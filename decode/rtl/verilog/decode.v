/******************************************************************************
 *
 *           File Name : decode.v
 *             Version : 0.1
 *                Date : Feb 20, 2008
 *         Description : LZS decode algorithm top module 
 *        Dependencies :
 * 
 *             Company : Beijing Soul
 *              Author : Hu Gang
 * 
 *****************************************************************************/

module decode(/*AUTOARG*/
   // Outputs
   valid_o, m_src_getn, done_o, data_o,
   // Inputs
   src_empty, rst, m_last, fo_full, fi, clk, ce
   );
   
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output [15:0]	data_o;			// From decode_out of decode_out.v
   output		done_o;			// From decode_out of decode_out.v
   output		m_src_getn;		// From decode_in of decode_in.v
   output		valid_o;		// From decode_out of decode_out.v
   // End of automatics
   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input		ce;			// To decode_in of decode_in.v, ...
   input		clk;			// To decode_in of decode_in.v, ...
   input [63:0]		fi;			// To decode_in of decode_in.v
   input		fo_full;		// To decode_in of decode_in.v, ...
   input		m_last;			// To decode_in of decode_in.v
   input		rst;			// To decode_in of decode_in.v, ...
   input		src_empty;		// To decode_in of decode_in.v
   // End of automatics
   /*AUTOREG*/
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [7:0]		out_data;		// From decode_ctl of decode_ctl.v
   wire			out_done;		// From decode_ctl of decode_ctl.v
   wire			out_valid;		// From decode_ctl of decode_ctl.v
   wire			stream_ack;		// From decode_ctl of decode_ctl.v
   wire [12:0]		stream_data;		// From decode_in of decode_in.v
   wire			stream_done;		// From decode_in of decode_in.v
   wire			stream_valid;		// From decode_in of decode_in.v
   wire [3:0]		stream_width;		// From decode_ctl of decode_ctl.v
   // End of automatics
   
   /* Local variable */
   // End definition
   
   decode_in  decode_in (/*AUTOINST*/
			 // Outputs
			 .m_src_getn		(m_src_getn),
			 .stream_data		(stream_data[12:0]),
			 .stream_valid		(stream_valid),
			 .stream_done		(stream_done),
			 // Inputs
			 .clk			(clk),
			 .rst			(rst),
			 .ce			(ce),
			 .m_last		(m_last),
			 .fo_full		(fo_full),
			 .src_empty		(src_empty),
			 .fi			(fi[63:0]),
			 .stream_width		(stream_width[3:0]),
			 .stream_ack		(stream_ack));
   decode_ctl decode_ctl (/*AUTOINST*/
			  // Outputs
			  .stream_width		(stream_width[3:0]),
			  .stream_ack		(stream_ack),
			  .out_data		(out_data[7:0]),
			  .out_valid		(out_valid),
			  .out_done		(out_done),
			  // Inputs
			  .clk			(clk),
			  .rst			(rst),
			  .ce			(ce),
			  .fo_full		(fo_full),
			  .stream_data		(stream_data[12:0]),
			  .stream_valid		(stream_valid),
			  .stream_done		(stream_done));

   decode_out decode_out (/*AUTOINST*/
			  // Outputs
			  .data_o		(data_o[15:0]),
			  .valid_o		(valid_o),
			  .done_o		(done_o),
			  // Inputs
			  .clk			(clk),
			  .rst			(rst),
			  .out_valid		(out_valid),
			  .out_done		(out_done),
			  .out_data		(out_data[7:0]));
   
endmodule // decode

// Local Variables:
// verilog-library-directories:("."  "../../state_machine/src/" "../../copy_ref/src/" "../../output_token/src/" "../../history_ram/src/")
// verilog-library-extensions:(".v" ".h")
// End:
