OBJS += ../../../encode/bench/verilog/data.v
#OBJS += tb_in.v

I_FILE ?= ../../../files/01
I_SIZE ?= 512
D_SRC  = /tmp/decode.src
C_FILE = /tmp/decode.chk

tb_in : tb_in.v ${OBJS} ${D_SRC} 
	iverilog -o $@ tb_in.v ${OBJS} -y../../rtl/verilog/ -y ../../../common/ -y../../../encode/bench/verilog/

tin_run: tb_in ${D_SRC} ${C_FILE}
	vvp tb_in +LZS_FILE=${D_SRC} +SRC_FILE=${C_FILE} +size=${I_SIZE}

/tmp/decode.src: ../../../lzs ${I_FILE}
	../../../lzs -s ${I_SIZE} -c < ${I_FILE}
	cp /tmp/lzs.out $@

/tmp/decode.chk: /tmp/decode.src
	../../../lzs -s ${I_SIZE} < /tmp/decode.src
	cp /tmp/lzs.out $@
		
clean :
	rm -f tb *.mem *.vcd /tmp/decode.*
