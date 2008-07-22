/******************************************************************************
 * 
 *          File Name : decode_dp_in.v
 *            Version : 0.1
 *               Date : Mar 10, 2008
 *        Description :    
 *       Dependencies :
 * 
 *            Company : Beijing Soul
 *             Author : Chen Tong
 * 
 *****************************************************************************/

module decode_dp_in(/*AUTOARG*/
   // Outputs
   m_src_getn, stream_data, stream_valid, ce_decode,
   // Inputs
   clk, rst, ce, fi, m_src_empty, stream_width, stream_ack,
   current_state, m_last
   );

   parameter NEED_STR_WIDTH = 4;
   parameter IN_WIDTH = 13;

   parameter [1:0]
		R_IDLE = 2'b00,
		R_FIRST = 2'b01,
		R_INIT = 2'b11,
		R_PROC = 2'b10;
     
   parameter [1:0] 
		W_IDLE = 2'b00,
		W_FIRST = 2'b01,
		W_PROC = 2'b11;
 
   parameter [2:0] 
		WAIT = 3'b011,
		OFULL = 3'b110;
   
   /* Local port */
   input     clk;
   input     rst;
   input     ce;
   input [63:0] fi;
   input 	m_src_empty;
   input [NEED_STR_WIDTH-1:0] stream_width;
   input 		      stream_ack;
   input [2:0] 		      current_state;
   //input [19:0] 	      fi_cnt;
   input 		      m_last;
 
   output 		      m_src_getn;
   output [IN_WIDTH-1:0]      stream_data;
   output 		      stream_valid;
   output 		      ce_decode;
   // End definition

   /*AUTOOUTPUT*/
   /*AUTOINPUT*/
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			ce_decode;
   reg			stream_valid;
   // End of automatics
   /*AUTOWIRE*/

   /* Local variables */
   reg [31:0] 		src_char;
   reg [15:0] 		in0, in1, in2, in3;
   reg [1:0] 		in_num;
   reg [5:0] 		left;
   reg [1:0] 		r_state, w_state, r_state_next, w_state_next;
   reg 			m_src_getn_reg;
   reg 			need_next;
   reg [5:0] 		left_next;
   reg [3:0] 		in_data_shift;
   reg [31:0] 		in_data;
   reg [3:0] 		stream_width_reg;
   reg 			empty, empty_end;
   reg [3:0] 		temporary;
   //reg [16:0] 		iidx;

   wire [IN_WIDTH-1:0] stream_data;
   wire [NEED_STR_WIDTH-1:0] stream_width_wire;
   //wire 		     last;
   // End definition
   
   /* read 64-bit data from PCI, split it into 8 8-bit register */
   //always @(posedge clk or posedge rst)
     //begin
	//if (rst)
	  //iidx <= #1 0;
	//else if (!m_src_getn && ce)
	  //iidx <= #1 iidx + 1;
     //end

   //assign last = (iidx == fi_cnt[19:3]);
   
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  r_state <= #1 R_IDLE;
	else
	  r_state <= #1 r_state_next;
     end

   always @(/*AS*/ce or in_num or m_last or m_src_empty
	    or need_next or r_state)
     begin
	r_state_next = R_IDLE;
	case (r_state)
	  
	  R_IDLE : if (ce && !m_src_empty)
	    r_state_next = R_FIRST;
	  
	  R_FIRST : r_state_next = R_INIT;
	  
	  R_INIT : r_state_next = R_PROC;
	  
	  R_PROC : if (in_num == 3 && (!m_src_empty || m_last) && need_next)
	    r_state_next = R_INIT;
	  else
	    r_state_next = R_PROC;
	  
	  default : r_state_next = R_IDLE;
	  
	endcase
     end // always @ (...
   
   always @(posedge clk or posedge rst)
     begin
	if (rst) begin
	   m_src_getn_reg <= #1 1;
	   in_num <= #1 0;
	   in0 <= #1 0;
	   in1 <= #1 0;
	   in2 <= #1 0;
	   in3 <= #1 0;
	end else begin
	   m_src_getn_reg <= #1 1;
	   case (r_state)
	     
	     R_FIRST : begin
		in0 <= #1 {fi[07:00], fi[15:08]};
		in1 <= #1 {fi[23:16], fi[31:24]};
		in2 <= #1 {fi[39:32], fi[47:40]};
		in3 <= #1 {fi[55:48], fi[63:56]};
		in_num <= #1 2;
	     end
	     
	     R_INIT : begin
		in0 <= #1 {fi[07:00], fi[15:08]};
		in1 <= #1 {fi[23:16], fi[31:24]};
		in2 <= #1 {fi[39:32], fi[47:40]};
		in3 <= #1 {fi[55:48], fi[63:56]};
	     end // case: R_INIT
	     
	     R_PROC : begin
		if (need_next && (!m_src_empty || m_last))
		  in_num <= #1 in_num + 1;
		
		if (in_num == 2 && (!m_src_empty || m_last) && need_next) // must ***
		  m_src_getn_reg <= #1 0;
	     end
	     
	   endcase // case (r_state)
	end // else: !if(rst)
     end // block: state_machine_to_read

   reg [15:0] in_data_wire;
   always @(/*AS*/in0 or in1 or in2 or in3 or in_num)
     begin
	in_data_wire = 16'h0;
	case (in_num)
	  2'b00: in_data_wire = in0;
	  2'b01: in_data_wire = in1;
	  2'b10: in_data_wire = in2;
	  2'b11: in_data_wire = in3;
	endcase
     end
   // End of read
   
   /* Make continue data stream */
   always @(/*AS*/left_next)
     begin
	if (left_next > 16)
	  need_next = 0;
	else
	  need_next = 1;
     end
   
   assign stream_width_wire = empty_end ? stream_width_reg : stream_width;
   
   always @(/*AS*/empty_end or left or stream_ack
	    or stream_width_wire)
     begin
	if (stream_ack || empty_end)
	  left_next = left - stream_width_wire;
	else
	  left_next = left;
     end
   
   always @(/*AS*/empty_end or need_next or stream_ack
	    or stream_width_wire or temporary)
     begin
	if ((stream_ack || empty_end) && need_next)
	  in_data_shift = temporary + stream_width_wire;
	else
	  in_data_shift = 0;
     end
   
   always @(/*AS*/empty_end or in_data_shift or in_data_wire
	    or need_next or stream_ack)
     begin
	if ((stream_ack || empty_end) && need_next)
	  in_data = in_data_wire << in_data_shift;
	else
	  in_data = 32'b0;
     end
   
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  w_state <= #1 W_IDLE;
	else
	  w_state <= #1 w_state_next;
     end

   always @(/*AS*/m_src_empty or w_state)
     begin
	w_state_next = W_IDLE;
	case (w_state)
	  
	  W_IDLE : if (!m_src_empty)
	    w_state_next = W_FIRST;

	  W_FIRST : w_state_next = W_PROC;
	  
	  W_PROC : w_state_next = W_PROC;
	  
	  default : w_state_next = W_IDLE;
	  
	endcase
     end
   
   always @(posedge clk or posedge rst)
     begin
	if (rst) begin
	   src_char <= #1 0;
	   left <= #1 0;
	   temporary <= #1 0;
	   ce_decode <= #1 0;
	   stream_valid <= #1 0;
	end else begin
	   case (w_state)
	     
	     W_IDLE : if (!m_src_empty)
	       ce_decode <= #1 1;
	     
	     W_FIRST :begin
		src_char <= #1 {fi[7:0], fi[15:8], fi[23:16], fi[31:24]};
		stream_valid <= #1 1;
		left <= #1 32;
	     end

	     W_PROC : if (!m_src_empty || m_last)
	       if (stream_ack || empty_end) begin
		  stream_valid <= #1 1;
		  temporary <= #1 16 - left_next;
		  if (!need_next) begin
		     src_char <= #1 src_char << stream_width_wire;
		     left <= #1 left_next;
		  end else begin
		     src_char <= #1 (src_char << stream_width_wire) | in_data;
		     left <= #1 left_next + 16;
		  end
	       end else if (current_state == OFULL || current_state == WAIT)
		 stream_valid <= #1 stream_valid;
	       else
		 stream_valid <= #1 0;
	     else begin
		stream_valid <= #1 0;
	     end
	     
	   endcase // case (w_state_next)
	end // else: !if(rst)
     end // always @ (posedge clk or posedge rst)

   always @(posedge clk or posedge rst)
     begin //register stream_width when m_src_empty
	if (rst)
	  stream_width_reg <= #1 0;
	else if (stream_ack && m_src_empty)
	  stream_width_reg <= #1 stream_width;
	else if (empty_end)
	  stream_width_reg <= #1 0;
     end
   
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  empty <= #1 0;
	else
	  empty <= #1 m_src_empty;
     end
   
   always @(posedge clk or posedge rst)
     begin // empty_end instead of stream_valid when m_src_empty from 1 -> 0
	if (rst)
	  empty_end <= #1 0;
	else
	  empty_end <= #1 (empty ^ m_src_empty) && empty;
     end
   
   assign stream_data = src_char[31:32-IN_WIDTH];
   
   assign m_src_getn = ce ? m_src_getn_reg : 'bz;
   
endmodule // decode_dp_in
