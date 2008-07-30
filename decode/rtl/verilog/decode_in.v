/******************************************************************************
 *
 *           File Name : decode_in.v
 *             Version : 0.1
 *                Date : Feb 20, 2008
 *         Description :
 *        Dependencies :
 * 
 *             Company : Beijing Soul
 *              Author :
 * 
 *****************************************************************************/
module decode_in (/*AUTOARG*/
   // Outputs
   m_src_getn, stream_data, stream_valid,
   // Inputs
   clk, rst, ce, fo_full, src_empty, fi, stream_width,
   stream_ack
   );
   input clk,
	 rst,
	 ce,
	 fo_full;
   
   input src_empty;
   input [63:0] fi;
   output 	m_src_getn;
   
   input [3:0] 	stream_width;
   input 	stream_ack;
   
   output [12:0] stream_data;
   output 	 stream_valid;
   
endmodule // decode_in
