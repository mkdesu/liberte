/*
 * Supported kernel parameters:
 *   - halt  : power-off after memory wipe
 *   - alert : take special precautions against cold-boot attacks
 */

#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <signal.h>
#include <termios.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/mount.h>
#include <sys/reboot.h>
#include <sys/ioctl.h>


/* Move cursor to top left and clear screen */
#define ANSI_CLS "\033[H\033[2J"

#define MEMWIPE  "/memwipe"

/* Maximum length of /proc/sys/... path */
#define MAX_PATH 64

#define DELAY_MS 250


static void cocoon() {
    struct sigaction sa;
    struct termios   tr;

    sa.sa_handler  = SIG_IGN;
    sa.sa_flags    = 0;
    sa.sa_restorer = 0;
    sigfillset(&sa.sa_mask);
    

    if (sigaction(SIGINT,  &sa, 0))
        fprintf(stderr, "Failed to ignore SIGINT\n");
    if (sigaction(SIGTSTP, &sa, 0))
        fprintf(stderr, "Failed to ignore SIGTSTP\n");


    /* Depends on SIGINT being ignored */
    if(reboot(LINUX_REBOOT_CMD_CAD_OFF))
        fprintf(stderr, "Failed to disable Ctrl-Alt-Del sequence\n");


    /* Disable terminal signals (includes Ctrl-S / Scroll Lock) */
    if (tcgetattr(fileno(stdin), &tr))
        fprintf(stderr, "Failed to get stdin termios data\n");
    else {
        tr.c_iflag &= ~(IGNBRK | BRKINT | IXON);
        tr.c_lflag &= ~(ECHO | ICANON | ISIG);

        if (tcsetattr(fileno(stdin), TCSANOW, &tr))
            fprintf(stderr, "Failed to set stdin termios data\n");
    }
    
    if (tcflow(fileno(stdin), TCIOFF))
        fprintf(stderr, "Failed to disable stdin terminal\n");



    if (close(fileno(stdin)))
        fprintf(stderr, "Failed to close stdin\n");
}


static void sysctl(const char *key, const char *value) {
    char path[MAX_PATH + 1] = "/proc/sys/";
    char *loc = path-1;
    FILE *file;

    strcat(path, key);
    while ((loc = strchr(loc+1, '.')))
        *loc = '/';

    file = fopen(path, "w");
    if (!file) {
        fprintf(stderr, "Failed to open %s for writing\n", path);
        return;
    }

    if (fputs(value, file) < 0)
        fprintf(stderr, "Failed to write \"%s\" to %s\n", value, path);

    if (fflush(file))
        fprintf(stderr, "Failed to flush %s\n", path);

    if (fclose(file))
        fprintf(stderr, "Failed to close %s\n", path);
}


int main(int argc, char **argv) {
    int   halt = 0, alert = 0, status;
    pid_t pid;
    char  *empty[] = { 0 };


    /* Clear screen if the temrinal supports it */
    printf(ANSI_CLS);
    fflush(stdout);


    /* Disable Ctrl-Alt-Del */
    cocoon();


    /* Parse kernel parameters */
    for (;  *argv;  ++argv) {
        if      (!strcmp(*argv, "halt"))
            halt  = 1;
        else if (!strcmp(*argv, "alert"))
            alert = 1;
    }


    printf("Wiping RAM (halt=%d, alert=%d)...\n", halt, alert);


    /* Set VM-related kernel parameters via procfs */
    if (mount("proc", "/proc", "proc", MS_NOATIME | MS_NODEV | MS_NOEXEC | MS_NOSUID, ""))
        fprintf(stderr, "Failed to mount /proc\n");
    else {
        sysctl("kernel.printk",        "0");
        sysctl("vm.overcommit_memory", "1");
        sysctl("vm.drop_caches",       "3");

        if (umount("/proc"))
            fprintf(stderr, "Failed to unmount /proc\n");
    }


    /* Wipe memory via helper process */
    pid = vfork();

    if (pid == -1)
        fprintf(stderr, "Failed to vfork memory wiper\n");

    /* In child thread */
    else if (pid == 0) {
        execve(MEMWIPE, empty, empty);

        fprintf(stderr, "Failed to run memory wiper\n");
        _exit(1);
    }

    /* Continuing in parent thread */
    else {
        if (waitpid(pid, &status, 0) != pid)
            fprintf(stderr, "Failed to wait on child process\n");

        else if (WIFSIGNALED(status))
            fprintf(stderr, "Memory wiping process killed\n");

        else if (!WIFEXITED(status))
            fprintf(stderr, "Memory wiper didn't exit and wasn't killed\n");

        else if (WEXITSTATUS(status))
            fprintf(stderr, "Memory wiper didn't run or didn't exit cleanly\n");
    }


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
