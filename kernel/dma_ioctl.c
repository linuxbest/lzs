
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/version.h>
#include <linux/errno.h>
#include <linux/pci.h>
#include <linux/delay.h>
#include <linux/interrupt.h>
#include <linux/uio.h>
#include <asm/uaccess.h>
#include <asm/dma-mapping.h>
#include <asm/scatterlist.h>

#include "async_dma.h"
typedef struct {
        sgbuf_t src_sg, dst_sg;
        char *src, *dst;
} ioctl_t;

static int ioctl_cb(void *priv, int err, int osize)
{
        ioctl_t *p = priv;

        printk("cb: %p, %d, %d\n", p, err, osize);

        return 0;
}

static ioctl_t m;

static int __init ioctl_init(void)
{
        char *src, *dst;
        int i = 0;

        src = (char *)get_zeroed_page(GFP_KERNEL);
        dst = (char *)get_zeroed_page(GFP_KERNEL);
        for (i = 0; i < 32; i++)
                src[i] = i;

        m.src_sg.buffer = src;
        m.src_sg.use_sg = 0;
        m.src_sg.bufflen = 4096;
        
        m.dst_sg.buffer = dst;
        m.dst_sg.use_sg = 0;
        m.dst_sg.bufflen = 4096;

        async_submit(&m.src_sg, &m.dst_sg, ioctl_cb, OP_MEMCPY, &m);

        return 0;
}

static void __exit ioctl_exit(void)
{
}

module_init(ioctl_init);
module_exit(ioctl_exit);
MODULE_LICENSE("GPL");
