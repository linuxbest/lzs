/******************************************************************************
 *   File Name :  top.v
 *     Version :  0.1
 *        Date :  2008 02 27
 *  Description:  data source module
 * Dependencies:
 *
 *
 *      Company:  Beijing Soul
 *
 *          BUG:
 *
 *****************************************************************************/
`timescale 1ns/1ns
`include "../../rtl/verilog/encode_dp.v"
`include "../../rtl/verilog/encode_ctl.v"
`include "../../rtl/verilog/encode_out.v"
`include "../../rtl/verilog/encode.v"
`include "data.v"

module top(/*AUTOARG*/
   // Outputs
   m_dst_putn, m_dst_last, m_dst, fi_cnt
   );
   parameter LZF_WIDTH = 20;
   
   /*AUTOINPUT*/
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output [LZF_WIDTH-1:0]fi_cnt;		// From data of data.v
   output [63:0]	m_dst;			// From encode of encode.v
   output		m_dst_last;		// From encode of encode.v
   output		m_dst_putn;		// From encode of encode.v
   // End of automatics
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			ce;			// From data of data.v
   wire			clk;			// From data of data.v
   wire [63:0]		fi;			// From data of data.v
   wire			fo_full;		// From data of data.v
   wire			m_endn;			// From encode of encode.v
   wire			m_last;			// From data of data.v
   wire			m_src_getn;		// From encode of encode.v
   wire			rst;			// From data of data.v
   wire			src_empty;		// From data of data.v
   // End of automatics

   pullup(m_src_getn);
   pullup(m_dst_putn);
   pullup(m_endn);
   
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
   
   defparam 		
	   data.LZF_FILE = "/tmp/encode.src";
   /*defparam
 	   data.LZF_SIZE = 512;*/
   defparam
	   data.LZF_DEBUG = 0;
   defparam
	   data.LZF_DELAY = 20;
   defparam
	   data.LZF_FIFO_AW = 15;

   encode encode(/*AUTOINST*/
		 // Outputs
		 .m_dst			(m_dst[63:0]),
		 .m_dst_last		(m_dst_last),
		 .m_dst_putn		(m_dst_putn),
		 .m_endn		(m_endn),
		 .m_src_getn		(m_src_getn),
		 // Inputs
		 .ce			(ce),
		 .clk			(clk),
		 .fi			(fi[63:0]),
		 .fo_full		(fo_full),
		 .m_last		(m_last),
		 .rst			(rst),
		 .src_empty		(src_empty));

   parameter 		OUT_FILE = "/tmp/t.lzs";
   integer 		f;
   //parameter 		CHECK_FILE = "/tmp/c.lzs";
   parameter 		CHECK_FILE = "/tmp/encode.chk";
   integer 		c, cnt;
   
   initial begin
      $dumpfile("tb.vcd");
      $dumpvars(0, top);
      $write("using %s as source file size is %d\n", 
	     data.LZF_FILE, data.fi_cnt);
      $write("using %s as check file\n",
	     CHECK_FILE);
      $write("output file is %s\n",
	     OUT_FILE);
   end

   reg [7:0] data;
   always @(posedge clk or posedge rst)
     begin
	if (rst) begin
	   f = $fopen(OUT_FILE, "w");
	   c = $fopen(CHECK_FILE, "r");
	   cnt = 0;
	end else if (encode.out.doe) begin
	   data = $fgetc(c);
	   /*if (data == encode.out.do[15:08])
	     $write("cnt %h: high right %h\n", cnt, encode.out.do[15:08]);*/
	   if (data != encode.out.do[15:08]) begin
	      $write("cnt %h: right/current %h/%h\n", 
		     cnt, data, encode.out.do[15:08]);
	      $dumpflush(".");
	      $stop;
	   end
	   $fputc(f, encode.out.do[15:08]);
	   cnt = cnt + 1;

	   data = $fgetc(c);
	   /*if (data == encode.out.do[07:00])
	     $write("cnt %h: low  right %h\n", cnt, encode.out.do[07:00]);*/
	   if (data != encode.out.do[07:00]) begin
	      $write("cnt %h: right/current %h/%h\n", 
		     cnt, data, encode.out.do[07:00]);
	      $dumpflush(".");
	      $stop;
	   end
	   $fputc(f, encode.out.do[07:00]);
	   cnt = cnt + 1;
	end
     end // always @ (posedge clk)

endmodule // top

// Local Variables:
// verilog-library-directories:("." "../../common/" "../../rtl/verilog/")
// verilog-library-files:("")
// verilog-library-extensions:(".v" ".h")
// End:
