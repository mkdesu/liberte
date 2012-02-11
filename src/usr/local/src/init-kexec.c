/*
 * Supported kernel parameters:
 *   - halt  : power-off
 *   - alert : take special precautions against cold-boot attacks
 *             [unused at present]
 */

#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <sys/reboot.h>


/* Move cursor to top left and clear screen */
#define ANSI_CLS "\033[H\033[2J"

#define DELAY_MS 0


int main(int argc, char **argv) {
    int   halt = 0, alert = 0;


    /* Clear screen if the terminal supports it */
    printf(ANSI_CLS);
    fflush(stdout);


    /* Parse kernel parameters */
    for (;  *argv;  ++argv) {
        if      (!strcmp(*argv, "halt"))
            halt  = 1;
        else if (!strcmp(*argv, "alert"))
            alert = 1;
    }


    printf("Intermediate kernel (halt=%d, alert=%d)\n", halt, alert);


    usleep(DELAY_MS * 1000);


    if (halt) {
        reboot(LINUX_REBOOT_CMD_POWER_OFF);

        /* Not strictly necessary - POWER_OFF falls back to HALT anyway */
        fprintf(stderr, "Failed to power off\n");
        reboot(LINUX_REBOOT_CMD_HALT);
    }
    else {
        reboot(LINUX_REBOOT_CMD_RESTART);
    }


    return 0;
}
