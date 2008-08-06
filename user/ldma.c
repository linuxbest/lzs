#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <getopt.h>

#include "async_dma.h"

#include "../liblzs.c"

static void hexdump(char *data, unsigned size)
{
        char *start = data;
        while (size) {
                unsigned char *p;
                int w = 16, n = size < w? size: w, pad = w - n;
                printf("%04x:  ", data-start);
                for (p = data; p < (unsigned char *)data + n;)
                        printf("%02hx ", *p++);
                printf("%*.s  \"", pad*3, "");
                for (p = data; p < (unsigned char *)data + n;) {
                        int c = *p++;
                        printf("%c", c < ' ' || c > 127 ? '.' : c);
                }
                printf("\"\n");
                data += w;
                size -= n;
        }
}

static char *
op_to_name(int o)
{
        char *s = o == 0 ? "NULL" :
                  o == 1 ? "FILL" :
                  o == 2 ? "COPY" :
                  o == 3 ? "ENCODE" :
                  o == 4 ? "DECODE" : NULL;
}

static void 
usage(char *name)
{
        fprintf(stderr, "%s: [-s size] [-o op]\n", name);
        exit (0);
}

static int dst_check(unsigned char *src, int len, 
                unsigned char *dst, int dlen, int opt)
{
        unsigned char *t = malloc(dlen), *c = NULL;
        int o = 0, oc = 0;
        int i, err = 0;

        o = lzsCompress(src, len, t, dlen);
        if (opt == 3) { /* compress operation */
                c  = t;
                oc = o;
        } else if (opt == 4) { /* uncompress */
                c = src;
                oc = len;
        }

        printf("dlen %x, o %x\n", dlen, oc);
        for (i = 0; i < oc; i ++) {
                if (dst[i] != c[i]) 
                        err ++;
        }
        if (err) {
                FILE *fp;
                printf("error %d\n", err);

                fp = fopen("/tmp/src.dat", "w");
                if (opt == 3)
                        fwrite(src, len, 1, fp);
                else
                        fwrite(t, o, 1, fp);
                fclose(fp);

                fp = fopen("/tmp/dst.dat", "w");
                fwrite(dst, len, 1, fp);
                fclose(fp);

                exit (1);
        }

        return 0;
}

int main(int argc, char *argv[])
{
        char *src;
        char *dst, *t;
        int len = 0x80;
        int dlen = len;
        sioctl_t sio;
        int fd, res = 0, opt, op = 0, i = 0, 
            verbose = 0, 
            debug = 0, 
            loop = 0,
            check = 0;
        char *op_name;
        FILE *fp;

        while ((opt = getopt(argc, argv, "s:o:v:d:l:cDr:")) != -1) {
                switch (opt) {
                        case 'r':
                                fp = fopen(optarg, "r");
                                if (fp == NULL)
                                        perror("fopen");
                                break;
                        case 'D':
                                debug = 1;
                                break;
                        case 'c': 
                                check = 1;
                                break;
                        case 'l': 
                                loop = atoi(optarg);
                                break;
                        case 'd':
                                dlen = atoi(optarg);
                                break;
                        case 'v':
                                verbose = atoi(optarg);
                                break;
                        case 's':
                                len = atoi(optarg);
                                break;
                        case 'o':
                                op  = atoi(optarg);
                                break;
                        default:
                                usage(argv[0]);
                                break;
                }
        }

        op_name = op_to_name(op);
        printf("size is %d, op is %s\n",
                        len, op_name);

        if (op_name == NULL) 
                return -1;

        fd = open("/dev/lzfdma", O_RDONLY);
        if (fd == -1) {
                perror("open");
                return -1;
        }
        t = memalign(4096, len+0x10);
        for (i = 0; i < len+0x10; i ++) {
                t[i] = i;
        }
        src = memalign(4096, len+0x10);
        for (i = 0; i < len+0x10; i ++) {
                src[i] = i;
        }
        dst = memalign(4096, len+0x10);
        for (i = 0; i < len+0x10; i ++) {
                dst[i] = 0xff - i;
        }
        do {
                int clen;
                if (fp)
                        fread(src, len, 1, fp);
                clen = lzsCompress(src, len, t, len);
                if (clen % 16) clen += (16 - (clen % 16));
                sio.ops  = op;
                if (op == 4) {
                        sio.src = t;
                        //sio.slen = clen;
                } else {
                        sio.src = src;
                        //sio.slen = len;
                }
                sio.slen = len;
                sio.dst  = dst;
                sio.dlen = dlen;
                sio.err  = 0;
                sio.osize= 0;
                sio.done = 0;
                sio.flags= 0;
                if (debug) 
                        sio.flags |= SIO_DEBUG;

                res = ioctl(fd, SIOCTL_SUBMIT, &sio);

                if (sio.done == 0 || verbose) {
                        if (verbose == 2)
                                hexdump(dst, dlen+0x10);
                        printf("res %d, err %d, osize %x, done %d, dlen %x\n", 
                                        res, sio.err, sio.osize, sio.done, 
                                        dlen);
                }
                if (check) 
                        dst_check(src, len, dst, dlen, op);
                loop --;
        } while (res == 0 && loop > 0);

        free(src);
        free(dst);
}
