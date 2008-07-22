/******************************************************************************
 * 
 *          File Name : stream.v
 *            Version : 0.1
 *               Date : Mar 26, 2008
 *        Description :    
 *       Dependencies :
 * 
 *            Company : Beijing Soul
 *             Author : 
 * 
 *****************************************************************************/

module stream(/*AUTOARG*/
   // Outputs
   busy, ce_decode, stream_data, stream_valid,
   // Inputs
   clk, rst, data, die, iidx, copy_ref_end, fo_full,
   stream_ack, stream_width
   );
   input clk, rst;
   input [15:0] data;
   input 	die;
   input [1:0] 	iidx;
   input 	copy_ref_end;
   input 	fo_full;
   output 	busy;
   output 	ce_decode;
   
   input 	stream_ack;
   input [3:0] 	stream_width;
   output [12:0] stream_data;
   output 	 stream_valid;

   /*AUTOOUTPUT*/
   /*AUTOINPUT*/
   /*AUTOWIRE*/
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			ce_decode;
   // End of automatics
   
   parameter [1:0]
		S_IDLE = 2'b00,
		S_OE   = 2'b01,
		S_WAIT = 2'b11;
   
   reg [31:0] 	 sreg, sreg_n;
   reg [1:0] 	 state, state_n;
   reg [5:0] 	 cnt, cnt_n;
`ifdef SLOW
   reg 		 busy;
`else
   wire 	 busy;
`endif
   reg 		 busy_n;
   reg 		 doe, doe_n;
   reg 		 ack_call, ack_call_n;
   reg [15:0] 	 data_call;
   reg 		 ack_ref;
   reg 		 ref_end;
   reg 		 full;
   reg 		 ack_full;
   
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  state <= #1 S_IDLE;
	else
	  state <= #1 state_n;
     end
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  full <= #1 0;
	else
	  full <= #1 fo_full;
     end
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  ack_full <= #1 0;
	else
	  ack_full <= #1 (full ^ fo_full) && full;
     end
always @(posedge clk or posedge rst)
     begin
	if (rst)
	  ref_end <= #1 0;
	else
	  ref_end <= #1 copy_ref_end;
     end
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  ack_ref <= #1 0;
	else
	  ack_ref <= #1 (ref_end ^ copy_ref_end) && copy_ref_end;
     end
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  cnt <= #1 0;
	else
	  cnt <= #1 cnt_n;
     end
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  ack_call <= #1 0;
	else
	  ack_call <= #1 ack_call_n;
     end
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  data_call <= #1 0;
	else if (ack_call || (stream_ack && iidx != 3))
	  data_call <= #1 data;
     end
`ifdef SLOW
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  busy <= #1 0;
	else
	  busy <= #1 busy_n;
     end
`else
     assign busy = busy_n;
`endif
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  doe <= #1 0;
	else
	  doe <= #1 doe_n;
     end
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  ce_decode <= #1 0;
	else if (state == S_IDLE && die)
	  ce_decode <= #1 1;
     end
   reg [15:0] code, code_n;
   
   always @(/*AS*/ack_call or cnt or data or data_call
	    or die or sreg or state or stream_ack
	    or stream_width)
     begin
	state_n = S_IDLE;
	
	cnt_n = cnt;
	busy_n = 0;
	sreg_n = sreg;

	code_n = 0;
	doe_n = 0;

	ack_call_n = 0;
	
	case (state)
	  S_IDLE: begin
	     if (die) begin
		cnt_n = cnt + 16;
		sreg_n = sreg << 16 | data;
		busy_n = 1;
		if (cnt == 16) begin
		   state_n = S_OE;
		   doe_n = 1;
		   busy_n = 1;
		end
	     end
	  end
	  
	  S_OE: begin
	     if (stream_ack || ack_call) begin
		if ((cnt - stream_width) <= 16) begin
		   sreg_n = sreg << stream_width;
		   cnt_n = cnt - stream_width;
		   busy_n = 0;
		   state_n = S_WAIT;
		end else begin
		   sreg_n = sreg << stream_width;
		   cnt_n = cnt - stream_width;
		   busy_n = 1;
		   state_n = S_OE;
		   doe_n = 1;
		end
	     end else begin// if (stream_ack || ack_call)
		state_n = S_OE;
		busy_n = 1;
	     end
	  end
	  
	  S_WAIT: if (die) begin
	     cnt_n = cnt + 16;
	     sreg_n = sreg | (data_call << (16 - cnt));
	     state_n = S_OE;
	     ack_call_n = 1;
	     busy_n = 1;
	  end else begin
	     state_n = S_WAIT;
	     busy_n = 1;
	  end
	  
	  default : state_n = S_IDLE;
	  
	endcase
     end
   
   always @(posedge clk or posedge rst)
     begin
      if (rst)
	sreg <= #1 0;
      else
	sreg <= #1 sreg_n;
     end
   
   assign     stream_data = sreg[31:19];
   assign     stream_valid = doe || ack_ref || ack_full;

endmodule // stream

