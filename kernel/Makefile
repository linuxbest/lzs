ifneq ($(KERNELRELEASE),)
#SCST_INC_DIR := /p/prod/d/scst/scst/include

obj-m = lzf_dma.o

lzf_dma-objs = lzf_dma.o lzf_chdev.o 

else
ifeq ($(KDIR),)
KVER = $(shell uname -r)
KDIR := /lib/modules/$(KVER)/build
endif

all:
	$(MAKE) -C $(KDIR) SUBDIRS=$(shell pwd)

install: all
	$(MAKE) -C $(KDIR) SUBDIRS=$(shell pwd) \
	modules_install
	-depmod -a $(KVER)

uninstall:
	rm -f $(INSTALL_DIR)/scst_*.ko
endif

EXTRA_CFLAGS += -I$(SUBDIRS)
EXTRA_CFLAGS += -I$(SUBDIRS)/../
EXTRA_CFLAGS += -DEXTRACHECKS
#EXTRA_CFLAGS += -DTRACING
EXTRA_CFLAGS += -DDEBUG -g

clean:
	rm -f *.o *.ko .*.cmd *.mod.c .*.d .depend Modules.symvers \
	   Module.symvers Module.markers modules.order
	   rm -rf .tmp_versions

extraclean:  clean

.PHONY: all install uninstall clean extraclean
