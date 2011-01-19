#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/reboot.h>


int main(int argc, char **argv) {
    int halt = 0;

    /* Single "halt" argument causes post-wipe poweroff*/
    if (argc >= 2 && !strcmp(argv[1], "halt"))
        halt = 1;


    /* Wipe RAM */
    printf("Test\n");


    /* Power off if requested */
    if (halt) {
        printf("Powering off ...\n");


        /* From sysvinit: halt.c */
        kill(1, SIGTSTP);


        /* Attempt to power off, then to halt */
        reboot(RB_POWER_OFF);
        reboot(RB_HALT_SYSTEM);


        fprintf(stderr, "Poweroff failed.\n");
        return 1;
    }

    return 0;
}
