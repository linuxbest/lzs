/******************************************************************************
 *
 *           File Name : decode.v
 *             Version : 0.1
 *                Date : Feb 20, 2008
 *         Description : LZS decode algorithm top module 
 *        Dependencies :
 * 
 *             Company : Beijing Soul
 *              Author : Chen Tong
 * 
 *****************************************************************************/

module decode(/*AUTOARG*/
   // Outputs
   out_data, out_valid, stream_width, stream_ack, all_end,
   current_state,
   // Inputs
   clk, rst, ce_decode, fo_full, stream_data, stream_valid
   );
   
   parameter IN_WIDTH = 13;
   parameter LENGTH_WIDTH = 16;
   parameter OFFSET_WIDTH = 12;
   parameter NEED_STR_WIDTH = 4;
   
   /* Local port */
   input     clk;
   input     rst;
   input     ce_decode;
   input     fo_full;
   input [IN_WIDTH-1:0] stream_data;
   input 		stream_valid;
   
   output [7:0] 	out_data;
   output 		out_valid;
   output [NEED_STR_WIDTH-1:0] stream_width;
   output 		       stream_ack;
   output 		       all_end;
   output [2:0] 	       current_state;
   // End definition
   
   /*AUTOOUTPUT*/
   /*AUTOINPUT*/
   /*AUTOREG*/
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			copy_15_valid;		// From state of state_machine.v
   wire			copy_ref_end;		// From copy of copy_ref.v
   wire [7:0]		decode_result;		// From state of state_machine.v, ...
   wire [LENGTH_WIDTH-1:0] length;		// From state of state_machine.v
   wire			length_nostream;	// From state of state_machine.v
   wire			length_valid;		// From state of state_machine.v
   wire [OFFSET_WIDTH-1:0] offset;		// From state of state_machine.v
   wire			offset_valid;		// From state of state_machine.v
   wire [10:0]		read_address;		// From copy of copy_ref.v
   wire [7:0]		read_data;		// From history of history_ram.v
   wire			result_valid;		// From state of state_machine.v, ...
   wire [10:0]		write_address;		// From out_token of output_token.v
   wire [7:0]		write_data;		// From out_token of output_token.v
   wire			write_valid;		// From out_token of output_token.v
   // End of automatics
   
   /* Local variable */
   // End definition
   
   state_machine state(/*AUTOINST*/
		       // Outputs
		       .stream_width	(stream_width[NEED_STR_WIDTH-1:0]),
		       .stream_ack	(stream_ack),
		       .offset		(offset[OFFSET_WIDTH-1:0]),
		       .offset_valid	(offset_valid),
		       .length		(length[LENGTH_WIDTH-1:0]),
		       .length_valid	(length_valid),
		       .length_nostream	(length_nostream),
		       .copy_15_valid	(copy_15_valid),
		       .decode_result	(decode_result[7:0]),
		       .result_valid	(result_valid),
		       .all_end		(all_end),
		       .current_state	(current_state[2:0]),
		       // Inputs
		       .clk		(clk),
		       .rst		(rst),
		       .ce_decode	(ce_decode),
		       .fo_full		(fo_full),
		       .stream_data	(stream_data[IN_WIDTH-1:0]),
		       .stream_valid	(stream_valid),
		       .copy_ref_end	(copy_ref_end));
   
   copy_ref copy(/*AUTOINST*/
		 // Outputs
		 .decode_result		(decode_result[7:0]),
		 .result_valid		(result_valid),
		 .read_address		(read_address[10:0]),
		 .copy_ref_end		(copy_ref_end),
		 // Inputs
		 .clk			(clk),
		 .rst			(rst),
		 .current_state		(current_state[2:0]),
		 .offset		(offset[OFFSET_WIDTH-1:0]),
		 .offset_valid		(offset_valid),
		 .write_address		(write_address[10:0]),
		 .length		(length[LENGTH_WIDTH-1:0]),
		 .length_valid		(length_valid),
		 .length_nostream	(length_nostream),
		 .copy_15_valid		(copy_15_valid),
		 .read_data		(read_data[7:0]),
		 .fo_full		(fo_full),
		 .all_end		(all_end));
   
   output_token out_token(/*AUTOINST*/
			  // Outputs
			  .out_data		(out_data[7:0]),
			  .out_valid		(out_valid),
			  .write_address	(write_address[10:0]),
			  .write_data		(write_data[7:0]),
			  .write_valid		(write_valid),
			  // Inputs
			  .clk			(clk),
			  .rst			(rst),
			  .decode_result	(decode_result[7:0]),
			  .result_valid		(result_valid));
   
   history_ram history(/*AUTOINST*/
		       // Outputs
		       .read_data	(read_data[7:0]),
		       // Inputs
		       .clk		(clk),
		       .read_address	(read_address[10:0]),
		       .write_address	(write_address[10:0]),
		       .write_data	(write_data[7:0]),
		       .write_valid	(write_valid));
   
endmodule // decode

// Local Variables:
// verilog-library-directories:("."  "../../state_machine/src/" "../../copy_ref/src/" "../../output_token/src/" "../../history_ram/src/")
// verilog-library-extensions:(".v" ".h")
// End:
