top: top.v /tmp/encode.src /tmp/encode.chk 
	iverilog -Wall -o top top.v -y ../../../common/ -y ../../../decode/rtl/verilog/

I_FILE ?= "../../../files/01"
I_SIZE ?= "512"

trun: top
	vvp top +size=${I_SIZE}

clean:
	rm -f top *.vcd /tmp/encode.*

/tmp/encode.src:
	cp ${I_FILE} $@

/tmp/encode.chk: /tmp/encode.src
	../../../lzs -s ${I_SIZE} -c < /tmp/encode.src
	cp /tmp/lzs.out $@
