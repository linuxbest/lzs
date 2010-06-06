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

module mod(/*AUTOARG*/
   // Outputs
   m_src_getn, m_dst_putn, m_dst, m_dst_last, m_endn, m_cap,
   en_out_data, en_out_done, en_out_valid, cnt_finish, data_empty,
   data_valid, encode_ctl_state, encode_dp_state, encode_out_state,
   de_out_data, de_out_done, de_out_valid, decode_ctl_state,
   decode_stream_done, decode_out_done,
   // Inputs
   wb_clk_i, m_reset, m_enable, dc, m_src, m_src_last,
   m_src_almost_empty, m_src_empty, m_dst_almost_full, m_dst_full
   );
   input wb_clk_i;
   input m_reset;
   input m_enable;
   
   wire  wb_rst_i = m_reset;
   
   input [23:0] dc;   
   output 	m_src_getn;
   input [63:0] m_src;
   input 	m_src_last;
   input 	m_src_almost_empty;
   input 	m_src_empty;
   
   output 	m_dst_putn;
   output [63:0] m_dst;
   output 	 m_dst_last;
   input 	 m_dst_almost_full;
   input 	 m_dst_full;

   output 	 m_endn;

   output [7:0]  m_cap;
   
   //debug signal
   output 	en_out_data;
   output 	en_out_done;
   output 	en_out_valid;
   output 	cnt_finish;
   output 	data_empty;
   output 	data_valid;
   output [2:0]	encode_ctl_state;
   output [2:0]	encode_dp_state;
   output [2:0]	encode_out_state;

   output	de_out_data; 
   output 	de_out_done;
   output 	de_out_valid;
   output [2:0]	decode_ctl_state;
   output 	decode_stream_done;
   output 	decode_out_done;

   // synopsys translate_off
   pullup(m_dst_putn);
   pullup(m_src_getn);
   pullup(m_endn);
   // synopsys translate_on
   
   wire 	 fo_full   = m_dst_full  || m_dst_almost_full;
   wire 	 src_empty = m_src_empty || m_src_almost_empty;

   wire [15:0] 	 en_out_data,  de_out_data;
   wire 	 en_out_valid, de_out_valid;
   wire 	 en_out_done,  de_out_done;
   
   encode encode(.ce(dc[5] && m_enable),
		 .fi(m_src),
		 .clk(wb_clk_i),
		 .rst(wb_rst_i),
		 .data_o(en_out_data),
		 .done_o(en_out_done),
		 .valid_o(en_out_valid),
		 .m_last(m_src_last),
		 /*AUTOINST*/
		 // Outputs
		 .encode_ctl_state	(encode_ctl_state[2:0]),
		 .encode_dp_state	(encode_dp_state[2:0]),
		 .encode_out_state	(encode_out_state[2:0]),
		 .m_src_getn		(m_src_getn),
		 .cnt_finish		(cnt_finish),
		 .data_empty		(data_empty),
		 .data_valid		(data_valid),
		 // Inputs
		 .fo_full		(fo_full),
		 .src_empty		(src_empty));
   
   decode decode(.ce(dc[6] && m_enable),
		 .fi(m_src),
		 .clk(wb_clk_i),
		 .rst(wb_rst_i),
		 .data_o(de_out_data),
		 .done_o(de_out_done),
		 .valid_o(de_out_valid),
		 .m_last(m_src_last),
		 /*AUTOINST*/
		 // Outputs
		 .decode_ctl_state	(decode_ctl_state),
		 .m_src_getn		(m_src_getn),
		 .decode_stream_done	(decode_stream_done),
		 .decode_out_done	(decode_out_done),
		 // Inputs
		 .fo_full		(fo_full),
		 .src_empty		(src_empty));

   codeout codeout (/*AUTOINST*/
		    // Outputs
		    .m_dst		(m_dst[63:0]),
		    .m_dst_putn		(m_dst_putn),
		    .m_dst_last		(m_dst_last),
		    .m_endn		(m_endn),
		    // Inputs
		    .wb_clk_i		(wb_clk_i),
		    .wb_rst_i		(wb_rst_i),
		    .dc			(dc[23:0]),
		    .en_out_data	(en_out_data[15:0]),
		    .de_out_data	(de_out_data[15:0]),
		    .en_out_valid	(en_out_valid),
		    .de_out_valid	(de_out_valid),
		    .en_out_done	(en_out_done),
		    .de_out_done	(de_out_done),
		    .m_enable		(m_enable));

   assign 	 m_cap = {1'b1,  /* decode */
			  1'b1,  /* encode */
			  1'b0,  /* memcpy */
			  1'b0, 
			  1'b0, 
			  1'b0, 
			  1'b0};
   
endmodule // mod

// Local Variables:
// verilog-library-directories:("." "/p/hw/lzs/encode/rtl/verilog" "/p/hw/lzs/decode/rtl/verilog/")
// verilog-library-files:("/some/path/technology.v" "/some/path/tech2.v")
// verilog-library-extensions:(".v" ".h")
// End:
