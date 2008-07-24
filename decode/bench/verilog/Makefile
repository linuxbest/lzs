OBJS += tb_data.v
OBJS += ../src/decode.v
OBJS += ../../state_machine/src/state_machine.v
OBJS += ../../copy_ref/src/copy_ref.v
OBJS += ../../output_token/src/output_token.v
OBJS += ../../history_ram/src/history_ram.v

tb : tb.v ${OBJS}
	iverilog -o $@ tb.v
	vvp tb

clean :
	rm -f tb *.mem *.vcd
