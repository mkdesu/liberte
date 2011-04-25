#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <signal.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/mman.h>

#define KIB    (1 << 10)
#define BLOCK  (KIB << 2)

#define PATT_A 0x55
#define PATT_B 0xAA


static volatile ptrdiff_t* wipesize;


static void cocoon() {
    struct sigaction sa;
    sa.sa_handler  = SIG_IGN;
    sa.sa_flags    = 0;
    sa.sa_restorer = 0;
    sigfillset(&sa.sa_mask);

    if (sigaction(SIGTSTP, &sa, 0))
        fprintf(stderr, "Failed to ignore SIGTSTP\n");
}


static void unlimit(int resource, const char *name) {
    struct rlimit rlim;
    rlim.rlim_cur = RLIM_INFINITY;
    rlim.rlim_max = RLIM_INFINITY;

    /*
    if (setrlimit(resource, &rlim))
        fprintf(stderr, "Removing limits failed: %s\n", name);
    */
}


static void wipe(int pass, int fillbyte) {
    void *brkstart, *brkend;

    /* Doesn't work with klibc, but defaults are fine */
    unlimit(RLIMIT_AS,      "as");          /* brk */
    unlimit(RLIMIT_DATA,    "data");        /* brk: init data / uninit data / heap */
    unlimit(RLIMIT_STACK,   "stack");       /* stack / command line / env vars */
    unlimit(RLIMIT_MEMLOCK, "memlock");     /* mlock */

    brkstart     = sbrk(0);
    brkend       = brkstart;

    *wipesize    = 0;

    /* brk(brkend + BLOCK); printf("%#x\n", *((int*)brkend)); */

    /* Incrementally allocate as much memory as possible */
    while (!brk(brkend + BLOCK)) {
        memset(brkend, fillbyte, BLOCK);
        brkend += BLOCK;

        *wipesize = brkend - brkstart;
    }

    /*
      Most likely, the process is killed before brk() fails.

      To prevent killing:
        sysctl -w vm.overcommit_memory=2
                  vm.overcommit_ratio=~100 (+/-)
                  vm.drop_caches=3
    */

    /* Release allocated memory */
    if (brk(brkstart))
        fprintf(stderr, "Failed to release allocated memory\n");
}


int main() {
    pid_t pid;
    int   status, pass, fillbyte;


    /* Ignore some signals */
    cocoon();


    /* Allocate shared memory */
    wipesize = (volatile ptrdiff_t*) mmap(NULL, sizeof(ptrdiff_t), PROT_READ | PROT_WRITE,
                                          MAP_SHARED | MAP_ANONYMOUS | MAP_LOCKED, -1, 0);
    if (wipesize == (void*) -1) {
        fprintf(stderr, "Failed to allocate shared memory\n");
        return 1;
    }


    /* Flip bits 0 -> 1 and 1 -> 0 in checkerboard pattern */
    for (pass = 0;  pass < 3;  ++pass) {
        fillbyte = (pass % 2) ? PATT_A : PATT_B;

        /* Can't use vfork() since 2.6.37, because mm/oom_kill.c
           kills all memory-sharing processes on OOM. */
        *wipesize = 0;
        pid = fork();

        /* printf("PID = %d, clone PID = %d\n", getpid(), pid); */

        if (pid == -1)
            fprintf(stderr, "Failed to vfork process\n");

        /* In child thread */
        else if (pid == 0) {
            wipe(pass, fillbyte);
            _exit(0);
        }

        /* Continuing in parent thread */
        else {
            if (waitpid(pid, &status, 0) != pid)
                fprintf(stderr, "Failed to wait on child process\n");

            else {
                if (WIFSIGNALED(status))
                    printf("[killed] ");

                printf("Pass %d: wiped %ld MiB + %d KiB of RAM with 0x%X\n",
                       pass,
                       (long) (*wipesize / KIB / KIB),
                       (int)  (*wipesize / KIB % KIB),
                       fillbyte);
            }
        }
    }


    /* Free shared memory */
    if (munmap((void*) wipesize, sizeof(ptrdiff_t)))
        fprintf(stderr, "Failed to free shared dmemory\n");


    return 0;
}
