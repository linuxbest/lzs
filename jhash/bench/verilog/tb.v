`timescale 1ns/1ps

module tb(/*AUTOARG*/
   // Outputs
   hash_out, hash_done, fi_cnt,
   // Inputs
   m_endn
   );
   parameter LZF_WIDTH = 20;
   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input		m_endn;			// To data of data.v
   // End of automatics
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output [LZF_WIDTH-1:0]fi_cnt;		// From data of data.v
   output		hash_done;		// From jhash_core of jhash_core.v
   output [31:0]	hash_out;		// From jhash_core of jhash_core.v
   // End of automatics
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			ce;			// From data of data.v
   wire			clk;			// From data of data.v
   wire [63:0]		fi;			// From data of data.v
   wire			fo_full;		// From data of data.v
   wire			m_last;			// From data of data.v
   wire			m_src_getn;		// From jhash_in of jhash_in.v
   wire			rst;			// From data of data.v
   wire			src_empty;		// From data of data.v
   wire			stream_ack;		// From jhash_core of jhash_core.v
   wire [31:0]		stream_data0;		// From jhash_in of jhash_in.v
   wire [31:0]		stream_data1;		// From jhash_in of jhash_in.v
   wire [31:0]		stream_data2;		// From jhash_in of jhash_in.v
   wire			stream_done;		// From jhash_in of jhash_in.v
   wire [1:0]		stream_left;		// From jhash_in of jhash_in.v
   wire			stream_valid;		// From jhash_in of jhash_in.v
   // End of automatics
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
   defparam  data.LZF_FILE = "/tmp/decode.chk";
   defparam  data.LZF_DEBUG = 0;
   defparam  data.LZF_DELAY = 4;
   defparam  data.LZF_FIFO_AW = 5;

   jhash_in jhash_in     (/*AUTOINST*/
			  // Outputs
			  .m_src_getn		(m_src_getn),
			  .stream_data0		(stream_data0[31:0]),
			  .stream_data1		(stream_data1[31:0]),
			  .stream_data2		(stream_data2[31:0]),
			  .stream_valid		(stream_valid),
			  .stream_done		(stream_done),
			  .stream_left		(stream_left[1:0]),
			  // Inputs
			  .ce			(ce),
			  .clk			(clk),
			  .fi			(fi[63:0]),
			  .fo_full		(fo_full),
			  .m_last		(m_last),
			  .rst			(rst),
			  .src_empty		(src_empty),
			  .stream_ack		(stream_ack));
   jhash_core jhash_core (/*AUTOINST*/
			  // Outputs
			  .stream_ack		(stream_ack),
			  .hash_out		(hash_out[31:0]),
			  .hash_done		(hash_done),
			  // Inputs
			  .clk			(clk),
			  .rst			(rst),
			  .stream_data0		(stream_data0[31:0]),
			  .stream_data1		(stream_data1[31:0]),
			  .stream_data2		(stream_data2[31:0]),
			  .stream_valid		(stream_valid),
			  .stream_done		(stream_done),
			  .stream_left		(stream_left[1:0]));
   
   initial
     begin
	$dumpfile("tb.vcd");
	$dumpvars(0, tb);
	
	@(posedge hash_done);
	$write("out %h\n", hash_out);
	
	$finish;
     end

   always @(posedge clk)
     begin
	if (jhash_core.round == 3'b101)
	  $write("%h, %h, %h\n", jhash_core.OA, jhash_core.OB, jhash_core.OC);
     end
   
endmodule // top

// Local Variables:
// verilog-library-directories:("." "../../rtl/verilog/" "../../../encode/bench/verilog/")
// verilog-library-files:("")
// verilog-library-extensions:(".v" ".h")
// End: