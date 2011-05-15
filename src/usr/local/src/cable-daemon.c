#ifndef _POSIX_C_SOURCE
#define _POSIX_C_SOURCE 1
#endif

#ifndef _BSD_SOURCE
#define _BSD_SOURCE
#endif

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include <unistd.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>
#include <time.h>
#include <signal.h>
#include <locale.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <sys/inotify.h>
#include <sys/wait.h>


#define MSGID_LENGTH 40

/* max correct path length */
#define MAXPATH     127

/* waiting strategy for inotify setup retries (e.g., after fs unmount) */
#define WAIT_INIT     2
#define WAIT_MULT   3/2
#define WAIT_MAX     60

/* loop executable */
#define LOOP_EXEC   "/usr/local/libexec/cable/loop"


/* inotify file descriptor and (r)queue directories watch descriptors */
static int inotfd = -1, inotqwd = -1, inotrqwd = -1;

/* fast shutdown indicator */
static volatile int stop = 0;

/* process counters */
static volatile long pstarted = 0, pfinished = 0;


/* non-fatal error */
static void warning() {
    perror("cabled (warning)");
}

/* fatal errors which shouldn't happen in a correct program */
static void error() {
    perror("cabled (fatal)");

    if (inotfd != -1  &&  close(inotfd) == -1)
        warning();

    exit(EXIT_FAILURE);
}


/* INT/TERM signals handler */
static void sig_handler(int signum) {
	if (signum == SIGINT || signum == SIGTERM)
		stop = 1;
}


static void chld_handler(int signum) {
    pid_t pid;
    int   status;

    if (signum == SIGCHLD) {
        /*
          multiple instances of pending signals are compressed, so
          handle all completed processes as soon as possible
        */
        while ((pid = waitpid(0, &status, WNOHANG)) > 0)
            ++pfinished;

        /* -1/ECHILD is returned for no pending completed processes */
        if (pid == -1  &&  errno != ECHILD)
            error();
    }
}


/* unregister inotify watches and dispose of allocated file descriptor */
static void unreg_watches() {
    if (inotfd != -1) {
        /* ignore errors due to automatically removed watches (IN_IGNORED) */
        if (inotqwd != -1  &&  inotify_rm_watch(inotfd, inotqwd) == -1  &&  errno != EINVAL)
            error();
        else
            inotqwd = -1;

        /* ignore errors due to automatically removed watches (IN_IGNORED) */
        if (inotrqwd != -1  &&  inotify_rm_watch(inotfd, inotrqwd) == -1  &&  errno != EINVAL)
            error();
        else
            inotrqwd = -1;

        /*
          closing/reopening an inotify fd is an expensive operation, but must be done
          because otherwise fd provides infinite stream of IN_IGNORED events
        */
        if (close(inotfd) == -1) {
            inotfd = -1;
            error();
        }
        else
            inotfd = -1;
    }
}

/* register (r)queue-specific inotify watches, returning 1 if successful */
static int reg_watches(const char *qpath, const char *rqpath) {
    if (inotfd == -1  &&  (inotfd = inotify_init()) == -1)
        error();

    /* existing watch is ok */
    if ((inotqwd = inotify_add_watch(inotfd, qpath, IN_MOVED_TO | IN_ATTRIB | IN_MOVE_SELF | IN_DONT_FOLLOW | IN_ONLYDIR)) == -1) {
        warning();
        return 0;
    }

    /* existing watch is ok */
    if ((inotrqwd = inotify_add_watch(inotfd, rqpath, IN_MOVED_TO | IN_MOVE_SELF | IN_DONT_FOLLOW | IN_ONLYDIR)) == -1) {
        warning();
        return 0;
    }

    return 1;
}


/* check whether given path is a mountpoint by comparing its and its parent's device IDs */
static int is_mountpoint(const char *path) {
    char pathp[MAXPATH+1];
    struct stat st, stp;

    strncpy(pathp, path, MAXPATH);
    strncat(pathp, "/..", MAXPATH);

    if (lstat(path, &st) == -1  ||  lstat(pathp, &stp) == -1
        ||  !S_ISDIR(st.st_mode)  ||  !S_ISDIR(stp.st_mode))
        return 0;

    /* explicitly handle root fs, as well */
    return (st.st_dev != stp.st_dev) || (st.st_ino == stp.st_ino) ;
}


/*
  try to register inotify watches, unregistering them if not compeltely successful
  hold an open fd during the attempt, to prevent unmount during the process
*/
static int try_reg_watches(const char *mppath, const char *qpath, const char *rqpath) {
    int  mpfd = -1, ret = 0;
    struct stat st;

    /* unregister existing inotify watches */
    unreg_watches();

    /* try to quickly open a fd */
    if ((mpfd = open(mppath, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_NONBLOCK)) == -1)
        fprintf(stderr, "failed to open %s, waiting...\n", mppath);

    else if (! is_mountpoint(mppath))
        fprintf(stderr, "%s is not a mount point, waiting...\n", mppath);

    else if (lstat(qpath, &st) == -1  ||  !S_ISDIR(st.st_mode))
        fprintf(stderr, "%s is not a directory, waiting...\n", qpath);
    else if (lstat(rqpath, &st) == -1  ||  !S_ISDIR(st.st_mode))
        fprintf(stderr, "%s is not a directory, waiting...\n", rqpath);

    /* if registering inotify watches is unsuccessful, immediately unregister */
    else if (reg_watches(qpath, rqpath))
        ret = 1;
    else
        unreg_watches();

    /* always free the fd if the mp path was successfully opened */
    if (mpfd != -1  &&  close(mpfd) == -1)
        error();

    return ret;
}


/*
  sleep given number of seconds without interferences with SIGALRM
  do not complete interrupted sleeps to facilitate fast process shutdown
 */
static void sleepsec(float sec) {
    struct timespec req, rem;
    req.tv_sec  = (time_t) sec;
    req.tv_nsec = (long) ((sec - req.tv_sec) * 1e9f);

    if (nanosleep(&req, &rem) == -1) {
        /* try to complete the sleep at most once */
        if (errno == EINTR) {
            fprintf(stderr, "interrupted sleep\n");

            /*
            if (nanosleep(&rem, NULL) == -1  &&  errno != EINTR)
                error();
            */
        }
        else
            error();
    }
}


/* retry registering inotify watches, using the retry strategy parameters */
static void wait_reg_watches(const char *mppath, const char *qpath, const char *rqpath) {
    float slp = WAIT_INIT;

    while (!stop  &&  !try_reg_watches(mppath, qpath, rqpath)) {
        sleepsec(slp);

        slp = (slp * WAIT_MULT);
        if (slp > WAIT_MAX)
            slp = WAIT_MAX;
    }
}


/* set signal handlers */
static void set_signals() {
	struct sigaction sa;

	sa.sa_handler  = sig_handler;
	sigemptyset(&sa.sa_mask);
	sa.sa_flags    = 0;
    sa.sa_restorer = NULL;

	if (sigaction(SIGINT,  &sa, NULL) == -1  ||  sigaction(SIGTERM, &sa, NULL) == -1)
        error();

    sa.sa_handler  = chld_handler;
	sa.sa_flags    = SA_RESTART;

    if (sigaction(SIGCHLD, &sa, NULL) == -1)
        error();
}


/* lower-case hexadecimal of correct length, possibly ending with ".del" */
static int is_msgdir(const char *s) {
    size_t len = strlen(s);
    int    i;

    if (! (len == MSGID_LENGTH  ||
           (len == MSGID_LENGTH+4  &&  strcmp(".del", s + MSGID_LENGTH) == 0)))
        return 0;

    for (i = 0;  i < MSGID_LENGTH;  ++i)
        if (! (isxdigit(s[i])  &&  !isupper(s[i])))
            return 0;

    return 1;
}


/* run loop for given queue type and msgid; msgid is a volatile string */
static void run_loop(const char *qtype, const char *msgid) {
    pid_t pid;

    pid = fork();
    if (pid == -1)
        warning();
    else if (pid == 0) {
        printf("handling: %s %s\n", qtype, msgid);
        execl(LOOP_EXEC, "loop", qtype, msgid, (char *) NULL);

        /* exits just the fork */
        error();
    }
    else
        ++pstarted;
}


int main(int argc, char *argv[]) {
    /* using FILENAME_MAX prevents EINVAL on read() */
    char  buf[sizeof(struct inotify_event) + FILENAME_MAX+1];
    const char *mppath, *qpath, *rqpath;
    int   sz, offset, rereg;
    struct inotify_event *iev;

    umask(0077);
    setlocale(LC_ALL, "C");

    if (argc != 4) {
        fprintf(stderr, "%s <mount point> <queue dir> <rqueue dir>\n", argv[0]);
        return 1;
    }

    /* set INT/TERM handler */
    set_signals();

    /* extract arguments */
    mppath = argv[1];
    qpath  = argv[2];
    rqpath = argv[3];

    /* try to reregister watches as long as no signal caught */
    while (!stop) {
        wait_reg_watches(mppath, qpath, rqpath);
        fprintf(stderr, "registered watches\n");

        /* read events as long as no signal caught and no unmount / move_self / etc. events read */
        rereg = 0;
        while (!stop  &&  !rereg) {
            /* read events, taking care to handle interrupts due to signals */
            /* TODO: timeout */
            if ((sz = read(inotfd, buf, sizeof(buf))) == -1  &&  errno != EINTR)
                error();

            /* process all events in buffer, sz = -1 and 0 are automatically ignored */
            for (offset = 0;  offset < sz  &&  !stop  &&  !rereg; ) {
                /* get handler to next event in read buffer, and update offset */
                iev     = (struct inotify_event*) (buf + offset);
                offset += sizeof(struct inotify_event) + iev->len;

                /*
                  IN_IGNORED is triggered by watched directory removal / fs unmount
                  IN_MOVE_SELF is only triggered by move of actual watched directory
                  (i.e., not its parent)
                */
                if ((iev->mask & (IN_IGNORED | IN_UNMOUNT | IN_Q_OVERFLOW | IN_MOVE_SELF))) {
                    fprintf(stderr, "reregistering watches\n");
                    rereg = 1;
                }
                /* ignore non-directory events, and events with incorrect name */
                else if ((iev->mask & IN_ISDIR)  &&  is_msgdir(iev->name)) {
                    if (iev->wd != inotqwd  &&  iev->wd != inotrqwd)
                        fprintf(stderr, "unknown watch descriptor\n");
                    else {
                        const char *qtype = (iev->wd == inotqwd) ? "queue" : "rqueue";
                        run_loop(qtype, iev->name);
                    }
                }
            }
        }
    }

    unreg_watches();
    fprintf(stderr, "exiting\n");
    return 0;
}
