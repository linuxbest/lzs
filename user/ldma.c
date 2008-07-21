#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <getopt.h>

#include "async_dma.h"

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

int main(int argc, char *argv[])
{
        char *src;
        char *dst;
        int len = 0x80;
        sioctl_t sio;
        int fd, res = 0, opt, op = 0, i = 0, verbose = 0, debug = 0, loop = 0;
        char *op_name;

        while ((opt = getopt(argc, argv, "s:o:v:dl:")) != -1) {
                switch (opt) {
                        case 'l': 
                                loop = atoi(optarg);
                                break;
                        case 'd':
                                debug = 1;
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

        src = memalign(64, len+0x10);
        for (i = 0; i < len+0x10; i ++) {
                src[i] = i;
        }
        dst = memalign(64, len+0x10);
        for (i = 0; i < len+0x10; i ++) {
                dst[i] = 0xff - i;
        }
        do {
                sio.ops  = op;
                sio.src  = src;
                sio.slen = len;
                sio.dst  = dst;
                sio.dlen = len;
                sio.err  = 0;
                sio.osize= 0;
                sio.done = 0;
                sio.flags= 0;
                if (debug) 
                        sio.flags |= SIO_DEBUG;

                res = ioctl(fd, SIOCTL_SUBMIT, &sio);

                if (sio.done == 0 || verbose) {
                        if (verbose == 2)
                                hexdump(dst, len+0x10);
                        printf("res %d, err %d, osize %x, done %d\n", 
                                        res, sio.err, sio.osize, sio.done);
                }
                loop --;
        } while (res == 0 && loop > 0);

        free(src);
        free(dst);
}
