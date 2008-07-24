/******************************************************************************
 *
 *           File Name : tb.v
 *             Version : 0.1
 *                Date : Feb 27, 2008
 *         Description : LZS decode testbench
 *        Dependencies :
 *  
 *             Company : Beijing soul
 *              Author : Chen Tong
 * 
 *****************************************************************************/

`timescale 1ns/1ps

module tb(/*AUTOARG*/
   // Outputs
   stream_empty, out_valid, out_data, current_state,
   all_end
   );

   parameter IN_WIDTH = 13;
   parameter NEED_STR_WIDTH = 4;
   parameter OUT_WIDTH = 8;
      
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output		all_end;		// From decode of decode.v
   output [2:0]		current_state;		// From decode of decode.v
   output [7:0]		out_data;		// From decode of decode.v
   output		out_valid;		// From decode of decode.v
   output		stream_empty;		// From data of tb_data.v
   // End of automatics
   /*AUTOINPUT*/
   /*AUTOREG*/
   /*ATUOWIRE*/

   /* Local variable */
   wire [NEED_STR_WIDTH-1:0] stream_width;
   wire [IN_WIDTH-1:0] 	     stream_data;
   // End definition

   integer 		     c, cnt, o;
   parameter 		     SRC_FILE = "/home/kevin/lzf-hg.git/files/texbook.pdf";
   parameter 		     LZS_FILE = "/home/kevin/lzf-hg.git/files/01";
   parameter 		     OUT_FILE = "/tmp/t.lzs";
   parameter                 LZS_SIZE = 299;

   reg [255:0] lzs_file;
   reg [31:0]  lzs_size;
   reg [255:0] src_file;

   initial
   begin : VCD_and_MEM
      
      $dumpfile("tb.vcd");
      $dumpvars(0,tb);
      
      if (0 == $value$plusargs("SRC_FILE=%s", src_file))
        src_file = SRC_FILE;

      cnt = 0;
      c = $fopen(src_file, "r");
      o = $fopen(OUT_FILE, "w");
   end

   wire clk;
   always @(posedge clk)
   if (tb.decode.state.all_end) begin
      //$writememh("history_ram.mem", tb.decode.history.mem);
      # 200;
      $finish;
   end
   
   tb_data data(/*AUTOINST*/
		// Outputs
		.stream_valid		(stream_valid),
		.stream_data		(stream_data[IN_WIDTH-1:0]),
		.stream_empty		(stream_empty),
		.fo_full		(fo_full),
		.clk			(clk),
		.ce_decode		(ce_decode),
		.rst			(rst),
		// Inputs
		.stream_ack		(stream_ack),
		.stream_width		(stream_width[3:0]));

   decode decode(/*AUTOINST*/
		 // Outputs
		 .all_end		(all_end),
		 .current_state		(current_state[2:0]),
		 .out_data		(out_data[7:0]),
		 .out_valid		(out_valid),
		 .stream_ack		(stream_ack),
		 .stream_width		(stream_width[NEED_STR_WIDTH-1:0]),
		 // Inputs
		 .ce_decode		(ce_decode),
		 .clk			(clk),
		 .fo_full		(fo_full),
		 .rst			(rst),
		 .stream_data		(stream_data[IN_WIDTH-1:0]),
		 .stream_valid		(stream_valid));

   reg [7:0] s_data;
   always @(posedge clk)
     begin
	if (tb.decode.out_valid) begin
	   $fputc(o, tb.decode.out_data);
	   s_data = $fgetc(c);
	   if (s_data != tb.decode.out_data) begin
	      $write("cnt %h: right/current %h/%h\n", 
		     cnt, s_data, tb.decode.out_data);
	      $dumpflush(".");
	      $stop;
	   end else
	     $write("cnt %h: right %h \n", cnt, tb.decode.out_data);
	   cnt = cnt + 1;
	end
     end
   
endmodule // tb

// Local Variables:
// verilog-library-directories:("." "../src/")
// verilog-library-files:("")
// verilog-library-extensions:(".v" ".h")
// End:
