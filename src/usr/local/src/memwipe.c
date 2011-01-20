#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/types.h>
#include <sys/wait.h>

#define KIB    (1 << 10)
#define BLOCK  (KIB << 2)

#define PATT_A 0x55
#define PATT_B 0xAA


static volatile void*     brkstartsave;
static volatile ptrdiff_t wipesize;


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

    wipesize     = 0;
    brkstartsave = brkstart;

    /* brk(brkend + BLOCK); printf("%#x\n", *((int*)brkend)); */

    /* Incrementally allocate as much memory as possible */
    while (!brk(brkend + BLOCK)) {
        memset(brkend, fillbyte, BLOCK);
        brkend += BLOCK;

        wipesize = brkend - brkstart;
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
        fprintf(stderr, "Unable to release allocated memory\n");
}


int main() {
    pid_t pid;
    int   status, pass, fillbyte;

    /* Flip bits 0 -> 1 and 1 -> 0 in checkerboard pattern */
    for (pass = 0;  pass < 3;  ++pass) {
        fillbyte = (pass % 2) ? PATT_A : PATT_B;

        /* Suspends parent, all memory and resources are common,
           everything is common - even the sky, even Allah! (c) */
        pid = vfork();

        /* printf("PID = %d, clone PID = %d\n", getpid(), pid); */

        if (pid == -1)
            fprintf(stderr, "Failed to vfork process\n");

        /* In child thread */
        else if (pid == 0) {
            wipe(pass, fillbyte);
            _exit(pass);
        }

        /* Continuing in parent thread */
        else {
            if (waitpid(pid, &status, 0) != pid)
                fprintf(stderr, "Failed to wait on child process\n");

            else {
                if (WIFSIGNALED(status)) {
                    /* Release allocated memory if it wasn't freed after OOM kill */
                    /* Note: PAX_MEMORY_SANITIZE does not come into effect here   */
                    if (brk((void*) brkstartsave))
                        fprintf(stderr, "Failed to release assumed-unfreed memory\n");

                    printf("[killed] ");
                }

                printf("Pass %d: wiped %ld MiB + %d KiB of RAM with 0x%X\n",
                       pass,
                       (long) (wipesize / KIB / KIB),
                       (int)  (wipesize / KIB % KIB),
                       fillbyte);
            }
        }
    }

    return 0;
}
