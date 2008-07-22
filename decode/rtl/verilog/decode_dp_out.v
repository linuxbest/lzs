/******************************************************************************
 *
 *         File Name : decode_dp_out.v 
 *           Version : 0.1
 *              Date : Mar 10, 2008  
 *       Description : 
 *      Dependencies :
 * 
 *           Company : Beijing Soul
 *            Author : Chen Tong
 * 
 *****************************************************************************/

module decode_dp_out(/*AUTOARG*/
   // Outputs
   m_dst, m_dst_putn, m_endn,
   // Inputs
   clk, rst, out_data, out_valid, all_end, ce, m_src_getn,
   sbc_done, m_src_empty
   );

   /* Local port */
   input clk;
   input rst;
   input [7:0] out_data;
   input       out_valid;
   input       all_end;
   input       ce;
   input       m_src_getn;
   input       sbc_done;
   input       m_src_empty;
   
   output [63:0] m_dst;
   output 	 m_dst_putn;
   output 	 m_endn;
   // End definition

   /*AUTOOUTPUT*/
   /*AUTOINPUT*/
   /*AUTOREG*/
   /*AUTOWIRE*/
   
   /* Local variable */
   wire [63:0] 	 dout_out;
   wire 	 dout_en_out;
   
   reg [63:0] 	 dout_out_next;
   reg [2:0] 	 position;
   reg 		 position_valid;
   reg [63:0] 	 dout_out_reg;
   reg 		 dout_en_out_reg;
   reg 		 dout_done_reg;
   reg 		 last_data;
   reg 		 last_output;
   // End definition

   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  position <= #1 0;
	else if (out_valid)
	  position <= #1 position + 1;
     end

   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  position_valid <= #1 0;
	else if (out_valid)
	  position_valid <= #1 1;
	else //if (dout_done)
	  position_valid <= #1 0;
     end
   
   always @(posedge clk or posedge rst)
     begin
	if (rst) begin
	   dout_out_reg <= #1 0;
	   dout_en_out_reg <= #1 1;
	//end else if (all_end && position != 0) begin
	   //dout_out_reg <= #1 dout_out_next;
	   //dout_en_out_reg <= #1 0;
	end else if (all_end && position != 0) begin
	   dout_out_reg <= #1 dout_out_next;
	   dout_en_out_reg <= #1 0;
	end else if (sbc_done && m_src_empty 
		     && !m_src_getn && position != 0) begin
	   dout_out_reg <= #1 dout_out_next;
	   dout_en_out_reg <= #1 0;
	end else if (position == 0 && position_valid) begin
	   dout_out_reg <= #1 dout_out_next;
	   dout_en_out_reg <= #1 0;
	end else begin
	   dout_out_reg <= #1 0;
	   dout_en_out_reg <= #1 1;
	end
     end
   
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  dout_out_next <= #1 0;
	else if (out_valid)
	  case (position)
	    0 : begin 
	       dout_out_next[07:00] <= #1 out_data;
	       dout_out_next[63:08] <= #1 {56{'b1}};
	    end
	    1 : dout_out_next[15:08] <= #1 out_data;
	    2 : dout_out_next[23:16] <= #1 out_data;
	    3 : dout_out_next[31:24] <= #1 out_data;
	    4 : dout_out_next[39:32] <= #1 out_data;
	    5 : dout_out_next[47:40] <= #1 out_data;
	    6 : dout_out_next[55:48] <= #1 out_data;
	    7 : dout_out_next[63:56] <= #1 out_data;
	  endcase
     end
   
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  last_data <= #1 0;
	else if (all_end)
	  last_data <= #1 1;
	else if (sbc_done && m_src_empty && !m_src_getn)
	  last_data <= #1 1;
     end
   
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  last_output <= #1 0;
	else if (last_data)
	  last_output <= #1 1;
     end
   
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  dout_done_reg <= #1 1;
	else if (last_output)
	  dout_done_reg <= #1 0;
	//else if (all_end)
	  //dout_done_reg <= #1 0;
	//else if (sbc_done && m_src_empty && !m_src_getn)
	  //dout_done_reg <= #1 0;
     end
   
   assign 	 m_dst = ce ? dout_out_reg : 64'bz;
   assign 	 m_dst_putn = ce ? dout_en_out_reg : 1'bz;
   assign 	 m_endn = ce ? dout_done_reg : 1'bz;
   
endmodule // decode_dp_out
