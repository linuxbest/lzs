/******************************************************************************
 *   File Name :  encode.v
 *     Version :  0.1
 *        Date :  2008 02 27
 *  Description:  encode top
 * Dependencies:
 *
 *
 *      Company:  Beijing Soul
 *
 *          BUG:
 *
 *****************************************************************************/
module encode(/*AUTOARG*/
   // Outputs
   valid_o, m_src_getn, hwe, hwaddr, hraddr, hdata_o,
   done_o, data_o,
   // Inputs
   src_empty, rst, m_last, hdata, fo_full, fi, clk, ce
   );
   parameter LZF_WIDTH = 20;

   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input		ce;			// To dp of encode_dp.v, ...
   input		clk;			// To dp of encode_dp.v, ...
   input [63:0]		fi;			// To dp of encode_dp.v
   input		fo_full;		// To dp of encode_dp.v
   input [7:0]		hdata;			// To ctl of encode_ctl.v
   input		m_last;			// To dp of encode_dp.v
   input		rst;			// To dp of encode_dp.v, ...
   input		src_empty;		// To dp of encode_dp.v
   // End of automatics
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output [15:0]	data_o;			// From out of encode_out.v
   output		done_o;			// From out of encode_out.v
   output [7:0]		hdata_o;		// From dp of encode_dp.v
   output [10:0]	hraddr;			// From ctl of encode_ctl.v
   output [10:0]	hwaddr;			// From dp of encode_dp.v
   output		hwe;			// From dp of encode_dp.v
   output		m_src_getn;		// From dp of encode_dp.v
   output		valid_o;		// From out of encode_out.v
   // End of automatics
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			cnt_finish;		// From ctl of encode_ctl.v
   wire [3:0]		cnt_len;		// From ctl of encode_ctl.v
   wire [12:0]		cnt_output;		// From ctl of encode_ctl.v
   wire			cnt_output_enable;	// From ctl of encode_ctl.v
   wire [7:0]		data;			// From dp of encode_dp.v
   wire [7:0]		data_d1;		// From dp of encode_dp.v
   wire [7:0]		data_d2;		// From dp of encode_dp.v
   wire			data_empty;		// From dp of encode_dp.v
   wire			data_valid;		// From dp of encode_dp.v
   wire [7:0]		hash_d1;		// From dp of encode_dp.v
   wire [7:0]		hash_data;		// From dp of encode_dp.v
   wire [7:0]		hash_data1;		// From dp of encode_dp.v
   wire			hash_data_d1;		// From dp of encode_dp.v
   wire [LZF_WIDTH-1:0]	hash_ref;		// From dp of encode_dp.v
   wire [LZF_WIDTH-1:0]	iidx;			// From dp of encode_dp.v
   // End of automatics
   encode_dp dp(/*AUTOINST*/
		// Outputs
		.m_src_getn		(m_src_getn),
		.data_empty		(data_empty),
		.data			(data[7:0]),
		.data_valid		(data_valid),
		.hash_data		(hash_data[7:0]),
		.hash_data1		(hash_data1[7:0]),
		.hash_ref		(hash_ref[LZF_WIDTH-1:0]),
		.data_d1		(data_d1[7:0]),
		.data_d2		(data_d2[7:0]),
		.iidx			(iidx[LZF_WIDTH-1:0]),
		.hash_d1		(hash_d1[7:0]),
		.hash_data_d1		(hash_data_d1),
		.hwaddr			(hwaddr[10:0]),
		.hwe			(hwe),
		.hdata_o		(hdata_o[7:0]),
		// Inputs
		.clk			(clk),
		.rst			(rst),
		.ce			(ce),
		.fo_full		(fo_full),
		.fi			(fi[63:0]),
		.src_empty		(src_empty),
		.m_last			(m_last));
   encode_ctl ctl(/*AUTOINST*/
		  // Outputs
		  .hraddr		(hraddr[10:0]),
		  .cnt_output_enable	(cnt_output_enable),
		  .cnt_len		(cnt_len[3:0]),
		  .cnt_output		(cnt_output[12:0]),
		  .cnt_finish		(cnt_finish),
		  // Inputs
		  .clk			(clk),
		  .rst			(rst),
		  .data_valid		(data_valid),
		  .data_empty		(data_empty),
		  .hash_data		(hash_data[7:0]),
		  .hash_data1		(hash_data1[7:0]),
		  .data_d1		(data_d1[7:0]),
		  .data_d2		(data_d2[7:0]),
		  .hash_ref		(hash_ref[LZF_WIDTH-1:0]),
		  .iidx			(iidx[LZF_WIDTH-1:0]),
		  .hdata		(hdata[7:0]),
		  .data			(data[7:0]),
		  .hash_d1		(hash_d1[7:0]),
		  .hash_data_d1		(hash_data_d1));
   encode_out out(/*AUTOINST*/
		  // Outputs
		  .data_o		(data_o[15:0]),
		  .valid_o		(valid_o),
		  .done_o		(done_o),
		  // Inputs
		  .clk			(clk),
		  .rst			(rst),
		  .ce			(ce),
		  .cnt_output_enable	(cnt_output_enable),
		  .cnt_finish		(cnt_finish),
		  .cnt_output		(cnt_output[12:0]),
		  .cnt_len		(cnt_len[3:0]));
   
endmodule // encode
// Local Variables:
// verilog-library-directories:("." "../../common/")
// verilog-library-files:("")
// verilog-library-extensions:(".v" ".h")
// End: