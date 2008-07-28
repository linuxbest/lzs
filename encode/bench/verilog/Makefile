top: top.v /tmp/encode.src /tmp/encode.chk 
	iverilog -Wall -o top top.v

trun: top
	vvp top +size=${SIZE}

clean:
	rm -f top *.vcd


FILE := "../../../files/01"
SIZE := "512"

/tmp/encode.src:
	cp ${FILE} $@

/tmp/encode.chk: /tmp/encode.src
	../../../lzs -s ${SIZE} -c < /tmp/encode.src
	cp /tmp/lzs.out $@
