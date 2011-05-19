/* Alternative: _POSIX_C_SOURCE 200809L */
#ifndef _XOPEN_SOURCE
#define _XOPEN_SOURCE 700
#endif

/* DT_DIR, DT_UNKNOWN, dirfd() */
#ifndef _BSD_SOURCE
#define _BSD_SOURCE
#endif

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <limits.h>
#include <errno.h>
#include <dirent.h>
#include <syslog.h>
#include <stdarg.h>
#include <signal.h>
#include <sys/file.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>


/* flock timeout */
#define LOCK_TMOUT 300

#define NOT_NUM ULLONG_MAX
#define NUM_LEN 20
typedef unsigned long long num_t;


static volatile int alrm = 0;


/* logging init */
static void syslog_init() {
    openlog("mhdrop", LOG_PID, LOG_MAIL);
}

/* logging */
static void flog(int priority, const char *format, ...) {
    va_list ap;

    va_start(ap, format);
    vsyslog(priority, format, ap);
    va_end(ap);
}

static void flogexit(int priority, const char *format, ...) {
    va_list ap;

    va_start(ap, format);
    vsyslog(priority, format, ap);
    va_end(ap);

    exit(EXIT_FAILURE);
}


/* support for flock timeout */
static void alrm_handler(int signum) {
    if (signum == SIGALRM)
        alrm = 1;
}


/* fatal errors which shouldn't happen in a correct program */
static void error() {
    flogexit(LOG_ERR, "%m");
}


/* set signal handlers */
static void set_signals() {
    struct sigaction sa;

    sa.sa_handler  = alrm_handler;
    sa.sa_flags    = 0;
    sa.sa_restorer = NULL;
    sigemptyset(&sa.sa_mask);

    if (sigaction(SIGALRM, &sa, NULL) == -1)
        error();
}


/*
  convert file name to a number, if possible
  if not possible, NOT_NUM is returned
*/
static num_t getidx(const char *name) {
    char   *end;
    size_t len, i;
    num_t  num;

    len = strlen(name);

    /* check [1-9][0-9]* format */
    if (!*name  ||  name[0] == '0')
        return NOT_NUM;

    for (i = 0;  i < len;  ++i)
        if (!isdigit(name[i]))
            return NOT_NUM;

    /* convert to number, checking overflow / would-be overflow */
    errno = 0;
    num = strtoull(name, &end, 10);
    if (*end  ||  errno  ||  num == ULLONG_MAX)
        return NOT_NUM;

    return num;
}


/*
  locks are automatically released on program exit,
  so don't bother with unlocking on exceptions
 */
int main(int argc, char *argv[]) {
    const  char   *mhdir;
    struct dirent *de = NULL;
    DIR           *dir;
    int           dfd, i, spret;
    num_t         maxidx = 0, curidx;
    char          numname[NUM_LEN+1];

    if (argc < 3) {
        fprintf(stderr, "%s <mh dir> <message on same fs> ...\n", argv[0]);
        return 1;
    }

    mhdir = argv[1];

    /* init logging */
    syslog_init();

    /* signals */
    set_signals();

    /* open directory */
    if ((dir = opendir(mhdir)) == NULL)
        error();

    /* get corresponding file descriptor for lock / access */
    if ((dfd = dirfd(dir)) == -1)
        error();

    /* lock directory with timeout */
    alarm(LOCK_TMOUT);
    if (flock(dfd, LOCK_EX) == -1) {
        if (errno == EINTR  &&  alrm)
            flogexit(LOG_ERR, "timed out while locking %s", mhdir);
        else
            error();
    }
    alarm(0);

    /* find max entry, don't bother with file types */
    for (errno = 0;  (de = readdir(dir)) != NULL; )
        if ((curidx = getidx(de->d_name)) != NOT_NUM  &&  curidx > maxidx)
            maxidx = curidx;

    if (de == NULL  &&  errno)
        error();

    
    /* deliver messages */
    for (i = 2, ++maxidx;  i < argc;  ++i, ++maxidx) {
        if (maxidx == NOT_NUM  ||  maxidx == 0)
            flogexit(LOG_ERR, "indexes exhausted, %llu not legal", maxidx);

        /* convert to string, but also check back due to possible locale-related problems */
        spret = snprintf(numname, sizeof(numname), "%llu", maxidx);
        if (spret < 0  ||  spret >= sizeof(numname)  ||  getidx(numname) != maxidx)
            flogexit(LOG_ERR, "could not convert %llu to file name", maxidx);

        /* rename() may replace an externally created file, so use link/unlink */
        if (linkat(AT_FDCWD, argv[i], dfd, numname, 0) == -1)
            error();
        if (unlink(argv[i]) == -1)
            error();

        flog(LOG_INFO, "delivered %s/%s", mhdir, numname);
    }


    /* unlock (explicitly) */
    if (flock(dfd, LOCK_UN) == -1)
        error();

    /* close directory */
    if (closedir(dir) == -1)
        error();

    closelog();
    return 0;
}
