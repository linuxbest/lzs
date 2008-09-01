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
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [31:0]		stream_data0;
   reg [31:0]		stream_data1;
   reg [31:0]		stream_data2;
   reg			stream_done;
   // End of automatics
   
   reg 			pull_n;
   assign m_src_getn = ce ? ~(pull_n) : 1'bz;
   
   reg [31:0] stream_data0_n,
	      stream_data1_n,
	      stream_data2_n;
   reg [1:0]  state,
	      state_n;
   reg 	      stream_valid_n;
   
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  state <= #1 2'b00;
	else
	  state <= #1 state_n;
     end

   reg stream_valid_reg;
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  stream_valid_reg <= #1 1'b0;
	else
	  stream_valid_reg <= #1 stream_valid_n;
     end
   
   always @(posedge clk)
     begin
	stream_data0 <= #1 stream_data0_n;
	stream_data1 <= #1 stream_data1_n;
	stream_data2 <= #1 stream_data2_n;
     end
   
   always @(/*AS*/ce or fi or src_empty or state
	    or stream_ack or stream_data0 or stream_data1
	    or stream_data2 or stream_valid)
     begin
	state_n = state;
	pull_n  = 1'b0;
	stream_valid_n = stream_valid;
	stream_data0_n = stream_data0;
	stream_data1_n = stream_data1;
	stream_data2_n = stream_data2;
	
	case (state)
	  2'b00: if ((~src_empty && ce) | (~src_empty && stream_ack)) begin
	     stream_data0_n = fi[31:00];
	     stream_data1_n = fi[63:32];
	     pull_n  = 1'b1;
	     state_n = 2'b10;
	     stream_valid_n = 1'b0;
	  end
	  
	  2'b01: if (~src_empty) begin
	     stream_data1_n = fi[31:00];
	     stream_data2_n = fi[63:32];
	     //pull_n = 2'b1;
	     state_n = 2'b00;
	     stream_valid_n = 1'b1;
	  end
	  
	  2'b10: if (~src_empty) begin
	     stream_data2_n = fi[31:00];
	     stream_valid_n = 1'b1;
	     state_n = 2'b11;
	  end
	  
	  2'b11: if (~src_empty && stream_ack) begin
	     stream_data0_n = fi[63:32];
	     pull_n = 1'b1;
	     state_n = 2'b01;
	     stream_valid_n = 1'b0;
	  end
	endcase
     end // always @ (...

   assign stream_left = state;
   assign stream_valid= stream_valid_reg && ~src_empty;
   
   always @(posedge clk)
     stream_done <= #1 m_last;
   
endmodule // jhash