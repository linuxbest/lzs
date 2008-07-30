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
   out_valid, out_data, m_last, hdata, fi_cnt, all_end,
   // Inputs
   m_endn
   );

   parameter IN_WIDTH = 13;
   parameter NEED_STR_WIDTH = 4;
   parameter OUT_WIDTH = 8;
   parameter LZF_WIDTH = 20;
   
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output		all_end;		// From decode_ctl of decode_ctl.v
   output [LZF_WIDTH-1:0]fi_cnt;		// From data of data.v
   output [7:0]		hdata;			// From decode_ctl of decode_ctl.v
   output		m_last;			// From data of data.v
   output [7:0]		out_data;		// From decode_ctl of decode_ctl.v
   output		out_valid;		// From decode_ctl of decode_ctl.v
   // End of automatics
   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input		m_endn;			// To data of data.v
   // End of automatics
   /*AUTOREG*/
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			ce;			// From data of data.v
   wire			clk;			// From data of data.v
   wire [63:0]		fi;			// From data of data.v
   wire			fo_full;		// From data of data.v
   wire			m_src_getn;		// From decode_in of decode_in.v
   wire			rst;			// From data of data.v
   wire			src_empty;		// From data of data.v
   wire			stream_ack;		// From decode_ctl of decode_ctl.v
   wire			stream_valid;		// From decode_in of decode_in.v
   // End of automatics

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

   data data(/*AUTOINST*/
	     // Outputs
	     .clk			(clk),
	     .rst			(rst),
	     .src_empty			(src_empty),
	     .ce			(ce),
	     .fo_full			(fo_full),
	     .m_last			(m_last),
	     .fi			(fi[63:0]),
	     .fi_cnt			(fi_cnt[LZF_WIDTH-1:0]),
	     // Inputs
	     .m_src_getn		(m_src_getn),
	     .m_endn			(m_endn));

   defparam    data.LZF_FILE = "/tmp/decode.src";
   defparam    data.LZF_DEBUG = 1;
   defparam    data.LZF_DELAY = 0;
   defparam    data.LZF_FIFO_AW = 15;
   
   initial
     begin : VCD_and_MEM
	
	$dumpfile("tb.vcd");
	$dumpvars(0,tb);
	
	c = $fopen(src_file, "r");
	o = $fopen(OUT_FILE, "w");
	
	#5000;
	$finish;
     end
   
   decode_in  decode_in(/*AUTOINST*/
			// Outputs
			.m_src_getn	(m_src_getn),
			.stream_data	(stream_data[12:0]),
			.stream_valid	(stream_valid),
			// Inputs
			.clk		(clk),
			.rst		(rst),
			.ce		(ce),
			.fo_full	(fo_full),
			.src_empty	(src_empty),
			.fi		(fi[63:0]),
			.stream_width	(stream_width[3:0]),
			.stream_ack	(stream_ack));
   
   decode_ctl decode_ctl(/*AUTOINST*/
			 // Outputs
			 .stream_width		(stream_width[3:0]),
			 .stream_ack		(stream_ack),
			 .out_data		(out_data[7:0]),
			 .out_valid		(out_valid),
			 .all_end		(all_end),
			 .hdata			(hdata[7:0]),
			 // Inputs
			 .clk			(clk),
			 .rst			(rst),
			 .fo_full		(fo_full),
			 .stream_data		(stream_data[12:0]),
			 .stream_valid		(stream_valid));
   
   reg [7:0] s_data;
   always @(posedge clk)
     begin
	/*if (tb.decode.out_valid) begin
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
	end*/
     end

endmodule // tb

// Local Variables:
// verilog-library-directories:("." "../../rtl/verilog/" "../../../encode/bench/verilog/")
// verilog-library-files:("")
// verilog-library-extensions:(".v" ".h")
// End:
