OBJS += tb_data.v
OBJS += ../../rtl/verilog/decode.v
OBJS += ../../rtl/verilog/state_machine.v
OBJS += ../../rtl/verilog/copy_ref.v
OBJS += ../../rtl/verilog/output_token.v
OBJS += ../../rtl/verilog/history_ram.v

D_SRC = /tmp/decode.src

tb : tb.v ${OBJS} ${D_SRC}
	iverilog -o $@ tb.v ${OBJS}
	vvp tb +SRC_FILE=${D_SRC}

/tmp/decode.src: ../../../files/01 ../../../lzs
	../../../lzs -s 512 -c < ../../../files/01
	cp /tmp/lzs.out $@

clean :
	rm -f tb *.mem *.vcd
