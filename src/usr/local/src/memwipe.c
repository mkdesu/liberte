#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/mman.h>

#define KIB    (1 << 10)
#define BLOCK  (KIB << 2)
#define MAXMEM (KIB << 20)

#define PATT_A 0x55
#define PATT_B 0xAA


static volatile uintmax_t* wipesize;


static void unlimit(int resource, const char *name) {
    struct rlimit rlim;
    rlim.rlim_cur = RLIM_INFINITY;
    rlim.rlim_max = RLIM_INFINITY;

    /*
    if (setrlimit(resource, &rlim))
        fprintf(stderr, "Removing limits failed: %s\n", name);
    */
}


static void wipe(int depth, int pass, int fillbyte) {
    void  *start, *end;
    pid_t pid;
    int   status;

    start     = sbrk(0);
    end       = start;

    /* Incrementally allocate as much memory as possible */
    while (end - start + BLOCK <= MAXMEM  &&  !brk(end + BLOCK)) {
        memset(end, fillbyte, BLOCK);

        end       += BLOCK;
        *wipesize += BLOCK;
    }

    /*
      Most likely, the process is killed before brk() fails.

      To prevent killing:
        sysctl -w vm.overcommit_memory=2
                  vm.overcommit_ratio=~100 (+/-)
                  vm.drop_caches=3
    */

    /*
      If maximum allocated memory was reached, spawn a new process in
      order to avoid exhausting per-process VM space on 32-bit systems.

      NOTE: this relies on vm.oom_kill_allocating_task=1, otherwise
            one of the parent processes is usually killed.
    */
    if (end - start >= MAXMEM) {
        pid = fork();

        if (pid == -1)
            fprintf(stderr, "Failed to fork chain process\n");

        /* In child thread */
        else if (pid == 0) {
            if (brk(start))
                fprintf(stderr, "Failed to release chain parent's memory address space\n");
            else
                wipe(depth+1, pass, fillbyte);

            _exit(0);
        }

        /* Continuing in parent thread */
        else {
            if (waitpid(pid, &status, 0) != pid)
                fprintf(stderr, "Failed to wait on chained child process\n");

            else if (WIFSIGNALED(status))
                printf("[killed (chain %d)] ", depth+1);
        }
    }

    /* Release allocated memory */
    if (brk(start))
        fprintf(stderr, "Failed to release allocated memory\n");
}


int main() {
    pid_t pid;
    int   status, pass, fillbyte;


    /* Doesn't work with klibc, but defaults are fine */
    unlimit(RLIMIT_AS,      "as");          /* brk */
    unlimit(RLIMIT_DATA,    "data");        /* brk: init data / uninit data / heap */
    unlimit(RLIMIT_STACK,   "stack");       /* stack / command line / env vars */
    unlimit(RLIMIT_MEMLOCK, "memlock");     /* mlock */


    /* Allocate shared memory */
    wipesize = (volatile uintmax_t*) mmap(NULL, sizeof(uintmax_t), PROT_READ | PROT_WRITE,
                                          MAP_SHARED | MAP_ANONYMOUS | MAP_LOCKED, -1, 0);
    if (wipesize == MAP_FAILED) {
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

        if (pid == -1)
            fprintf(stderr, "Failed to fork process\n");

        /* In child thread */
        else if (pid == 0) {
            wipe(0, pass, fillbyte);
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
    if (munmap((void*) wipesize, sizeof(uintmax_t)))
        fprintf(stderr, "Failed to free shared dmemory\n");


    return 0;
}
