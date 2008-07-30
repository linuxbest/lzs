/******************************************************************************
 *
 *           File Name : decode_ctl.v
 *             Version : 0.1
 *                Date : Feb 20, 2008
 *         Description :
 *        Dependencies :
 * 
 *             Company : Beijing Soul
 *              Author :
 * 
 *****************************************************************************/
module decode_ctl (/*AUTOARG*/
   // Outputs
   stream_width, stream_ack, out_data, out_valid, all_end,
   // Inputs
   clk, rst, ce_decode, fo_full, stream_data, stream_valid
   );
   input clk,
	 rst,
	 ce_decode,
	 fo_full;
   
   input [12:0] stream_data;
   input 	stream_valid;
   
   output [3:0] stream_width;
   output 	stream_ack;
   
   output [7:0] out_data;
   output 	out_valid;
   output 	all_end;

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			all_end;
   reg [7:0]		out_data;
   reg			out_valid;
   reg			stream_ack;
   reg [3:0]		stream_width;
   // End of automatics
   
   parameter [2:0]
		S_IDLE = 3'h0,
		S_PROC = 3'h1,
		S_LEN1 = 3'h2,
		S_LEN2 = 3'h3,
		S_LEN3 = 3'h4,
		S_WAIT = 3'h5,
		S_END  = 3'h7;
   reg [2:0]
	    state, state_n;

   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  state <= #1 S_IDLE;
	else
	  state <= #1 state_n;
     end

   reg [10:0] offset_n, offset;
   reg [3:0]  cnt_n, cnt;
   reg [7:0]  out_data_n;
   reg 	      out_valid_n;
   always @(posedge clk)
     begin
	out_data  <= #1 out_data_n;
	out_valid <= #1 out_valid_n;
     end
	     
   always @(/*AS*/ce_decode or state or stream_data
	    or stream_valid)
     begin
	stream_width = 4'h0;
	stream_ack   = 1'b0;
	
	state_n = state;

	out_valid_n = 1'b0;
	
	case (state)
	  S_IDLE: begin
	     if (ce_decode)
	       state_n = S_PROC;
	  end
	  
	  S_PROC: begin
	     if (stream_valid) begin
		if (stream_data[12:4] == 9'b110000000) begin /* END */
		   state_n = S_END;
		end else if (~stream_data[12]) begin      /* uncompress data */
		   stream_width = 4'h9;
		   stream_ack   = 1'b1;
		   
		   out_data_n  = stream_data[11:4];
		   out_valid_n = 1'b1;
		end else begin                   /* offset and first len */
		   if (~stream_data[11]) begin
		      stream_width = 4'hd;       /* 11 + 2 */
		      offset_n     = stream_data[10:0];
		   end else begin
		      stream_width = 4'h9;       /* 7 + 2 */
		      offset_n     = stream_data[10:4];
		   end
		   stream_ack   = 1'b1;
		   cnt_n = stream_data[12:09];
		   state_n = S_LEN1;
		end // else: !if(~stream_data[12])
	     end // if (stream_valid)
	  end // case: S_PROC

	  S_LEN1:   begin
	     if (stream_valid) begin
		cnt_n = stream_data[12:09];
		stream_width = 4'h2;
		stream_ack   = 1'b1;
		if (stream_data[12:11] == 2'b11) begin
		   state_n = S_LEN2;
		end else begin
		   state_n = S_WAIT;
		end
	     end
	  end // case: S_LEN
	  
	  S_LEN2:   begin
	     if (stream_valid) begin
		cnt_n = stream_data[12:09];
		stream_width = 4'h2;
		stream_ack   = 1'b1;
		if (stream_data[12:11] == 2'b11) begin
		   state_n = S_LEN3;
		end else begin
		   state_n = S_WAIT;
		end
	     end
	  end

	  S_LEN3: begin
	     if (stream_valid) begin
		cnt_n = stream_data[12:09];
		stream_width = 4'h4;
		stream_ack   = 1'b1;
		if (stream_data[12:09] == 4'b1111) begin
		   state_n = S_LEN3;
		end else begin
		   state_n = S_WAIT;
		end
	     end
	  end // case: S_LEN3
	  
	  S_WAIT: begin
	     state_n = S_PROC;
	  end
	  
	endcase
     end
endmodule // decode_ctl
