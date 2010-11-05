#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

#define BUF 1024

int main(int argc, char **argv) {
    char  buf[BUF];
    long  maxsize, pos;
    char  *interr;
    FILE  *out;

    char  *newname;
    const char *suffix = ".old";
    
    if (argc != 3) {
        fprintf(stderr, "%s <file> <max size>\n", argv[0]);
        return 1;
    }

    maxsize = strtol(argv[2], &interr, 10);
    if (!*argv[2] || *interr || errno == ERANGE || maxsize <= 0) {
        fprintf(stderr, "Invalid maximum size: \"%s\"\n", argv[2]);
        return 1;
    }

    if (!(out = fopen(argv[1], "a"))) {
        perror("Could not open file");
        /* return 1; */
    }

    while (fgets(buf, BUF, stdin) == buf) {
        if (out && (pos = ftell(out)) >= 0) {
            /* pos is 0 for non-seekable streams (e.g., /dev/null) */
            if (pos && pos + strlen(buf) > maxsize) {
                if (fclose(out))
                    perror("Could not close file, not rotating");
                else if (!(newname = (char*) malloc(strlen(argv[1]) + strlen(suffix) + 1)))
                    perror("Could not allocate memory, not rotating");
                else {
                    strcpy(newname, argv[1]);
                    strcat(newname, suffix);

                    if (rename(argv[1], newname))
                        perror("Could not rotate file");

                    free(newname);

                    if (!(out = fopen(argv[1], "a"))) {
                        perror("Could not open new file");
                        /* return 1; */
                    }
                }
            }
        }
        else {
            /* perror("Could not get stream size"); */
        }
        
        if (!out || fputs(buf, out) < 0)
            fprintf(stderr, "Did not log: %s", buf);
        if (out && fflush(out))
            perror("Could not flush");
    }

    if (out && fclose(out))
        perror("Could not close file");
    
    return 0;
}
