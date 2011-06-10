#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <errno.h>
#include <pwd.h>
#include <sys/types.h>


/* must not have any processes running as this uid */
#define SLAYUID "slay"


static void error() {
    if (errno)
        perror("slay");
    else
        fprintf(stderr, "slay: error\n");

    exit(EXIT_FAILURE);
}


int main(int argc, char *argv[]) {
    const struct passwd *pswd;
    uid_t slayuid, killuid;


    if (argc != 2) {
        printf("%s <user>\n", argv[0]);
        return EXIT_FAILURE;
    }


    /* get real/saved and target uids */
    if ((pswd = getpwnam(SLAYUID)) == NULL)
        error();
    slayuid = pswd->pw_uid;

    if ((pswd = getpwnam(argv[1])) == NULL)
        error();
    killuid = pswd->pw_uid;


    /*
      "real or effective user ID of the sending process must equal
       the real or saved set-user-ID of the target process"
     */
    if (setresuid(slayuid, killuid, slayuid) == -1)
        error();


    /* must be able to send a signal at least to itself */
    if (kill(-1, SIGKILL) == -1)
        error();


    /* it is possible that this process exits before being killed */
    return EXIT_SUCCESS;
}
