#define _BSD_SOURCE

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>


/*
 * Executes "/bin/sh" after setting real user-id
 * to effective user-id, and same with group-id.
 *
 * Real and effective group-id are set to 0 if
 * possible afterwards (errors are ignored).
 *
 * "/bin/sh" is passed all the arguments of the program,
 * and the environment is preserved.
 */
int main(int agrc, char *const argv[]) {
    if (setreuid(geteuid(), -1) == 0  &&  setregid(getegid(), -1) == 0) {
        setregid(0, 0);
        execv("/bin/sh", argv);
    }

    perror("privsh");
    return EXIT_FAILURE;
}
