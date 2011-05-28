/************************************************************************
 *     File Name  : mod.v
 *        Version :
 *           Date : 
 *    Description : 
 *   Dependencies :
 *
 *        Company : Beijing Soul Tech.
 *
 *   Copyright (C) 2008 Beijing Soul tech.
 *
 ***********************************************************************/
module codeout (/*AUTOARG*/
   // Outputs
   m_dst, m_dst_putn, m_dst_last, m_endn,
   // Inputs
   wb_clk_i, wb_rst_i, dc, en_out_data, de_out_data,
   en_out_valid, de_out_valid, en_out_done, de_out_done,
   m_enable
   );
   input wb_clk_i, 
	 wb_rst_i;
   input [23:0] dc;
   
   input [15:0] en_out_data,  de_out_data;
   input 	en_out_valid, de_out_valid;
   input 	en_out_done,  de_out_done;

   input 	m_enable;
   
   output [63:0] m_dst;
   output 	 m_dst_putn;
   output 	 m_dst_last;
   output 	 m_endn;

   /*AUTOREG*/

   reg [15:0] 		data_i;
   reg 			valid_i, done_i;
   always @(/*AS*/dc or de_out_data or de_out_done
	    or de_out_valid or en_out_data or en_out_done
	    or en_out_valid)
     begin
	if (dc[5]) begin /* encode */
	   data_i = {en_out_data[7:0], en_out_data[15:8]};
	   valid_i= en_out_valid;
	   done_i = en_out_done;
	end else begin
	   data_i = de_out_data;
	   valid_i= de_out_valid;
	   done_i = de_out_done;
	end
     end // always @ (...

   reg [1:0] cnt;
   always @(posedge wb_clk_i or posedge wb_rst_i)
     begin
	if (wb_rst_i)
	  cnt <= #1 2'b00;
	else if (valid_i)
	  cnt <= #1 cnt + 1'b1;
     end

   reg [63:0] m_dst_r;
   always @(posedge wb_clk_i)
     begin
	if (valid_i)
	  case (cnt)
	    2'b00: m_dst_r[15:00] <= #1 data_i;
	    2'b01: m_dst_r[31:16] <= #1 data_i;
	    2'b10: m_dst_r[47:32] <= #1 data_i;
	    2'b11: m_dst_r[63:48] <= #1 data_i;
	  endcase
     end
   reg m_dst_last_r, m_dst_putn_r, m_endn_r;

   reg [1:0] done;
   always @(posedge wb_clk_i or posedge wb_rst_i)
     begin
	if (wb_rst_i)
	  done <= #1 2'b00;
	else if (done_i && done == 2'b00)
	  done <= #1 2'b01;
	else if (done == 2'b01 && m_dst_putn_r == 1'b0)
	  done <= #1 2'b11;
     end

   always @(posedge wb_clk_i or posedge wb_rst_i)
     begin
	if (wb_rst_i)
	  m_dst_last_r <= #1 1'b0;
	else if (done[0])
	  m_dst_last_r <= #1 1'b1;
     end

   always @(posedge wb_clk_i)
     begin
	if (valid_i && (&cnt))
	  m_dst_putn_r <= #1 1'b0;
	else if (done == 2'b01)
	  m_dst_putn_r <= #1 1'b0;
	else
	  m_dst_putn_r <= #1 1'b1;
     end

   always @(posedge wb_clk_i)
     if (done == 2'b11)
       m_endn_r <= #1 1'b0;
     else
       m_endn_r <= #1 1'b1;

   reg sel;
   always @(/*AS*/dc or m_enable)
     if (m_enable)
       sel = dc[5] | dc[6];
     else
       sel = 1'b0;
   
   assign m_dst      = sel ? m_dst_r      : 64'hz;
   assign m_dst_last = sel ? m_dst_last_r : 1'bz;
   assign m_dst_putn = sel ? m_dst_putn_r : 1'bz;
   assign m_endn     = sel ? m_endn_r     : 1'bz;
   
endmodule // codeout
