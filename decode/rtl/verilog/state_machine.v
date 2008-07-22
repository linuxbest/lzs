/******************************************************************************
 *
 *           File Name : state_machine.v
 *             Version : 0.1
 *                Date : Feb 20, 2008
 *         Description : implement a state machine to control decode flow 
 *        Dependencies :
 * 
 *             Company : Beijing Soul
 *              Author : Chen Tong
 * 
 *****************************************************************************/

module state_machine(/*AUTOARG*/
   // Outputs
   stream_width, stream_ack, offset, offset_valid, length,
   length_valid, length_nostream, copy_15_valid,
   decode_result, result_valid, all_end, current_state,
   // Inputs
   clk, rst, ce_decode, fo_full, stream_data, stream_valid,
   copy_ref_end
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
   input 		copy_ref_end;
   
   output [NEED_STR_WIDTH-1:0] stream_width;
   output 		       stream_ack;
   output [OFFSET_WIDTH-1:0]   offset;
   output 		       offset_valid;
   output [LENGTH_WIDTH-1:0]   length;
   output 		       length_valid;
   output 		       length_nostream;
   output 		       copy_15_valid;
   output [7:0] 	       decode_result;
   output 		       result_valid;
   output 		       all_end;
   output [2:0] 	       current_state;
   // End definition
   
   /*AUTOOUTPUT*/
   /*AUTOINPUT*/
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			copy_15_valid;
   reg [LENGTH_WIDTH-1:0] length;
   reg			length_nostream;
   reg			length_valid;
   reg [OFFSET_WIDTH-1:0] offset;
   reg			offset_valid;
   reg			stream_ack;
   reg [NEED_STR_WIDTH-1:0] stream_width;
   // End of automatics
   /*AUTOWIRE*/
   
   reg [7:0] 		       decode_result_reg, decode_result_next;
   assign 		       decode_result = copy_ref_end ? 
					       decode_result_reg : 8'hz;
   
   reg 			       result_valid_reg, result_valid_next;
   assign 		       result_valid  = copy_ref_end ? 
					       result_valid_reg : 1'hz;
   
   /* Local variable */
   reg [2:0] 		       current_state;
   reg [2:0] 		       state_next;
   reg [2:0] 		       state_pre, state_pre_next;
   reg 			       state_pre_valid;
   
   parameter [2:0] 	       
		IDLE = 3'b000,
    		START = 3'b001,
   		LENGTH_GET = 3'b010,
   		LENGTH_BIG = 3'b100,
   		WAIT = 3'b011,
		OFULL = 3'b110,
   		DONE = 3'b111;
   
   reg [LENGTH_WIDTH-1:0]      length_reg;
   reg 			       four_bit;
   reg 			       all_end;
   reg [NEED_STR_WIDTH-1:0]    stream_width_next;
   reg 			       stream_ack_next;
   reg [OFFSET_WIDTH-1:0]      offset_next;
   reg 			       offset_valid_next;
   reg [LENGTH_WIDTH-1:0]      length_next;
   reg 			       length_valid_next;
   reg 			       length_nostream_next;
   reg 			       copy_15_valid_next;
   reg 			       all_end_next;
   // End definition
   
   always @(posedge clk or posedge rst) 
     begin
	if (rst)
	  current_state <= #1 IDLE;
	else
	  current_state <= #1 state_next;
     end
   
   always @(/*AS*/ce_decode or copy_ref_end or current_state
	    or fo_full or length_reg or state_pre
	    or stream_data or stream_valid)
     begin
	
	state_next = IDLE;
	four_bit = 0;
	state_pre_valid = 0;
	decode_result_next = 0;
	result_valid_next = 0;
	stream_width_next = 0;
	stream_ack_next = 0;
	offset_next = 0;
	offset_valid_next = 0;
	length_next = 0;
	length_valid_next = 0;
	length_nostream_next = 0;
	copy_15_valid_next = 0;
	all_end_next = 0;
	state_pre_next = 0;
	
	case (current_state)
	  
	  IDLE : if (ce_decode) 
	    state_next = START;
	  
	  START : begin
	     if (stream_valid) begin
		if (stream_data[IN_WIDTH-1:IN_WIDTH-2] == 2'b11 && 
		    stream_data[IN_WIDTH-3:IN_WIDTH-9] == 0)
		  state_next = DONE;
		else if (stream_data[IN_WIDTH-1] == 0) begin 
		   decode_result_next = stream_data[IN_WIDTH-2:IN_WIDTH-9];
		   result_valid_next = 1;
		   stream_width_next = 9;
		   stream_ack_next = 1;
		   state_next = START;
		end else begin
		   stream_ack_next =1;
		   offset_valid_next = 1;
		   if (stream_data[IN_WIDTH-2] == 0) begin
		      stream_width_next = 13;
		      offset_next = stream_data[IN_WIDTH-3:IN_WIDTH-13];
		   end else begin
		      stream_width_next = 9;
		      offset_next = stream_data[IN_WIDTH-3:IN_WIDTH-9];
		   end
		   state_next =  LENGTH_GET;
		end
	     end else
	       state_next = START;
	     
	     if (fo_full) begin
		state_pre_next = state_next;
		state_pre_valid = 1;
		state_next = OFULL;
	     end
	  end
	  
	  LENGTH_GET : begin
	     if (stream_valid) 
	       if (stream_data[IN_WIDTH-1:IN_WIDTH-2] == 'b11) begin //length > 4
		  stream_width_next = 4;
		  stream_ack_next =  1;
		  if (stream_data[IN_WIDTH-3:IN_WIDTH-4] == 'b11) // ~ > 7
		    state_next = LENGTH_BIG;
		  else begin // 4 < length <= 7
		     length_next = stream_data[IN_WIDTH-3:IN_WIDTH-4] + 5;
		     length_valid_next = 1;
		     state_next = WAIT;
		  end
	       end else begin // length <= 4
		  stream_width_next = 2;
		  stream_ack_next = 1;
		  length_next = stream_data[IN_WIDTH-1:IN_WIDTH-2] + 2;
		  length_valid_next = 1;
		  state_next = WAIT;
	       end 
	     else begin
		state_next = LENGTH_GET;
		length_nostream_next = 1;
	     end
	     
	     if (fo_full) begin
		state_pre_next = state_next;
		state_pre_valid = 1;
		state_next = OFULL;
	     end
	  end
	  
	  LENGTH_BIG : begin 
	     if (stream_valid) begin
		stream_width_next = 4;
		stream_ack_next = 1;
		if (stream_data[IN_WIDTH-1:IN_WIDTH-4] == 'b1111) begin
		   state_next = LENGTH_BIG;
		   four_bit = 1;
		   copy_15_valid_next = 1;
		end else begin // result length value
		   length_next = length_reg + 
				 stream_data[IN_WIDTH-1:IN_WIDTH-4] + 8;
		   length_valid_next = 1;
		   state_next = WAIT;
		end
	     end else begin
		state_next = LENGTH_BIG;
		length_nostream_next = 1;
	     end
	     
	     if (fo_full) begin
		state_pre_next = state_next;
		state_pre_valid = 1;
		state_next = OFULL;
	     end
	  end
	  
	  WAIT : if (copy_ref_end)
	    state_next = START;
	  else
	    state_next = WAIT;
	  
	  OFULL : if (!fo_full)
	    state_next = state_pre;
	  else
	    state_next = OFULL;
	  
	  DONE : begin
	     all_end_next = 1;
	     state_next = DONE;
	  end
	  
	  default : state_next = IDLE;
	  
	endcase // case (current_state)
     end // block: commm_logic_block

   always @ (posedge clk or posedge rst)
     begin : length_reg_make
	if (rst)
	  length_reg <= #1 0;
	else if (current_state == START)
	  length_reg <= #1 0;
	else if (four_bit)
	  length_reg <= #1 length_reg + 15;
     end
   
   always @(posedge clk or posedge rst) 
     begin
	if (rst)
	  state_pre <= 0;
	else if (state_pre_valid)
	  state_pre <= #1 state_pre_next;
     end
   
   always @(posedge clk or posedge rst) 
     begin : decode_rezult_make
	if (rst)
	  decode_result_reg <= 0;
	else
	  decode_result_reg <= #1 decode_result_next;
     end
   
   always @(posedge clk or posedge rst)
     begin : rezult_valid_reg_make
	if (rst)
	  result_valid_reg <= #1 0;
	else
	  result_valid_reg <= #1 result_valid_next;
     end
   
   always @(posedge clk or posedge rst) 
     begin : register_stream_width
	if (rst)
	  stream_width <= #1 0;
	else
	  stream_width <= #1 stream_width_next;
     end
   
   always @(posedge clk or posedge rst) 
     begin
	if (rst)
	  stream_ack <= #1 0;
	else
	  stream_ack <= #1 stream_ack_next;
     end
   
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  offset <= #1 0;
	else
	  offset <= #1 offset_next;
     end

   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  offset_valid <= #1 0;
	else
	  offset_valid <= #1 offset_valid_next;
     end

   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  length <= #1 0;
	else
	  length <= #1 length_next;
     end

   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  length_valid <= #1 0;
	else
	  length_valid <= #1 length_valid_next;
     end

   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  length_nostream <= #1 0;
	else
	  length_nostream <= #1 length_nostream_next;
     end

   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  copy_15_valid <= #1 0;
	else
	  copy_15_valid <= #1 copy_15_valid_next;
     end

   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  all_end <= #1 0;
	else
	  all_end <= #1 all_end_next;
     end
   
endmodule // state_machine
