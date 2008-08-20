/*
 * test the lzs hardware 
 *
 */
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <malloc.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>

#include <fcntl.h>
#include <getopt.h>

#include "async_dma.h"

#include "../liblzs.c"

/* for debug */
static void 
hexdump(char *data, unsigned size)
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

static int
write_file(char *s1, int sz1, char *append, int idx)
{
        FILE *fp;
        char buf[256];
        sprintf(buf, "/tmp/d/%d.%s", idx, append);
        fp = fopen(buf, "w");
        if (fp == NULL)
                return 0;
        fwrite(s1, sz1, 1, fp);
        fclose(fp);
        return 0;
}

static int
lzs_test(int fd, char *dev, int sz, int cnt, int debug)
{
        char *s, /* origin buffer */
             *z, /* software compress buffer */
             *t1,/* temp1 buffer */
             *t2;/* temp2 buffer */
        FILE *fp;
        int c_error = 10, d_error = 10, idx = 0;

        s = (char *)memalign(64, sz+0x10);
        t1= (char *)memalign(64, sz+0x10);
        t2= (char *)memalign(64, sz+0x10);
        z = (char *)memalign(64, sz+0x10);

        fp = fopen(dev, "r");
        if (fp == NULL) {
                perror("fopen");
                return 0;
        }

        do {
                int o, res = 0, cz;
                int c_err = 0, d_err = 0;
                sioctl_t sio = {0};
                sioctl_t sio2 = {0};

                /* reading data to buffer */
                if (fread(s, sz, 1, fp) != 1) {
                        return -1;
                }
                /* call software compress */
                cz = o = lzsCompress(s, sz, z, sz);
                /* call hardare compress */

                sio.ops = OP_COMPRESS;
                sio.src = (uint32_t)s;
                sio.slen= sz;
                sio.dlen= sz;
                sio.dst = (uint32_t)t1;
                if (debug)
                        sio.flags = SIO_DEBUG;

                res = ioctl(fd, SIOCTL_SUBMIT, &sio);
                if (res != 0) {
                        return -2;
                }
                if (sio.done == 0) { /* hardware not finished */
                //        return -3;
                }
                if (memcmp(t1, z, o) != 0) {
                        c_error --;
                        c_err = 1;
                }

                if (o % 8)
                        res += (8 - (o%8));
                else
                        res = o;
                sio2.ops = OP_UNCOMPRESS;
                sio2.src = (uint32_t)z;
                sio2.slen= res;
                sio2.dlen= sz;
                sio2.dst = (uint32_t)t2;
                if (debug)
                        sio.flags = SIO_DEBUG;

                res = ioctl(fd, SIOCTL_SUBMIT, &sio2);
                if (res != 0) {
                        return -4;
                }
                if (sio.done == 0) {
                //        return -5;
                }
                if (memcmp(t2, s, sz) != 0) {
                        d_err = 1;
                        d_error --;
                }

                if (d_err || c_err) {/* s, z, t1, t2 */
                        write_file(s, sz, "s", idx);
                        write_file(z, cz, "z", idx);
                        write_file(t1, sio.osize, "t1", idx);
                        write_file(t2, sio2.osize, "t2", idx);
                }
                printf("idx c_err d_err: %05d %02d %02d\r", 
                                idx, c_error, d_error);
                idx ++;
                if (sio.done == 0 || sio2.done == 0)
                        return  -90;
        } while (idx < cnt && c_error && d_error);
        printf("\n");

        return 0;
}

int 
main(int argc, char *argv[])
{
        int opt, sz = 65536, cnt = 1, debug = 0;
        char *dev = NULL;
        int fd, res = 0;

        while ((opt = getopt(argc, argv, "d:s:c:D")) != -1) {
                switch (opt) {
                case 'd':
                        dev = strdup(optarg);
                        break;
                case 's':
                        sz = atoi(optarg);
                        break;
                case 'c':
                        cnt = atoi(optarg);
                        break;
                case 'D':
                        debug = 1;
                        break;
                }
        }

        /*mknod("/dev/lzfdma", 0x666, MK_DEV(0x254, 0x0));*/
        fd = open("/dev/lzfdma", O_RDONLY);
        if (fd == -1) {
                perror("open");
                return -1;
        }

        if (dev) {
                res = lzs_test(fd, dev, sz, cnt, debug);
                printf("lzs_test res %d\n", res);
        }

        return 0;
}
