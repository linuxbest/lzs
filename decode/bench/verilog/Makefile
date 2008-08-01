OBJS += ../../../encode/bench/verilog/data.v
OBJS += ../../rtl/verilog/decode.v
OBJS += ../../rtl/verilog/state_machine.v
OBJS += ../../rtl/verilog/copy_ref.v
OBJS += ../../rtl/verilog/output_token.v
OBJS += ../../rtl/verilog/history_ram.v
OBJS += tb_data.v

I_FILE ?= ../../../files/01
I_SIZE ?= 512
D_SRC  = /tmp/decode.src
C_FILE = /tmp/decode.chk

tb : tb.v ${OBJS} ${D_SRC} 
	iverilog -o $@ tb.v ${OBJS} -y../../rtl/verilog/ -y ../../../common/ -y../../../encode/bench/verilog/

trun: tb ${D_SRC} ${C_FILE}
	vvp tb +LZS_FILE=${D_SRC} +SRC_FILE=${C_FILE} +size=${I_SIZE}

/tmp/decode.src: ../../../lzs ${I_FILE}
	../../../lzs -s ${I_SIZE} -c < ${I_FILE}
	cp /tmp/lzs.out $@

/tmp/decode.chk: /tmp/decode.src
	../../../lzs -d < /tmp/decode.src
	cp /tmp/lzs.out $@
		
clean :
	rm -f tb *.mem *.vcd /tmp/decode.*
