/*
  http://tools.ietf.org/html/rfc3548
  http://en.wikipedia.org/wiki/Base32
*/

#include <stdio.h>
#include <stdlib.h>
#include <locale.h>
#include <string.h>
#include <ctype.h>

int main(int argc, char *argv[]) {
    char *hex, *b32;
    int  len, i, j, digit, sum;
    
    setlocale(LC_ALL, "C");

    if (argc != 2) {
        printf("%s <hex>\n", argv[0]);
        return 1;
    }

    hex = argv[1];
    len = strlen(hex);

    if (len == 0 || len % 5 != 0) {
        printf("Argument length must be a positive multiple of 5\n");
        return 1;
    }

    b32 = (char*) malloc(len/5 * 4 + 1);
    if (!b32) {
        printf("Memory allocation error\n");
        return 1;
    }
    b32[len/5 * 4] = '\0';

    for (i = 0;  i < len; ) {
        for (j = sum = 0;  j < 5;  ++i, ++j) {
            if (!isxdigit(hex[i])) {
                printf("Non-hexadecimal character encountered\n");
                return 1;
            }

            if (isdigit(hex[i]))
                digit = hex[i] - '0';
            else if (islower(hex[i]))
                digit = hex[i] - 'a' + 10;
            else if (isupper(hex[i]))
                digit = hex[i] - 'A' + 10;
            else
                return 2;

            sum = sum * 16 + digit;
        }

        for (j = 1;  j <= 4;  ++j) {
            digit = sum % 32;
            sum  /= 32;

            if (digit < 26)
                digit += 'a';
            else
                digit  = digit - 26 + '2';

            b32[i/5 * 4 - j] = digit;
        }
    }

    puts(b32);

    free(b32);
    return 0;
}
