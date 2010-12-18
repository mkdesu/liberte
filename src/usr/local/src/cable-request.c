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


#define VERSION             "LIBERTE CABLE 1.0"
#define REQVAR              "PATH_INFO"
#define MAX_REQ_LENGTH      256

/* caller shouldn't be able to distinguish OK/ERROR */
#define OK                  "OK"
#define BADREQ              "BADREQ"
#define BADFMT              "BADFMT"
#ifndef ERROR
#define ERROR               OK
#endif

#define MSGID_LENGTH         40
#define TOR_HOSTNAME_LENGTH  16
#define USERNAME_LENGTH      32
#define ACKHASH_LENGTH      128

#ifndef CABLES_PREFIX
#define CABLES_PREFIX       "/home/anon/persist/cables"
#endif

/* maximum filename length in (r)q_pfx/<msgid>/: 32 characters */
#define MAX_PATH_LENGTH     (sizeof(CABLES_PREFIX) + 9 + MSGID_LENGTH + 32)

static const char *q_pfx  = CABLES_PREFIX "/queue/";
static const char *rq_pfx = CABLES_PREFIX "/rqueue/";


static void retstatus(const char *status) {
    puts(status);
    exit(0);
}


/* lower-case hexadecimal */
static int vfyhex(int sz, const char *s) {
    if (strlen(s) != sz)
        return 0;

    for (; *s; ++s)
        if (!(isxdigit(*s) && !isupper(*s)))
            return 0;

    return 1;
}


/* lower-case Base-32 encoding (a-z, 2-7) */
static int vfybase32(int sz, const char *s) {
    if (strlen(s) != sz)
        return 0;

    for (; *s; ++s)
        if (!(islower(*s) || (*s >= '2' && *s <= '7')))
            return 0;

    return 1;
}


/* lower case hostnames - currently, only .onion addresses are recognized */
static int vfyhost(char *s) {
    int  result = 0;
    char *dot   = strrchr(s, '.');

    if (dot) {
        *dot = '\0';

        /* Tor .onion hostnames */
        if (!strcmp("onion", dot+1))
            result = vfybase32(TOR_HOSTNAME_LENGTH, s);

        *dot = '.';
    }

    return result;
}


static void write_line(const char *path, const char *s) {
    FILE *file;

    if (!(file = fopen(path, "w")))
        retstatus(ERROR);

    if (s) {
        if(fputs(s, file) < 0 || fputc('\n', file) != '\n') {
            fclose(file);
            retstatus(ERROR);
        }
    }

    if (fclose(file))
        retstatus(ERROR);
}


static void create_file(const char *path) {
    write_line(path, NULL);
}


static void read_line(const char *path, char *s, int sz) {
    FILE *file;

    if (!(file = fopen(path, "r")))
        retstatus(ERROR);

    if (s) {
        if(!fgets(s, sz, file) || fgetc(file) != EOF) {
            fclose(file);
            retstatus(ERROR);
        }

        sz = strlen(s);
        if (s[sz-1] == '\n')
            s[sz-1] = '\0';
    }

    if (fclose(file))
        retstatus(ERROR);
}


static void check_file(const char *path) {
    read_line(path, NULL, 0);
}


static void handle_msg(const char *msgid, const char *hostname, const char *username) {
    char path[MAX_PATH_LENGTH+1];
    int  baselen;

    /* base: .../cables/rqueue/<msgid> */
    strcpy(path, rq_pfx);
    strcat(path, msgid);
    baselen = strlen(path);

    /* atomically create directory */
    if (mkdir(path, 0700))
        retstatus(ERROR);

    /* write hostname */
    strcpy(path + baselen, "/hostname");
    write_line(path, hostname);

    /* write username */
    strcpy(path + baselen, "/username");
    write_line(path, username);

    /* create recv.req */
    strcpy(path + baselen, "/recv.req");
    create_file(path);
}


static void handle_rcp(const char *msgid) {
    char path[MAX_PATH_LENGTH+1];
    int  baselen;

    /* base: .../cables/queue/<msgid> */
    strcpy(path, q_pfx);
    strcat(path, msgid);
    baselen = strlen(path);

    /* create ack.req */
    strcpy(path + baselen, "/ack.req");
    create_file(path);
}


static void handle_ack(const char *msgid, const char *ackhash) {
    char path[MAX_PATH_LENGTH+1], trpath[MAX_PATH_LENGTH+6+1];
    char recack[ACKHASH_LENGTH+2];
    int  baselen;

    /* base: .../cables/rqueue/<msgid> */
    strcpy(path, rq_pfx);
    strcat(path, msgid);
    baselen = strlen(path);

    /* check recv.ok */
    strcpy(path + baselen, "/recv.ok");
    check_file(path);

    /* read receipt.ack */
    strcpy(path + baselen, "/receipt.ack");
    read_line(path, recack, sizeof(recack));

    /* compare <ackhash> <-> receipt.ack */
    if (strcmp(ackhash, recack))
        retstatus(ERROR);

    /* rename .../cables/rqueue/<msgid>/ */
    path[baselen] = '\0';
    strcpy(trpath, path);
    strcat(trpath, ".trash");

    if (rename(path, trpath))
        retstatus(ERROR);
}


int main() {
    char       buf[MAX_REQ_LENGTH+1];
    const char *pathinfo, *delim = "/";
    char       *cmd, *msgid, *arg1, *arg2;

    umask(0077);
    setlocale(LC_ALL, "C");

    
    /* HTTP headers */
    printf("Content-Type: text/plain\n"
           "Cache-Control: no-cache\n\n");


    /* Check request availability and length */
    pathinfo = getenv(REQVAR);
    if (!pathinfo || strlen(pathinfo) >= sizeof(buf))
        retstatus(BADREQ);


    /* Copy request to writeable buffer */
    strncpy(buf, pathinfo, sizeof(buf)-1);
    buf[sizeof(buf)-1] = '\0';


    /* Tokenize the request */
    cmd   = strtok(buf,  delim);
    msgid = strtok(NULL, delim);
    arg1  = strtok(NULL, delim);
    arg2  = strtok(NULL, delim);

    if (strtok(NULL, delim) || !cmd)
        retstatus(BADFMT);


    /* Handle commands

       ver
       msg/<msgid>/<hostname>/<username>
       rcp/<msgid>
       ack/<msgid>/<ackhash>

       msgid:    MSGID_LENGTH        xdigits
       ackhash:  ACKHASH_LENGTH      xdigits
       hostname: TOR_HOSTNAME_LENGTH base-32 chars + ".onion"
       username: USERNAME_LENGTH     base-32 chars
    */
    if (!strcmp("ver", cmd)) {
        if (msgid)
            retstatus(BADFMT);

        retstatus(VERSION);
    }
    else if (!strcmp("msg", cmd)) {
        if (!arg2)
            retstatus(BADFMT);

        if (   !vfyhex(MSGID_LENGTH, msgid)
            || !vfyhost(arg1)
            || !vfybase32(USERNAME_LENGTH, arg2))
            retstatus(BADFMT);

        handle_msg(msgid, arg1, arg2);
    }
    else if (!strcmp("rcp", cmd)) {
        if (!msgid || arg1)
            retstatus(BADFMT);

        if (!vfyhex(MSGID_LENGTH, msgid))
            retstatus(BADFMT);

        handle_rcp(msgid);
    }
    else if (!strcmp("ack", cmd)) {
        if (!arg1 || arg2)
            retstatus(BADFMT);

        if (   !vfyhex(MSGID_LENGTH, msgid)
            || !vfyhex(ACKHASH_LENGTH, arg1))
            retstatus(BADFMT);

        handle_ack(msgid, arg1);
    }
    else
        retstatus(BADFMT);


    retstatus(OK);
    return 0;
}
