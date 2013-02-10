#include <unistd.h>
#include <stdio.h>

/*
 * This C uname wrapper makes glibc build process
 * happy by being an ELF binary.
 *
 * It just invokes the uname wrapper script.
 */
#define UNAME_HELPER "/usr/local/bin/uname-helper"


int main(int argc, char *const argv[]) {
    execv(UNAME_HELPER, argv);
    perror("uname wrapper");
    return 1;
}
