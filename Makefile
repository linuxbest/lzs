CFLAGS += -Wall -g

CFLAGS += ${LZS_CFLAGS_ENV}

tlzs: liblzs.c
	gcc ${CFLAGS} -DMAIN -o $@ $^

lzs: liblzs.c lzs.c
	gcc ${CFLAGS} -o $@ $^
