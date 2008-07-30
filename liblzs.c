/*
 * liblzs.c
 *
 * Copyright (C) Beijing Soul.
 *
 * Hu gang <hugang@soulinfo.com>
 *
 * A compatible LZX base compress/uncompress 
 *
 */
#ifndef __KERNEL__
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
typedef uint8_t  u8;
typedef uint16_t u16;
typedef uint32_t u32;
#else
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/errno.h>
#undef DEBUG
#endif

#include "liblzs.h"

struct sk_buff {
        int len;
        int data_len;
        unsigned char *head;
        unsigned char *data;
        unsigned char *tail;
        unsigned char *end;
};

#ifdef DEBUG
static FILE *fp_debug;
#define dprintf(format, arg...) \
        do {\
                fprintf(fp_debug, "%s:%d:" format, __FUNCTION__, \
                                __LINE__, ## arg); \
        } while (0)
#else
#define dprintf(format, arg...) \
        do {} while (0)
#endif

static void skb_put(struct sk_buff *skb, unsigned int len, unsigned char byte)
{
        dprintf("%02x, %02x\n", skb->len, byte);
        *skb->data = byte;
        skb->data ++;
        skb->len ++;
}

typedef struct _lzs_state {
        u32 word;
        int left;
        u8 *inbuf;
        int inlen;
        u8 zstuff;
        u16 ccnt;
} LZSState;

static int
putBits(LZSState *s, struct sk_buff *skbout, u32 bits, int len)
{
        u8 byte;

        dprintf("%04x, %x\n", bits, len);
        s->word <<= len;
        s->word |= bits;
        s->left += len;

        while(s->left >= 8) {
                s->left -= 8;
                byte = s->word >> (s->left);
                skb_put(skbout, 1, byte);
        }
        if (skbout->len >= skbout->data_len)
                return -1;

        return 0;
}

static int
putLiteralByte(LZSState *s, struct sk_buff *skbout, u8 byte)
{
        if (putBits(s, skbout, 0, 1) != 0)
                return -1;
        if (putBits(s, skbout, byte, 8) != 0)
                return -1;
        return 0;
}

static int
putOffset(LZSState *s, struct sk_buff *skbout, u32 offs)
{
        int off;
        if(offs < 128) {
                off = 3 << 7 | offs;
                dprintf("%x\n", off);
                if (putBits(s, skbout, 3, 2) != 0)
                        return -1;
                if (putBits(s, skbout, offs, 7) != 0)
                        return -1;
        } else {
                off = 2 << 11 | offs;
                dprintf("%x\n", off);
                if (putBits(s, skbout, 2, 2) != 0)
                        return -1;
                if (putBits(s, skbout, offs, 11) != 0)
                        return -1;
        }
        return 0;
}

static int
putLen(LZSState *s, struct sk_buff *skbout, u32 index, int len)
{
        int res;

        switch(len) {
                case 2:
                        res = putBits(s, skbout, 0, 2);
                        break;
                case 3:
                        res = putBits(s, skbout, 1, 2);
                        break;
                case 4:
                        res = putBits(s, skbout, 2, 2);
                        break;
                case 5:
                        res = putBits(s, skbout, 12, 4);
                        break;
                case 6:
                        res = putBits(s, skbout, 13, 4);
                        break;
                case 7:
                        res = putBits(s, skbout, 14, 4);
                        break;
                default:
                        len -= 8;
                        if (putBits(s, skbout, 15, 4) != 0)
                                return -1;
                        while(len >= 15) {
                                if (putBits(s, skbout, 15, 4) != 0)
                                        return -1;
                                len -= 15;
                        }
                        if (putBits(s, skbout, len, 4) != 0)
                                return -1;
        }

        return 0;
}


int 
lzsCompress(const void *const _in_data, unsigned int in_len,
            void             *out_data, unsigned int out_len)
{
        uint8_t *in_data = (uint8_t *)_in_data;
        LZSState lzs_state = {0};
        LZSState *s = &lzs_state;
        uint8_t byte;
        uint32_t htab[256] = {0};
        uint32_t ref;
        uint32_t iidx = 0;

        struct sk_buff lzs_skbout;
        struct sk_buff *skbout = &lzs_skbout;

        lzs_skbout.data_len = out_len - 2; /* keep it safe */
        lzs_skbout.len = 0;
        lzs_skbout.head = lzs_skbout.data = out_data;
#ifdef DEBUG
        fp_debug = fopen("/tmp/encode.log", "w+");
#endif
        dprintf("Enter, %x\n", in_len);
        s->inlen = in_len;

        do {
                int off, tlen, lit = 0;

                /* read byte */
                byte = in_data[iidx];

                /* insert history buffer */

                /* hash function */
                ref = htab[byte];
                htab[byte] = iidx;

                if (iidx == 0){ /* at least 2 byte */
                        iidx ++;
                        continue;
                }

                dprintf("ref %x%x, %x%x, ref %x, iidx %x, inlen %x, %x\n",
                                in_data[ref], in_data[ref-1],
                                in_data[iidx], in_data[iidx-1],
                                ref, iidx, s->inlen, byte);

                off  = iidx - ref;
                if (ref == 0 || in_data[ref-1] != in_data[iidx-1] || off > 2047) {
                        dprintf("litera %x, %x, %x\n", in_data[iidx-1], off, iidx-1);
                        if (putLiteralByte(s, skbout, in_data[iidx-1]) != 0)
                                return -1;
                        iidx ++;
                        continue;
                }
                dprintf("offset is 0x%x, 0x%x\n", off, iidx);

                if (putOffset(s, skbout, off) != 0)
                        return -1;

                tlen = 0;
                for (tlen = 0; tlen + iidx < in_len; tlen ++) {
                        byte = in_data[iidx+tlen]; htab[byte] = iidx+tlen;
                        dprintf("ref/iidx %02x %02x\n", 
                                        in_data[ref+tlen],
                                        in_data[iidx+tlen]);
                        if (in_data[ref+tlen] != in_data[iidx+tlen]) {
                                lit = 1;
                                break;
                        }
                }
                tlen ++;
                //byte = skbin->data[iidx+tlen];
                //htab[byte] = iidx+tlen;
                dprintf("tlen %x, off %x, %x, %x\n", tlen, off, iidx+tlen, byte);
                if (putLen(s, skbout, -1, tlen) != 0)
                        return -1;

                if (tlen + iidx - 1 == in_len && (!lit))
                        goto done;

                iidx += tlen;
        } while (iidx < in_len);
        
        dprintf("litera %x, %x\n", in_data[iidx-1], iidx-1);
        if (putLiteralByte(s, skbout, in_data[iidx-1]) != 0)
                return -1;
done:
        putBits(s, skbout, 0x180, 9);
        putBits(s, skbout, 0x00, 16);
        putBits(s, skbout, 0x00, 16);
        putBits(s, skbout, 0, 16);
        dprintf("Leave, %x\n", skbout->len);
#ifdef DEBUG
        fclose(fp_debug);
#endif
        return skbout->len;
}

/* 
 * decompress 
 *
 */
static  void pullByte(LZSState *s)
{
        u8 byte;

        if(s->inlen) {
                byte = *s->inbuf++;
                s->inlen--;
                s->word |= (byte << (8 - s->left));
                s->left += 8;
        } else {
                if(s->zstuff > 0) {
                        s->zstuff++;
                } else {
                        s->zstuff = 1;
                }
        }
}

static  u32 get1(LZSState *s)
{
        u32 ret;

        if(s->left < 1)
                pullByte(s);

        ret = s->word & 0x8000;
        s->word <<= 1;
        s->left--;
        return ret;
}

static  u32 get2(LZSState *s)
{
        register u32 ret;

        if(s->left < 2)
                pullByte(s);
        ret = s->word & 0xc000;
        s->word <<= 2;
        s->left -= 2;
        return ret;
}



static  u32 get4(LZSState *s)
{
        register u32 ret;

        if(s->left < 4)
                pullByte(s);
        ret = s->word & 0xf000;
        s->word <<= 4;
        s->left -= 4;
        return ret;
}


static  u32 get7(LZSState *s)
{
        register u32 ret;

        if(s->left < 7)
                pullByte(s);
        ret = s->word & 0xfe00;
        s->word <<= 7;
        s->left -= 7;
        return ret;
}



static  u32 get8(LZSState *s)
{
        register u32 ret;

        if(s->left < 8)
                pullByte(s);
        ret = s->word & 0xff00;
        s->word <<= 8;
        s->left -= 8;
        return ret;
}

static  u32 get11(LZSState *s)
{
        register u32 ret;

        ret = get7(s);
        ret |= get4(s) >> 7;

        return ret;
}

static  int getCompLen(LZSState *s)
{
        register int clen, nibble;

        switch(get2(s)) {
                case 0x0000:
                        return 2;
                case 0x4000:
                        return 3;
                case 0x8000:
                        return 4;
                default:
                        break;
        }

        switch(get2(s)) {
                case 0x0000:
                        return 5;
                case 0x4000:
                        return 6;
                case 0x8000:
                        return 7;
                default:
                        break;
        }

        clen = 8;
        do {
                nibble = get4(s) >> 12;
                dprintf("nibble %x\n", nibble);
                clen += nibble;
        } while(nibble == 0xf);

        return clen;
}

int lzsDecompress(const void *const in_data,  unsigned int in_len,
                void             *out_data, unsigned int out_len)
{
        int offs, clen;
        LZSState lzs_state = {0};
        LZSState *s = &lzs_state;
        u8 *op = out_data, *ref;

        s->inbuf = (void *)in_data;
        s->inlen = in_len;
#ifdef DEBUG
        fp_debug = fopen("/tmp/decode.log", "w+");
#endif
        dprintf("Enter\n");
        do {
                if (op - (uint8_t *)out_data > out_len)
                        return -1;

                if (get1(s) == 0) {
                        *op = get8(s) >> 8;
                        dprintf("get1, %02x, %x\n", *op, op - (uint8_t *)out_data);
                        op ++;
                        continue;
                }

                if (get1(s)) {
                        offs = get7(s)  >> 9;
                        dprintf("offset7 , %x, %x\n", offs, s->inlen);
                } else {
                        offs = get11(s) >> 5;
                        dprintf("offset11, %x, %x\n", offs, s->inlen);
                }
                if (!offs) /* end marker */
                        break;

                clen = getCompLen(s);
                if (!clen)
                        return -1;

                dprintf("off %x, len %x, %x\n", 
                                offs, clen, out_len);
                ref = op - offs;
                do {
                        *op = *ref;
                        dprintf("put, %02x, %x\n", *op, op - (uint8_t *)out_data);
                        op ++;
                        ref ++;
                } while (--clen);
        } while (s->zstuff == 0);

        dprintf("Leave\n");
#ifdef DEBUG
        fclose(fp_debug);
#endif
        return op - (uint8_t *)out_data;
}

#ifdef MAIN
#include <assert.h>
#define IfPrint(c) (c >= 32 && c < 127 ? c : '.')
static void HexDump (unsigned char *p_Buffer, unsigned long p_Size)
{
        unsigned long l_Index;
        unsigned char l_Row [17];

        for (l_Index = l_Row [16] = 0; l_Index < p_Size || l_Index % 16; 
                        ++l_Index) {
                if (l_Index % 16 == 0)
                        printf("%05x   ", (unsigned int)l_Index);
                printf("%02x ", l_Row [l_Index % 16] = 
                                (l_Index < p_Size ? p_Buffer [l_Index] : 0));
                l_Row [l_Index % 16] = IfPrint (l_Row [l_Index % 16]);
                if ((l_Index + 1) % 16 == 0)
                        printf("   %s\n", l_Row);
        }
        if ((l_Index % 16) != 0)
                printf("\n");
}

struct test_data {
        unsigned char compress[1024 * 1024];
        unsigned int compress_len;

        unsigned char uncompress[1024 * 1024];
        unsigned int uncompress_len;
} tdb[] = {
        {
                .compress = {0x20,0x90,0x88,0x38,0x1c,0x21,0xe2,0x5c,0x15,0x80},
                .compress_len = 10,
                .uncompress = "ABAAAAAACABABABA",
                .uncompress_len = 16,
        },
        { .compress_len = 0, },
};

int main(int argc, char *argv[])
{
        struct sk_buff in, out;
        struct test_data *p = tdb;
        unsigned char out_buf[1024 * 1024];
        unsigned char in_buf[1024 * 1024];
        unsigned char tmp_buf[1024 * 1024];
        int ret;

        while (p->compress_len) {
                ret = lzsCompress(p->uncompress, p->uncompress_len, 
                                out_buf, 1024 * 1024);
                if (ret != 0) 
                        break;
                p->compress_len = ret;
                if (bcmp(p->compress, out.head, p->compress_len) != 0) {
                        printf("orig      : \n");
                        HexDump(in.data, p->uncompress_len);
                        printf("compress  : %d\n", out.len);
                        HexDump(out.head, out.len);
                        printf("except    : %d\n", p->compress_len);
                        HexDump(p->compress, p->compress_len);
                }

                memset(out_buf, 0, out.len);
                out.len = lzsDecompress(p->compress, p->compress_len, 
                                out_buf, 1024 * 1024);
                if (bcmp(p->uncompress, out.head, out.len) != 0) {
                        printf("uncompress:\n");
                        HexDump(out.head, out.len);
                }
                p ++;
        }

        int i, tsize = 65536;
        for (i = 0; i < tsize; i ++) 
                in_buf[i] = i;
       
        memset(out_buf, 0, 1024 * 1024);
        out.len = lzsCompress(in_buf, i, out_buf, 1024 * 1024);
        printf("compress   %d, %d\n", i, out.len);
        out.len = lzsDecompress(out_buf, out.len, tmp_buf, 1024 * 1024);
        printf("uncompress %d, %d\n", in.len, out.len);

        if (bcmp(in_buf, tmp_buf, i) != 0) {
                //HexDump(out.head, out.len);
                HexDump(out.head, out.len);
        }

        return 0;
}
#endif
