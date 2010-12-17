/*
  Returned status: OK, BADREQ, BADFMT, <VERSION>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <locale.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>


#define VERSION   "LIBERTE CABLE 1.0"
#define REQVAR    "PATH_INFO"
#define MAXPATH   256


void retstatus(const char *status) {
    puts(status);
    exit(0);
}


/* lower-case hexadecimal */
int vfyhex(int sz, const char *s) {
    if (strlen(s) != sz)
        return 0;

    for (; *s; ++s)
        if (!(isxdigit(*s) && !isupper(*s)))
            return 0;

    return 1;
}


/* lower-case Base-32 encoding (a-z, 2-7) */
int vfybase32(int sz, const char *s) {
    if (strlen(s) != sz)
        return 0;

    for (; *s; ++s)
        if (!(islower(*s) || (*s >= '2' && *s <= '7')))
            return 0;

    return 1;
}


/* lower case hostnames - currently, only .onion addresses are supported */
int vfyhost(const char *s) {
    char buf[17];
    
    if (strlen(s) != 16+1+5)
        return 0;

    strncpy(buf, s, 16);
    buf[16] = '\0';

    return vfybase32(16, buf) && !strcmp(".onion", s+16);
}


void handle_msg(const char *msgid, const char *hostname, const char *username) {
    /* TODO */
}


void handle_rcp(const char *msgid) {
    /* TODO */
}


void handle_ack(const char *msgid, const char *ackhash) {
    /* TODO */
}


int main() {
    char       buf[MAXPATH];
    const char *pathinfo, *delim = "/";
    char       *cmd, *msgid, *arg1, *arg2;

    umask(077);
    setlocale(LC_ALL, "C");

    
    /* HTTP headers */
    printf("Content-Type: text/plain\n"
           "Cache-Control: no-cache\n\n");


    /* Check request availability and length */
    pathinfo = getenv(REQVAR);
    if (!pathinfo || strlen(pathinfo) >= MAXPATH)
        retstatus("BADREQ");


    /* Copy request to writeable buffer */
    strncpy(buf, pathinfo, MAXPATH-1);
    buf[MAXPATH-1] = '\0';


    /* Tokenize the request */
    cmd   = strtok(buf,  delim);
    msgid = strtok(NULL, delim);
    arg1  = strtok(NULL, delim);
    arg2  = strtok(NULL, delim);

    if (strtok(NULL, delim) || !cmd)
        retstatus("BADFMT");


    /* Handle commands

       ver
       msg/<msgid>/<hostname>/<username>
       rcp/<msgid>
       ack/<msgid>/<ackhash>

       msgid:     40 xdigits
       ackhash:  128 xdigits
       hostname:  16 base-32 chars + ".onion"
       username:  32 base-32 chars
    */
    if (!strcmp("ver", cmd)) {
        if (msgid)
            retstatus("BADFMT");

        retstatus(VERSION);
    }
    else if (!strcmp("msg", cmd)) {
        if (!arg2)
            retstatus("BADFMT");

        if (   !vfyhex(40, msgid)
            || !vfyhost(arg1)
            || !vfybase32(32, arg2))
            retstatus("BADFMT");

        handle_msg(msgid, arg1, arg2);
    }
    else if (!strcmp("rcp", cmd)) {
        if (!msgid || arg1)
            retstatus("BADFMT");

        if (!vfyhex(40, msgid))
            retstatus("BADFMT");

        handle_rcp(msgid);
    }
    else if (!strcmp("ack", cmd)) {
        if (!arg1 || arg2)
            retstatus("BADFMT");

        if (   !vfyhex( 40, msgid)
            || !vfyhex(128, arg1))
            retstatus("BADFMT");

        handle_ack(msgid, arg1);
    }
    else
        retstatus("BADFMT");


    retstatus("OK");
    return 0;
}
