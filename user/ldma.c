#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <getopt.h>

#include "async_dma.h"

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
        int fd, res = 0, opt, op = 0;
        char *op_name;

        while ((opt = getopt(argc, argv, "s:o:")) != -1) {
                switch (opt) {
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

        src = memalign(16, len);
        dst = memalign(16, len);
        //while (res == 0) {
                //sio.ops = OP_COMPRESS;
                //sio.ops = OP_MEMCPY;
                sio.ops = OP_FILL;
                //sio.ops = OP_NULL;
                sio.src  = src;
                sio.slen = len;
                sio.dst  = dst;
                sio.dlen = len;
                sio.err = 0;
                sio.osize = 0;
                sio.done = 0;

                res = ioctl(fd, SIOCTL_SUBMIT, &sio);

                printf("res %d, err %d, osize %d, done %d\n", 
                                res, sio.err, sio.osize, sio.done);
        //}
        free(src);
        free(dst);
}
