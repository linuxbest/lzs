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

/* Debug */
#define dprintk(format, a...) \
        do { \
                if (debug) printk("%s:%d "format, __FUNCTION__, __LINE__, ##a);\
        } while (0)

static int debug = 0;
MODULE_PARM(debug, "i");
MODULE_PARM_DESC(debug, "debug flag");

static int ops = 0;
MODULE_PARM(ops, "i");
MODULE_PARM_DESC(ops, "ops");

static int cnt = 2;
MODULE_PARM(cnt, "i");
MODULE_PARM_DESC(ops, "cnt");

static int loop = 1;
MODULE_PARM(loop, "i");
MODULE_PARM_DESC(loop, "loop");

static int order = 0;
MODULE_PARM(order, "i");
MODULE_PARM_DESC(order, "loop");

/* backport hexdump.c */
enum {
        DUMP_PREFIX_NONE,
        DUMP_PREFIX_ADDRESS,
        DUMP_PREFIX_OFFSET
};
#define bool int
#define hex_asc(x)  "0123456789abcdef"[x]
#include "hexdump.c"

static LIST_HEAD(head);

typedef struct {
        struct scatterlist src_sg[64];
        struct scatterlist dst_sg[64];

        sgbuf_t sgbuf_src, sgbuf_dst;

        struct list_head entry;
} queue_t;

static int 
init_queue(void)
{
        queue_t *q;
        int i;
        struct scatterlist *sg;
        
        q = kmalloc(sizeof(*q), GFP_KERNEL);
        sg= q->src_sg;

        for (i = 0; i < 64; i++, sg++) {
                sg->page = alloc_pages(GFP_KERNEL, order);
                sg->offset = 0;
                sg->length = PAGE_SIZE << order;
                if (ops == 3) {
                        int j;
                        char *s = page_address(sg->page);
                        for(j = 0;j < sg->length; j++)  {
                                s[j] = j;
                        }
                } 
                if (ops == 6)
                        memset(page_address(sg->page), 0xff, sg->length);
        }
        q->sgbuf_src.buffer = (char *)q->src_sg;
        q->sgbuf_src.use_sg = 64;
        q->sgbuf_src.bufflen= (PAGE_SIZE<<order) * 64;

        sg= q->dst_sg;
        for (i = 0; i < 64; i++, sg++) {
                sg->page = alloc_pages(GFP_KERNEL, order);
                sg->offset = 0;
                sg->length = PAGE_SIZE << order;
                memset(page_address(sg->page), 0xff, sg->length);
        }
        q->sgbuf_dst.buffer = (char *)q->dst_sg;
        q->sgbuf_dst.use_sg = 64;
        q->sgbuf_dst.bufflen= (PAGE_SIZE<<order) * 64;

        list_add_tail(&q->entry, &head);
}

static atomic_t job;
static wait_queue_head_t wait;

static int async_done(void *priv, int err, uint32_t osize, uint32_t hash)
{
        atomic_dec(&job);
        dprintk("%p, %d, %d, %d\n", priv, err, osize, atomic_read(&job));
        wake_up_all(&wait);
        return 0;
}

extern unsigned long long do_getccnt(unsigned long *hi, unsigned long *lw);

static int __init lzf_init(void)
{
        int i;
        queue_t *q;
        unsigned long start = jiffies, e_jiffies;
        unsigned long long s = 0, e = 0;
        unsigned long size = (64 * (PAGE_SIZE<<order) * cnt) >> 10;
        unsigned long used = 0;
        unsigned long KB   = 0;

        for (i = 0; i < cnt; i++) {
                init_queue();
        }
        init_waitqueue_head(&wait); 
        atomic_set(&job, 0);

        do {
                i = cnt;
                list_for_each_entry(q, &head, entry) {
                        atomic_inc(&job);
                        i --;
                        /*dprintk("%d\n", i);*/
                        if (i == 0) {
                                start = jiffies;
                                s = do_getccnt(NULL, NULL);
                        }
                        async_submit(&q->sgbuf_src, &q->sgbuf_dst, 
                                        async_done, ops, NULL, i == 0);
                }

                wait_event_timeout(wait, atomic_read(&job) == 0, 5*HZ);
                e = do_getccnt(NULL, NULL);
                e_jiffies = jiffies;
                if (atomic_read(&job) != 0) {
                        break;
                }
                used = (e-s) >> 20;
                KB   = (size * 500) / used;
                printk("jiffies %ld, cycles %lld, speed %08ld KB/s \n",
                                e_jiffies-start, e-s, KB);
                loop --;
        } while (loop > 0);

        if (loop > 0)
                async_dump_register();

        return 0;
}

static void __exit lzf_exit(void)
{
        queue_t *q, *p;

        list_for_each_entry_safe(p, q, &head, entry) {
                int i;
                for (i = 0; i < 64; i ++)
                        __free_pages(p->src_sg[i].page, order);
                for (i = 0; i < 64; i ++)
                        __free_pages(p->dst_sg[i].page, order);
                list_del(&p->entry);
                kfree(p);
        }
}

module_init(lzf_init);
module_exit(lzf_exit);
MODULE_LICENSE("GPL");
