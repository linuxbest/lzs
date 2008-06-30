#include <stdio.h>
#include <getopt.h>
#include <stdlib.h>

//#include "liblzs.h"

static unsigned char in_buf[1024 * 1024 * 10];
static unsigned char out_buf[1024 *1024 * 10];
static unsigned char tmp_buf[1024 *1024 * 10];

static int 
do_memcmp(unsigned char *s1, unsigned char *s2, size_t n)
{
        int i;

        for (i = 0; i < n; i++) {
                //fprintf(stderr, "off %x: %x/%x\n", i, *s1, *s2);
                if (*s1 != *s2)
                        goto missing;
                s1 ++;
                s2 ++;
        }
        return 0;
missing:
        fprintf(stderr, "off %x, right/current %x/%x\n", 
                        i, *s2, *s1);
        return -1;
}

static int compress(FILE *fpin, int size, int mode)
{
        int olen, len = sizeof(in_buf), tlen;
        int ret;
        FILE * fpout;
        
        //fprintf(stderr, "size %d, %d\n", len, size);
        fpout = fopen("/tmp/lzs.out", "w+");
        memset(in_buf, 0, len);
        memset(out_buf, 0, len);
        memset(tmp_buf, 0, len);

        len = fread(in_buf, 1, size, fpin);
        if (len == EOF)
                return len;

        if (mode)
                olen = lzsCompress(in_buf, len, out_buf, sizeof(out_buf));
        else
                olen = lzsDecompress(in_buf, len, out_buf, sizeof(out_buf));

        ret = fwrite(out_buf, 1, olen, fpout);

        if (mode) 
                tlen = lzsDecompress(out_buf, olen, tmp_buf, sizeof(tmp_buf));
        else
                tlen = lzsCompress(out_buf, olen, tmp_buf, sizeof(tmp_buf));
        fprintf(stderr, "tlen,len %d, %d, %d\n", tlen, len, olen);
        ret = do_memcmp(tmp_buf, in_buf, len);
        if (ret == 0 && tlen == len) {
                fprintf(stderr, "PASSED\n");
        } else {
                fprintf(stderr, "ERROR\n");
                ret = -1;
        }

        fclose(fpout);

        return ret;
}

int main(int argc, char *argv[])
{
        int size = 512, mode = 'd';
        int p, res, loop = 0;

        while ((p = getopt(argc, argv, "s:cl")) != EOF) {
                switch (p) {
                        case 's':
                                size = atoi(optarg);
                                break;
                        case 'c':
                                mode = 'c';
                                break;
                        case 'l':
                                loop = 1;
                                break;
                        default:
                                break;
                }
        }

        do {
                res = compress(stdin, size, mode == 'c');
        } while (res == 0 && loop);

        return 0;
}
