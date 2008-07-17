#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "async_dma.h"

int main(int argc, char *argv[])
{
        char *src;
        char *dst;
        int len = /*1 * 1024 * */0x80;
        sioctl_t sio;
        int fd, res = 0;

        //mknod("/dev/lzfdma", 0666, 
        fd = open("/dev/lzfdma", O_RDONLY);
        if (fd == -1) {
                perror("open");
                return -1;
        }

        src = memalign(16, len);
        dst = memalign(16, len);
        //while (res == 0) {
                //sio.ops = OP_COMPRESS;
                sio.ops = OP_MEMCPY;
                //sio.ops = OP_NULL;
                sio.src = src;
                sio.slen = len;
                sio.dst = dst;
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
