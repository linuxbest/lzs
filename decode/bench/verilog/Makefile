OBJS += tb_data.v
OBJS += ../../rtl/verilog/decode.v
OBJS += ../../rtl/verilog/state_machine.v
OBJS += ../../rtl/verilog/copy_ref.v
OBJS += ../../rtl/verilog/output_token.v
OBJS += ../../rtl/verilog/history_ram.v

D_SRC  = /tmp/decode.src
C_FILE = /tmp/decode.chk

tb : tb.v ${OBJS} ${D_SRC}
	iverilog -o $@ tb.v ${OBJS} -y../../rtl/verilog/

trun: tb ${D_SRC} ${C_FILE}
	vvp tb +LZS_FILE=${D_SRC} +SRC_FILE=${C_FILE} +LZS_SIZE=299

/tmp/decode.src: ../../../files/01 ../../../lzs
	../../../lzs -s 512 -c < ../../../files/01
	cp /tmp/lzs.out $@

/tmp/decode.chk: /tmp/decode.src
	../../../lzs -d < /tmp/decode.src
	cp /tmp/lzs.out $@
		
clean :
	rm -f tb *.mem *.vcd
