/******************************************************************************
 *
 *         File Name : decode_dp.v 
 *           Version : 0.1
 *              Date : Mar 10, 2008
 *       Description : 
 *      Dependencies :
 * 
 *           Company : Beijing Soul
 *            Author : Chen Tong
 *
 *****************************************************************************/

module decode_dp(/*AUTOARG*/
   // Outputs
   m_src_getn, m_dst, m_dst_putn, m_endn,
   // Inputs
   clk, rst, ce, fo_full, fi, m_src_empty, sbc_done, m_last
   );

   parameter IN_WIDTH = 13;
   parameter NEED_STR_WIDTH = 4;
   
   /* Local port */
   input     clk;
   input     rst;
   input     ce;
   input     fo_full;
   input [63:0] fi;
   input 	m_src_empty;
   input 	sbc_done;
   //input [19:0] fi_cnt;
   input m_last;
   
   output 	m_src_getn; 
   output [63:0] m_dst;
   output 	 m_dst_putn;
   output 	 m_endn;
   // End definition

   /*AUTOOUTPUT*/
   /*AUTOINPUT*/
   /*AUTOREG*/
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			all_end;		// From decode of decode.v
   wire			ce_decode;		// From decode_dp_in of decode_dp_in.v
   wire [2:0]		current_state;		// From decode of decode.v
   wire [7:0]		out_data;		// From decode of decode.v
   wire			out_valid;		// From decode of decode.v
   wire			stream_ack;		// From decode of decode.v
   wire [IN_WIDTH-1:0]	stream_data;		// From decode_dp_in of decode_dp_in.v
   wire			stream_valid;		// From decode_dp_in of decode_dp_in.v
   wire [NEED_STR_WIDTH-1:0] stream_width;	// From decode of decode.v
   // End of automatics
   
   /* Local variable */
   // End definition

   decode_dp_in decode_dp_in(/*AUTOINST*/
			     // Outputs
			     .m_src_getn	(m_src_getn),
			     .stream_data	(stream_data[IN_WIDTH-1:0]),
			     .stream_valid	(stream_valid),
			     .ce_decode		(ce_decode),
			     // Inputs
			     .clk		(clk),
			     .rst		(rst),
			     .ce		(ce),
			     .fi		(fi[63:0]),
			     .m_src_empty	(m_src_empty),
			     .stream_width	(stream_width[NEED_STR_WIDTH-1:0]),
			     .stream_ack	(stream_ack),
			     .current_state	(current_state[2:0]),
			     .m_last		(m_last));
 
   decode decode(/*AUTOINST*/
		 // Outputs
		 .out_data		(out_data[7:0]),
		 .out_valid		(out_valid),
		 .stream_width		(stream_width[NEED_STR_WIDTH-1:0]),
		 .stream_ack		(stream_ack),
		 .all_end		(all_end),
		 .current_state		(current_state[2:0]),
		 // Inputs
		 .clk			(clk),
		 .rst			(rst),
		 .ce_decode		(ce_decode),
		 .fo_full		(fo_full),
		 .stream_data		(stream_data[IN_WIDTH-1:0]),
		 .stream_valid		(stream_valid));

   decode_dp_out decode_dp_out(/*AUTOINST*/
			       // Outputs
			       .m_dst		(m_dst[63:0]),
			       .m_dst_putn	(m_dst_putn),
			       .m_endn		(m_endn),
			       // Inputs
			       .clk		(clk),
			       .rst		(rst),
			       .out_data	(out_data[7:0]),
			       .out_valid	(out_valid),
			       .all_end		(all_end),
			       .ce		(ce),
			       .m_src_getn	(m_src_getn),
			       .sbc_done	(sbc_done),
			       .m_src_empty	(m_src_empty));
   
endmodule // decode_dp

// Local Variables:
// verilog-library-directories:("." "../../decode/src/" "../../decode_dp_out/src/" "../../decode_dp_in/src/")
// verilog-library-extensions:(".v" ".h")
// End:
