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
   stream_width, stream_ack, out_data, out_valid, out_done,
   // Inputs
   clk, rst, ce, fo_full, stream_data, stream_valid
   );
   input clk,
	 rst,
	 ce,
	 fo_full;
   
   input [12:0] stream_data;
   input 	stream_valid;
   
   output [3:0] stream_width;
   output 	stream_ack;
   
   output [7:0] out_data;
   output 	out_valid;
   output 	out_done;

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
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
		S_COPY = 3'h6,
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
   reg [3:0] cnt, cnt_n;
   reg cnt_load, cnt_dec;
   reg [10:0] off, off_n;
   reg 	      off_load, off_load_n;
   reg 	      out_valid_n;
   reg [7:0]  out_data_n;
   
   always @(/*AS*/ce or cnt or fo_full or state
	    or stream_data or stream_valid)
     begin
	stream_width = 4'h0;
	stream_ack   = 1'b0;
	
	state_n = state;

	cnt_load = 1'b0;
	cnt_n    = cnt;
	cnt_dec  = 1'b0;

	off_n = 11'h0;
	off_load_n = 1'b0;

	out_data_n = 8'h0;
	out_valid_n = 1'b0;
	
	case (state)
	  S_IDLE: begin
	     if (ce)
	       state_n = S_PROC;
	  end
	  
	  S_PROC: begin
	     if (stream_valid) begin
		if (stream_data[12:4] == 9'b110000000) begin /* END */
		   state_n = S_END;
		end else if (~stream_data[12]) begin         /* uncompress*/
		   stream_width = 4'h9;
		   stream_ack   = 1'b1;
		   out_valid_n = 1'b1;
		   out_data_n = stream_data[11:4];
		end else begin                   /* offset and first len */
		   if (~stream_data[11]) begin
		      stream_width = 4'hd;       /* 11 + 2 */
		      off_n = stream_data[10:0];
		   end else begin
		      stream_width = 4'h9;       /* 7 + 2 */
		      off_n = stream_data[10:4];
		   end
		   off_load_n = 1'b1;
		   stream_ack = 1'b1;
		   state_n = S_LEN1;
		end // else: !if(~stream_data[12])
	     end // if (stream_valid)
	  end // case: S_PROC

	  S_LEN1:   begin
	     if (stream_valid) begin
		stream_width = 4'h2;
		stream_ack   = 1'b1;
		cnt_load     = 1'b1;
		state_n      = S_WAIT;
		case (stream_data[12:11])
		  2'b00: cnt_n = 4'b0010; /* 2 */
		  2'b01: cnt_n = 4'b0011; /* 3 */
		  2'b10: cnt_n = 4'b0100; /* 4 */
		  2'b11: begin 
		     cnt_load = 1'b0;
		     state_n = S_LEN2;
		  end
		endcase
	     end
	  end // case: S_LEN
	  
	  S_LEN2:   begin
	     if (stream_valid) begin
		stream_width = 4'h2;
		stream_ack   = 1'b1;
		cnt_load     = 1'b1;
		state_n      = S_WAIT;
		case (stream_data[12:11])
		  2'b00: cnt_n = 4'b0101; /* 5 */
		  2'b01: cnt_n = 4'b0110; /* 6 */
		  2'b10: cnt_n = 4'b0111; /* 7 */
		  2'b11: begin
		     cnt_n = 4'b1000;
		     state_n = S_COPY;
		  end
		endcase
	     end
	  end

	  S_COPY: begin
	     if (|cnt && ~fo_full) begin
		cnt_dec = 1'b1;
	     end else begin
		state_n = S_LEN3;
	     end
	  end
	  
	  S_LEN3: begin
	     if (stream_valid) begin
		stream_width = 4'h4;
		stream_ack   = 1'b1;
		cnt_load = 1'b1;
		cnt_n = stream_data[12:09];
		if (stream_data[12:09] == 4'b1111) begin
		   state_n = S_COPY;
		end else begin
		   state_n = S_WAIT;
		end
	     end
	  end // case: S_LEN3
	  
	  S_WAIT: begin
	     if (|cnt && ~fo_full) begin
		cnt_dec = 1'b1;
	     end else begin
		state_n = S_PROC;
	     end
	  end
	  
	endcase
     end // always @ (...

   /* out data and valid signal */
   reg [7:0] out_data_r;
   reg 	     out_valid_r;
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  out_valid_r <= #1 1'b0;
	else 
	  out_valid_r <= #1 out_valid_n;
     end
   always @(posedge clk)
     out_data_r  <= #1 out_data_n;
   
   reg [10:0] waddr, raddr;
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  waddr <= #1 11'h0;
	else if (out_valid)
	  waddr <= #1 waddr + 1'b1;
     end

   wire [7:0] hdata;
   reg [10:0] hmem_raddr;
   reg [7:0]  hmem [2047:0];
   always @(posedge clk) begin
      if (out_valid)
	hmem[waddr] <= #1 out_data;
      hmem_raddr <= #1 raddr;
   end
   assign hdata = hmem[hmem_raddr];
   
   reg 	    hwe;
   always @(posedge clk)
     hwe <= #1 cnt_dec;
   
   always @(posedge clk)
     begin
	if (cnt_load)
	  cnt <= #1 cnt_n;
	else if (cnt_dec)
	  cnt <= #1 cnt - 1'b1;
     end

   always @(posedge clk)
     begin
	off <= #1 off_n;
	off_load <= #1 off_load_n;
     end
   
   always @(posedge clk)
     begin
	if (off_load)
	  raddr <= #1 waddr - off;
	else if (cnt_dec)
	  raddr <= #1 raddr + 1'b1;
     end

   assign out_done  = state == S_END;
   assign out_data  = out_valid_r ? out_data_r : hdata;
   assign out_valid = out_valid_r | hwe;
   
endmodule // decode_ctl
