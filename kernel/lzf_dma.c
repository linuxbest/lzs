/*
 * lzs dma module for kernel 2.6.10 
 *
 */
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/version.h>
#include <linux/errno.h>
#include <linux/pci.h>
#include <linux/delay.h>
#include <linux/interrupt.h>

#include "async_dma.h"
#include "lzf_hw.h"
#include "lzf_chip.h"

/* backport hexdump.c */
enum {
        DUMP_PREFIX_NONE,
        DUMP_PREFIX_ADDRESS,
        DUMP_PREFIX_OFFSET
};
#define bool int
#define hex_asc(x)  "0123456789abcdef"[x]
#include "hexdump.c"

static int __devinit lzf_probe(struct pci_dev  *pdev, 
                const struct pci_device_id *id)
{
       int res = 0;
        /* TODO */
       return res;
}

static void __devexit lzf_remove(struct pci_dev *pdev)
{
        /* TODO */
}

static void lzf_shutdown(struct device *dev)
{
        /* TODO */
}

static struct pci_device_id lzf_pci_table[] = {
        { 0x0100, 0x0003, PCI_ANY_ID, PCI_ANY_ID},
        { 0 },
};

static struct pci_driver lzf_driver = {
        .name      = "lzf",
        .id_table  = lzf_pci_table,
        .probe     = lzf_probe,
        .remove    = __devexit_p(lzf_remove),
        .driver    = {
                .shutdown = lzf_shutdown,
        },
};
        
static int __init lzf_init(void)
{
        return pci_module_init(&lzf_driver);
}

static void __exit lzf_exit(void)
{
        pci_unregister_driver(&lzf_driver);
}

module_init(lzf_init);
module_exit(lzf_exit);
MODULE_LICENSE("GPL");
