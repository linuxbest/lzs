/******************************************************************************
 *   File Name :  jhash_in.v
 *     Version :  0.1
 *        Date :  2008 08 29
 *  Description:  jash in module
 * Dependencies:
 *
 *
 *      Company:  Beijing Soul
 *
 *          BUG:
 *
 *****************************************************************************/

module jhash_in(/*AUTOARG*/
   // Outputs
   m_src_getn, stream_data0, stream_data1, stream_data2,
   stream_valid, stream_done, stream_left,
   // Inputs
   ce, clk, fi, fo_full, m_last, rst, src_empty, stream_ack
   );
   
   input                ce;
   input                clk;
   input [63:0] 	fi;
   input                fo_full;
   input                m_last;
   input                rst;
   input                src_empty;

   output               m_src_getn;

   input 		stream_ack;
   output [31:0] 	stream_data0,
			stream_data1,
			stream_data2;
   output 		stream_valid;
   output 		stream_done;
   output [1:0] 	stream_left;

   /*AUTOREG*/
   
   reg 			pull_n;
   assign m_src_getn = ce ? ~(pull_n) : 1'bz;
   
   reg [31:0] stream_data0_n,
	      stream_data1_n,
	      stream_data2_n;
   reg [2:0]  state,
	      state_n;
   reg 	      stream_valid_n;
   parameter [2:0]
		S_IDLE    = 3'b100,
		S_RUN_01  = 3'b001,
		S_RUN_01_N= 3'b101,
		S_RUN_10  = 3'b010,
		S_RUN_10_N= 3'b110,
		S_DONE    = 3'b111;
   
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  state <= #1 S_IDLE;
	else
	  state <= #1 state_n;
     end

   reg [1:0] dstart, dstart_n;
   reg [31:0] d0, d1,
	      d0_n, d1_n;
   always @(posedge clk)
     begin
	d0 <= #1 d0_n;
	d1 <= #1 d1_n;
	dstart <= #1 dstart_n;
     end

   always @(/*AS*/ce or d0 or d1 or dstart or fi or m_last
	    or src_empty or state or stream_ack)
     begin
	state_n = state;
	pull_n  = 1'b0;
	d0_n = d0;
	d1_n = d1;
	dstart_n = dstart;
	
	case (state)
	  S_IDLE: if (~src_empty && ce) begin
	     d0_n = fi[31:00];
	     d1_n = fi[63:32];
	     pull_n  = 1'b1;
	     dstart_n= 2'b10;
	     state_n = S_RUN_10;
	  end
	  
	  S_RUN_10_N: if (m_last)
	    state_n = S_DONE;
	  else if (~src_empty) begin
	     d0_n = fi[31:00];
	     d1_n = fi[63:32];
	     pull_n  = 1'b1;
	     dstart_n= 2'b10;
	     state_n = S_RUN_10;
	  end
	  
	  S_RUN_10: if (stream_ack) begin
	     if (~src_empty && ~m_last) begin
		d0_n = fi[63:32];
		pull_n = 1'b1;
		dstart_n = 2'b01;
		state_n = S_RUN_01;
	     end else
	       state_n = S_RUN_01_N;
	  end
	  
	  S_RUN_01_N: if (m_last) 
	    state_n = S_DONE;
	  else if (~src_empty) begin
	     d0_n = fi[63:32];
	     pull_n = 1'b1;
	     dstart_n = 2'b01;
	     state_n = S_RUN_01;
	  end
	  
	  S_RUN_01: if (stream_ack) begin
	     if (~src_empty && ~m_last) begin
		state_n = S_RUN_10_N;
		pull_n = 1'b1;
	     end if (m_last) 
	       state_n = S_DONE;
	  end
	  
	  S_DONE: ;
	  
	endcase
     end // always @ (...

   assign stream_left = dstart;
   assign stream_valid= ~state[2] && ~src_empty;
   assign stream_data0= d0;
   assign stream_data1= state[1] ? d1      : fi[31:00];
   assign stream_data2= state[1] ? fi[31:0]: fi[63:32];
   
   assign stream_done = m_last;
endmodule // jhash