/******************************************************************************
 *   File Name :  jhash.v
 *     Version :  0.1
 *        Date :  2008 08 29
 *  Description:  jash module
 * Dependencies:
 *
 *
 *      Company:  Beijing Soul
 *
 *          BUG:
 *
 *****************************************************************************/

module jhash(/*AUTOARG*/
   // Outputs
   m_src_getn, hash_out, hash_done,
   // Inputs
   src_empty, rst, m_last, fo_full, fi, clk, ce
   );

   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input		ce;			// To jhash_in of jhash_in.v
   input		clk;			// To jhash_in of jhash_in.v, ...
   input [63:0]		fi;			// To jhash_in of jhash_in.v
   input		fo_full;		// To jhash_in of jhash_in.v
   input		m_last;			// To jhash_in of jhash_in.v
   input		rst;			// To jhash_in of jhash_in.v, ...
   input		src_empty;		// To jhash_in of jhash_in.v
   // End of automatics
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output		hash_done;		// From jhash_core of jhash_core.v
   output [31:0]	hash_out;		// From jhash_core of jhash_core.v
   output		m_src_getn;		// From jhash_in of jhash_in.v
   // End of automatics
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			stream_ack;		// From jhash_core of jhash_core.v
   wire [31:0]		stream_data0;		// From jhash_in of jhash_in.v
   wire [31:0]		stream_data1;		// From jhash_in of jhash_in.v
   wire [31:0]		stream_data2;		// From jhash_in of jhash_in.v
   wire			stream_done;		// From jhash_in of jhash_in.v
   wire [1:0]		stream_left;		// From jhash_in of jhash_in.v
   wire			stream_valid;		// From jhash_in of jhash_in.v
   // End of automatics
   
   jhash_in   jhash_in  (/*AUTOINST*/
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
   jhash_core jhash_core(/*AUTOINST*/
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
   
endmodule