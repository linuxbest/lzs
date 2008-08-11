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
static int debug = 0;
static int apidev_major = 0;

/* vvvvvvvv  following code borrowed from st driver's direct IO vvvvvvvvv */
	/* hopefully this generic code will moved to a library */

/* Pin down user pages and put them into a scatter gather list. Returns <= 0 if
   - mapping of all pages not successful
   - any page is above max_pfn
   (i.e., either completely successful or fails)
*/
static int 
st_map_user_pages(struct scatterlist *sgl, const unsigned int max_pages, 
	          unsigned long uaddr, size_t count, int rw,
	          unsigned long max_pfn)
{
	int res, i, j;
	unsigned int nr_pages;
	struct page **pages;

	nr_pages = ((uaddr & ~PAGE_MASK) + count + ~PAGE_MASK) >> PAGE_SHIFT;

	/* User attempted Overflow! */
	if ((uaddr + count) < uaddr)
		return -EINVAL;

	/* Too big */
        if (nr_pages > max_pages)
		return -ENOMEM;

	/* Hmm? */
	if (count == 0)
		return 0;

	if ((pages = kmalloc(max_pages * sizeof(*pages), GFP_ATOMIC)) == NULL)
		return -ENOMEM;

        /* Try to fault in all of the necessary pages */
	down_read(&current->mm->mmap_sem);
        /* rw==READ means read from drive, write into memory area */
	res = get_user_pages(
		current,
		current->mm,
		uaddr,
		nr_pages,
		rw == READ,
		0, /* don't force */
		pages,
		NULL);
	up_read(&current->mm->mmap_sem);

	/* Errors and no page mapped should return here */
	if (res < nr_pages)
		goto out_unmap;

        for (i=0; i < nr_pages; i++) {
                /* FIXME: flush superflous for rw==READ,
                 * probably wrong function for rw==WRITE
                 */
		flush_dcache_page(pages[i]);
		if (page_to_pfn(pages[i]) > max_pfn)
			goto out_unlock;
		/* ?? Is locking needed? I don't think so */
		/* if (TestSetPageLocked(pages[i]))
		   goto out_unlock; */
        }

	/* Populate the scatter/gather list */
	sgl[0].page = pages[0]; 
	sgl[0].offset = uaddr & ~PAGE_MASK;
	if (nr_pages > 1) {
		sgl[0].length = PAGE_SIZE - sgl[0].offset;
		count -= sgl[0].length;
		for (i=1; i < nr_pages ; i++) {
			sgl[i].offset = 0;
			sgl[i].page = pages[i]; 
			sgl[i].length = count < PAGE_SIZE ? count : PAGE_SIZE;
			count -= PAGE_SIZE;
		}
	}
	else {
		sgl[0].length = count;
	}

	kfree(pages);
	return nr_pages;

 out_unlock:
	/* for (j=0; j < i; j++)
	   unlock_page(pages[j]); */
	res = 0;
 out_unmap:
	if (res > 0)
		for (j=0; j < res; j++)
			page_cache_release(pages[j]);
	kfree(pages);
	return res;
}


/* And unmap them... */
static int 
st_unmap_user_pages(struct scatterlist *sgl, const unsigned int nr_pages,
		    int dirtied)
{
	int i;

	for (i=0; i < nr_pages; i++) {
		if (dirtied && !PageReserved(sgl[i].page))
			SetPageDirty(sgl[i].page);
		/* unlock_page(sgl[i].page); */
		/* FIXME: cache flush missing for rw==READ
		 * FIXME: call the correct reference counting function
		 */
		page_cache_release(sgl[i].page);
	}

	return 0;
}

static wait_queue_head_t wait;

static int async_done(void *priv, int err, int osize)
{
        sioctl_t *sio = priv;

        dprintk("err %d, osize %d\n", err, osize);
        sio->err = err;
        sio->osize = osize;
        sio->done = 1;
        wake_up_all(&wait);

        return 0;
}

static sgbuf_t sgbuf_src, sgbuf_dst;

static int map_sio(sioctl_t *sio)
{
        struct scatterlist *sgl_src, *sgl_dst;
        int max_sg = 512, res = 0;

        sgl_src = kmalloc(sizeof(struct scatterlist) * max_sg, GFP_KERNEL);
        sgl_dst = kmalloc(sizeof(struct scatterlist) * max_sg, GFP_KERNEL);
        dprintk("src %p, dst %p\n", sgl_src, sgl_dst);
        res = st_map_user_pages(sgl_src, max_sg, sio->src, sio->slen,
                        READ, ULONG_MAX);
        dprintk("res %d\n", res);
        if (res <= 0) 
                return -1;
        sgbuf_src.buffer = (char *)sgl_src;
        sgbuf_src.use_sg = res;
        sgbuf_src.bufflen = sio->slen;

        res = st_map_user_pages(sgl_dst, max_sg, sio->dst, sio->dlen,
                        WRITE, ULONG_MAX);
        dprintk("res %d\n", res);
        if (res <= 0) 
                goto out;
        sgbuf_dst.buffer = (char *)sgl_dst;
        sgbuf_dst.use_sg = res;
        sgbuf_dst.bufflen = sio->dlen;

        sio->done = 0;
        res = async_submit(&sgbuf_src, &sgbuf_dst, async_done, sio->ops, 
                        sio, 1);
        if (res)
                goto out;
        wait_event_timeout(wait, sio->done, 5*HZ);
        if (sio->done == 0 || (sio->flags & SIO_DEBUG)) {
                async_dump_register();
        }

        st_unmap_user_pages(sgl_dst, sgbuf_dst.use_sg, 1);
        st_unmap_user_pages(sgl_src, sgbuf_src.use_sg, 0);
        kfree(sgl_src);
        kfree(sgl_dst);
out:
        return res;
}

static int apidev_open(struct inode *inode, struct file *file)
{
        dprintk("inode %p, file %p\n", inode, file);
        return 0;
}

static int apidev_close(struct inode *inode, struct file *file)
{
        dprintk("inode %p, file %p\n", inode, file);
        return 0;
}

static int apidev_ioctl(struct inode *inode, struct file *fp,
                unsigned int cmd, unsigned long arg)
{
        int res = 0;
        sioctl_t sio;

        dprintk("cmd %x, arg %lx\n", cmd, arg);

        res = copy_from_user(&sio, (void *)arg, sizeof(sio));
        dprintk("res %x\n", res);
        if (res) {
                return res;
        }
        dprintk("ops %d, src %x, slen %x, dst %x, dlen %x\n",
                        sio.ops, sio.src, sio.slen, 
                        sio.dst, sio.dlen);
        res = map_sio(&sio);
        dprintk("res %x\n", res);
        copy_to_user((void*)arg, (void *)&sio, sizeof(sio));

        return res;
}

static struct file_operations fops = {
        .ioctl = apidev_ioctl,
        .open  = apidev_open,
        .release = apidev_close,
};

void exit_chdev(void)
{
        unregister_chrdev(apidev_major, "lzfdma");
}

int init_chdev(void)
{
        apidev_major = register_chrdev(0, "lzfdma", &fops);
        init_waitqueue_head(&wait);

        return apidev_major;
}
