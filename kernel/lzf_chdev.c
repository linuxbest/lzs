#include <linux/spinlock.h>
#include <linux/blkdev.h>
#include <linux/mempool.h>
#include <linux/list.h>
#include <linux/sched.h>
#include <linux/wait.h>
#include <linux/poll.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <asm/uaccess.h>

#include "async_dma.h"
#include "lzf_chdev.h"

/* Debug */
#define dprintk(format, a...) \
        do { \
                if (debug) printk("%s:%d "format, __FUNCTION__, __LINE__, ##a);\
        } while (0)
static int debug = 1;
static int apidev_major = 0;

static int apidev_open(struct inode *inode, struct file *file)
{
        dprintk("");
        return 0;
}

static int apidev_close(struct inode *inode, struct file *file)
{
        dprintk("");
        return 0;
}

static int apidev_ioctl(struct inode *inode, struct file *fp,
                unsigned int cmd, unsigned long arg)
{
        return 0;
}

static struct file_operations fops = {
        .ioctl = apidev_ioctl,
        .open  = apidev_open,
        .close = apidev_close,
};

void exit_chdev(void)
{
        unregister_chrdev(apidev_major, "lzfdma");
}

int init_chdev(void)
{
        apidev_major = register_chrdev(0, "lzfdma", &fops);
        return apidev_major;
}
