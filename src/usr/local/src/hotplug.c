/*
   initramfs module hotplugging script.

   Written in C to be statically compiled in order to prevent
   segfaults in ld-linux.so.2 at early kernel initialization stages
   (empirically, when /dev/null is available, but /dev/tty0 is not
   yet, during device addition events).
*/

#include <string.h>
#include <unistd.h>
#include <stdlib.h>

#define MODPROBE "/sbin/modprobe"

int main() {
    char *value;

    if (((value = getenv("ACTION"))) && !strcmp("add", value)) {
        if ((value = getenv("MODALIAS"))) {
            execl(MODPROBE, MODPROBE, "-qb", value, (char *) NULL);
            return EXIT_FAILURE;
        }
    }

    return EXIT_SUCCESS;
}
