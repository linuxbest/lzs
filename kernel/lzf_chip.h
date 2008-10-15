#ifndef _LZF_CHIP_H_
#define _LZF_CHIP_H_

/* Data bit */
#define BIT_0	0x1
#define BIT_1	0x2
#define BIT_2	0x4
#define BIT_3	0x8
#define BIT_4	0x10
#define BIT_5	0x20
#define BIT_6	0x40
#define BIT_7	0x80
#define BIT_8	0x100
#define BIT_9	0x200
#define BIT_10	0x400
#define BIT_11	0x800
#define BIT_12	0x1000
#define BIT_13	0x2000
#define BIT_14	0x4000
#define BIT_15	0x8000
#define BIT_16	0x10000
#define BIT_17	0x20000
#define BIT_18	0x40000
#define BIT_19	0x80000
#define BIT_20	0x100000
#define BIT_21	0x200000
#define BIT_22	0x400000
#define BIT_23	0x800000
#define BIT_24	0x1000000
#define BIT_25	0x2000000
#define BIT_26	0x4000000
#define BIT_27	0x8000000
#define BIT_28	0x10000000
#define BIT_29	0x20000000
#define BIT_30	0x40000000
#define BIT_31	0x80000000

enum {
        OFS_CCR = 0x0,
#define CCR_APPEND BIT_0
#define CCR_ENABLE BIT_1
#define CCR_C_INTP BIT_2 /* clear interrupt pending */
        OFS_CSR = 0x4,
#define CSR_INTP   BIT_0 /* interrupt pending */
#define CSR_BUSY   BIT_1 /* busy */
        OFS_DAR = 0x8,
        OFS_NDAR= 0xC,
};

typedef struct {
        uint32_t next_desc; /* 0 [31:03] */
        uint32_t ctl_addr;  /* 1 [31:03] */
        uint32_t dc_fc;     /* 2 [15:00] dc 
                                 [23:16] fc */
        uint32_t u0;        /* 3 */
        uint32_t src_desc;  /* 4 [31:3] */
        uint32_t u1;        /* 5 */
        uint32_t dst_desc;  /* 6 [31:3] */
        uint32_t u2;        /* 7 */
} __attribute__ ((packed)) job_desc_t;

typedef struct {
#define LZF_MAX_SG_ELEM_LEN /*0xffff*/0x7fff8/*1<<16<<3 - 8*/
#define LZF_SG_LAST         BIT_20
        uint32_t desc;      /* 0 [15:00] total size 
                                 [20]    LAST */
        uint32_t desc_adr;  /* 1 [31:03] */
        uint32_t desc_next; /* 3 [31:03] */

        uint32_t u[5];      /* u[0] this desc hw address
                               u[1] next desc sf address
                               u[2] 
                               u[3] 

                               */
} __attribute__ ((packed)) buf_desc_t;

typedef struct {
        uint32_t ocnt;      /* 0 */
        uint32_t u0;        /* 1 */
        uint32_t err;       /* 2 */
        uint32_t u1;        /* 3 */
        uint32_t cycle;     /* 4 */
        uint32_t hash;      /* 5 */
        uint32_t dc_fc;     /* 6 */
        uint32_t u3;        /* 7 */
} __attribute__ ((packed)) res_desc_t;

enum ec_ops {
        DC_NULL       = (1<<0)/*0x1*/,
        DC_READ       = (1<<1)/*0x2*/,
        DC_WRITE      = (1<<2)/*0x4*/,
        DC_FILL       = (1<<3)|DC_WRITE/*0x0c*/,
        DC_MEMCPY     = (1<<4)|DC_READ|DC_WRITE/*0x16*/,
        DC_COMPRESS   = (1<<5)|DC_READ|DC_WRITE/*0xa6*/,
        DC_UNCOMPRESS = (1<<6)|DC_READ|DC_WRITE/*0xc6*/,
        DC_CTRL       = (1<<7),

        DC_HASH       = (1<<8)|DC_READ,
        DC_COMPARE    = (1<<9)|DC_READ,
        DC_CONT       = (1<<10),
        DC_INTR_EN    = (1<<11), /* Enable Interrupt */
        DC_NREAD      = (1<<12)|DC_READ, /* Null READ */
};

#endif
