#ifndef _ASYNC_DMA_H_
#define _ASYNC_DMA_H_

enum ops_enum {
        OP_FILL       = 0,
        OP_MEMCPY     = 1,
        OP_COMPRESS   = 2,
        OP_UNCOMPRESS = 3,
};

/* 
 * this callback runing at interrupt level 
 */
typedef int (*async_cb_t)(void *priv, int err, int osize);

typedef struct {
        char   *buffer;
        int    use_sg;
        int    bufflen;
} sgbuf_t;

int async_submit(sgbuf_t *src, /* source data buffer */
                sgbuf_t *dst,  /* dest data buffer */
                async_cb_t cb, /* callback function */
                int ops,       /* ops */
                void *priv);   /* private for callback */

#endif
