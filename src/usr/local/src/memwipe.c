#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/resource.h>

#define BLOCK  4096
#define PATT_A 0x55
#define PATT_B 0xAA


extern char etext;                          /* first addr past text        segment */
extern char edata;                          /* first addr past init   data segment */
extern char end;                            /* first addr past uninit data segment */


static void unlimit(int resource, const char *name) {
    struct rlimit rlim;
    rlim.rlim_cur = RLIM_INFINITY;
    rlim.rlim_max = RLIM_INFINITY;

    /*
    if (setrlimit(resource, &rlim))
        fprintf(stderr, "Removing limits failed: %s\n", name);
    */
}


static void wipe() {
    void *brkstart, *brkend;

    /* Doesn't work with klibc, but defaults are fine */
    unlimit(RLIMIT_AS,      "as");          /* brk */
    unlimit(RLIMIT_DATA,    "data");        /* brk: init data / uninit data / heap */
    unlimit(RLIMIT_STACK,   "stack");       /* stack / command line / env vars */
    unlimit(RLIMIT_MEMLOCK, "memlock");     /* mlock */

    brkstart = sbrk(0);
    brkend   = brkstart;

    /* Allocate as much memory as possible */
    while (!brk(brkend + BLOCK)) {
        memset(brkend, PATT_A, BLOCK);
        brkend += BLOCK;
    }

    /* Flip all bits twice */
    memset(brkstart, PATT_B, brkend - brkstart);
    memset(brkstart, PATT_A, brkend - brkstart);

    /* Release allocated memory */
    if (brk(brkstart))
        fprintf(stderr, "Unable to release allocated memory\n");

    printf("Wiped %ld MiB of RAM\n", (long) ((brkend - brkstart) / (1024*1024)));
}


int main() {
    /* Wipe RAM */
    wipe();

    return 0;
}
