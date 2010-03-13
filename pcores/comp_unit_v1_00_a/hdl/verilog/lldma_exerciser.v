//  ***************************************************************************
//  **  Copyright(C) 2008 Xilinx, Inc. All rights reserved.         
//  **                                                                       
//  **  This text contains proprietary, confidential information of          
//  **  Xilinx, Inc. , is distributed by under license from Xilinx, Inc.,    
//  **  and may be used, copied and/or disclosed only pursuant to the        
//  **  terms of a valid license agreement with Xilinx, Inc.                 
//  **                                                                       
//  **  Unmodified source code is guaranteed to place and route,             
//  **  function and run at speed according to the datasheet                 
//  **  specification. Source code is provided "as-is", with no              
//  **  obligation on the part of Xilinx to provide support.                 
//  **                                                                       
//  **  Xilinx Hotline support of source code IP shall only include          
//  **  standard level Xilinx Hotline support, and will only address         
//  **  issues and questions related to the standard released Netlist        
//  **  version of the core (and thus indirectly, the original core source). 
//  **                                                                       
//  **  The Xilinx Support Hotline does not have access to source            
//  **  code and therefore cannot answer specific questions related          
//  **  to source HDL. The Xilinx Support Hotline will only be able          
//  **  to confirm the problem in the Netlist version of the core.           
//  **                                                                       
//  **  This copyright and support notice must be retained as part           
//  **  of this text at all times.
//  ***************************************************************************
//
//****************************************************************************
// Filename:        lldma_exerciser.v
// Description:     This core is a LocalLink loopback core which connects to
//		    the Tx and Rx to the LocalLink interface.
//
//****************************************************************************
//
// Structure:   
//                  lldma_exerciser.v
//
// Author:      KD
//
// History:
//        KD         07/11/2008 Initial release.
//****************************************************************************/

module lldma_exerciser (
	SYS_Clk,
	Rst,
	global_test_en_l,

	dcr_read,
	dcr_write,
	dcr_wr_dbus,
	dcr_abus,
	dcr_ack,
	dcr_rd_dbus,

	tx_data,
	tx_rem,
	tx_sof_n,
	tx_eof_n,
	tx_sop_n,
	tx_eop_n,
	tx_src_rdy_n,
	tx_intr_in,
	tx_dst_rdy_n,

	rx_data,
	rx_rem,
	rx_sof_n,
	rx_eof_n,
	rx_sop_n,
	rx_eop_n,
	rx_src_rdy_n,
	rx_intr_in,
	rx_dst_rdy_n,

	tx_intr_out,
	rx_intr_out,
	debug_out_127_0
);

parameter C_DCR_BASEADDR = 'b00_0000_0000;
parameter C_DCR_HIGHADDR = 'b00_0000_0011;

input	SYS_Clk;
input	Rst;
input	global_test_en_l;

input	dcr_read;
input	dcr_write;
input [0:31] dcr_wr_dbus;
input [0:9] dcr_abus;
output	dcr_ack;
output [0:31] dcr_rd_dbus;

input [31:0] tx_data;
input [3:0] tx_rem;
input	tx_sof_n;
input	tx_eof_n;
input	tx_sop_n;
input	tx_eop_n;
input	tx_src_rdy_n;
input	tx_intr_in;
output	tx_dst_rdy_n;

output [31:0] rx_data;
output [3:0] rx_rem;
output	rx_sof_n;
output	rx_eof_n;
output	rx_sop_n;
output	rx_eop_n;
output	rx_src_rdy_n;
input	rx_intr_in;
input	rx_dst_rdy_n;

output	tx_intr_out;
output	rx_intr_out;
output [127:0] debug_out_127_0;

reg	Rst_n_ff;
reg [31:0] dcr_wr_data_ff, dcr_read_data_ff;
reg [9:0] dcr_addr_ff;
reg	dcr_write_ack_ff, dcr_read_ff, dcr_read_2ff, dcr_write_ff;
reg	dcr_write_2ff, dcr_read_ack_ff, dcr_read_ack_2ff, dcr_hit_ff;

wire dcrrst_l = Rst_n_ff;


wire [31:0] dcr_wr_data = dcr_wr_dbus[0:31];
wire [9:0] dcr_addr = dcr_abus[0:9];
wire [9:0] dcr_base = C_DCR_BASEADDR;
wire [9:0] dcr_high = C_DCR_HIGHADDR;
wire [9:0] dcr_mask = dcr_base[9:0] ^ dcr_high[9:0];

wire	dcr_hit = ((dcr_addr[9:0] & ~dcr_mask[9:0]) == dcr_base[9:0]);

wire	dcr_start_write = dcr_write_ff && ~dcr_write_2ff && dcr_hit_ff;
wire	dcr_start_read = dcr_read_ff && ~dcr_read_2ff && dcr_hit_ff;

wire	dcr_write_ack = dcr_write_ff && (dcr_start_write || dcr_write_ack_ff);
wire	dcr_read_ack = dcr_read_ff && (dcr_start_read || dcr_read_ack_ff);

wire [15:0] dcr_raw_exp = (16'h1 << dcr_addr_ff[3:0]);
wire [15:0] dcr_wr_exp = (dcr_start_write) ? dcr_raw_exp[15:0] : 16'h0;

always @(posedge SYS_Clk) begin
	Rst_n_ff <= ~Rst;
	dcr_wr_data_ff[31:0] <= dcr_wr_data[31:0];
	dcr_addr_ff[9:0] <= dcr_addr[9:0];
	dcr_read_ff <= dcr_read;
	dcr_read_2ff <= dcr_read_ff;
	dcr_write_ff <= dcr_write;
	dcr_write_2ff <= dcr_write_ff;
	dcr_hit_ff <= dcr_hit;
	dcr_write_ack_ff <= (dcrrst_l) ? dcr_write_ack : 1'b0;
	dcr_read_ack_ff <= (dcrrst_l) ? dcr_read_ack : 1'b0;
	dcr_read_ack_2ff <= (dcrrst_l) ? dcr_read_ack_ff : 1'b0;
end


reg [31:0] reg0_ctl_ff;
reg [31:0] reg2_err_ff;
reg [31:0] reg3_data_ff;
reg [31:0] reg4_data2_ff;
reg [31:0] reg5_tx_dbgcnt_ff, reg6_rx_dbgcnt_ff;
reg	tx_seen_pkt_ff;

wire	reg0_tx_dbgcnt_en = reg0_ctl_ff[0];
wire	reg0_rx_dbgcnt_en = reg0_ctl_ff[1];
wire [3:0] reg0_hdr_cnt = reg0_ctl_ff[7:4];
wire	reg0_general_reset = reg0_ctl_ff[8];
wire	reg0_en_dbg_first_pkt = reg0_ctl_ff[9];
wire	reg0_en_rdy_first_pkt = reg0_ctl_ff[10];
wire [3:0] reg0_rx_foot_rem_mask = reg0_ctl_ff[15:12];

wire rst_l = Rst_n_ff && ~reg0_general_reset;
			// This allows an easy software way to reset almost
			//  all lldma_exerciser state, including FIFO ptrs

wire	tx_dbg_rdy_deassert;

wire	tx_dbgcnt_en = reg0_tx_dbgcnt_en && global_test_en_l &&
				(~reg0_en_dbg_first_pkt || tx_seen_pkt_ff);
wire	rx_dbgcnt_en = reg0_rx_dbgcnt_en && global_test_en_l &&
				(~reg0_en_dbg_first_pkt || tx_seen_pkt_ff);

dbgcnt Txdbgcnt (
	.clk(SYS_Clk),
	.dbgcnt_in(reg5_tx_dbgcnt_ff[31:0]),
	.glbl_en_in(tx_dbgcnt_en),
	.rst_l(rst_l),
	.dbg_output(tx_dbg_rdy_deassert)
);

wire	rx_dbg_rdy_deassert;
dbgcnt Rxdbgcnt (
	.clk(SYS_Clk),
	.dbgcnt_in(reg6_rx_dbgcnt_ff[31:0]),
	.glbl_en_in(rx_dbgcnt_en),
	.rst_l(rst_l),
	.dbg_output(rx_dbg_rdy_deassert)
);

wire [31:0] reg0_ctl = (dcr_wr_exp[0]) ? dcr_wr_data_ff[31:0] : reg0_ctl_ff;

wire [31:0] reg2_err_pre = (dcr_wr_exp[2]) ?
		~dcr_wr_data_ff[31:0] & reg2_err_ff[31:0] : reg2_err_ff[31:0];
wire [31:0] reg3_data = (dcr_wr_exp[3]) ? dcr_wr_data_ff[31:0] :
							reg3_data_ff[31:0];
wire [31:0] reg4_data2 = (dcr_wr_exp[4]) ? dcr_wr_data_ff[31:0] :
							reg4_data2_ff[31:0];
wire [31:0] reg5_tx_dbgcnt = (dcr_wr_exp[5]) ? dcr_wr_data_ff[31:0] :
							reg5_tx_dbgcnt_ff[31:0];
wire [31:0] reg6_rx_dbgcnt = (dcr_wr_exp[6]) ? dcr_wr_data_ff[31:0] :
							reg6_rx_dbgcnt_ff[31:0];

wire [7:0] reg0_ver = 8'h04;			// Current version
wire [31:0] rd_val0 = { reg0_ver[7:0], 8'h0, reg0_ctl_ff[15:0] };
wire [31:0] rd_val1 = 32'h0;
wire [31:0] rd_val4 = { 22'h0, reg4_data2_ff[9:0] };

wire [31:0] dcr_read_data_pre =
		((dcr_raw_exp[0]) ? rd_val0[31:0] : 32'h0) |
		((dcr_raw_exp[1]) ? rd_val1[31:0] : 32'h0) |
		((dcr_raw_exp[2]) ? reg2_err_ff[31:0] : 32'h0) |
		((dcr_raw_exp[3]) ? reg3_data_ff[31:0] : 32'h0) |
		((dcr_raw_exp[4]) ? rd_val4[31:0] : 32'h0) |
		((dcr_raw_exp[5]) ? reg5_tx_dbgcnt_ff[31:0] : 32'h0) |
		((dcr_raw_exp[6]) ? reg6_rx_dbgcnt_ff[31:0] : 32'h0);

wire [31:0] dcr_read_data =
	(dcr_read_ack) ? dcr_read_data_pre[31:0] : dcr_read_data_ff[31:0];


reg	tx_sof_n_ff, tx_eof_n_ff, tx_sop_n_ff, tx_eop_n_ff;
reg	tx_rdy_ff, tx_fifo_wr_ff, tx_valid_payload_end_ff;
reg [8:0] tx_fifo_addr_ff;
reg [8:0] rx_fifo_addr_ff;
reg [2:0] tx_hdr_addr_ff;
reg [1:0] tx_pkt_num_ff;
reg [1:0] rx_pkt_num_ff;
reg	rx_ptr_diffs_ff;

reg	tx_in_frame_ff, tx_in_payload_ff, tx_hdr_done_ff;

wire	tx_valid = ~tx_src_rdy_n && ~tx_dst_rdy_n;
wire	tx_frame_start = ~tx_sof_n && tx_valid;
wire	tx_frame_end = ~tx_eof_n && tx_valid;
wire	tx_payload_start = ~tx_sop_n && tx_valid;
wire	tx_payload_end = ~tx_eop_n && tx_valid;
wire	tx_in_frame = ~tx_frame_end && (tx_frame_start || tx_in_frame_ff);
wire	tx_in_frame2 = tx_frame_start || tx_in_frame_ff;

wire	tx_seen_pkt = (~tx_sof_n && ~tx_src_rdy_n) || tx_seen_pkt_ff;
wire	tx_valid_payload_end = (tx_valid) ? tx_payload_end :
						tx_valid_payload_end_ff;

wire	tx_in_payload = ~tx_payload_end && (tx_payload_start ||
							tx_in_payload_ff);
wire	tx_in_payload2 = tx_payload_start || tx_in_payload_ff;
wire	tx_hdr_done = ~tx_frame_end && (tx_payload_start || tx_hdr_done_ff);

wire	tx_fifo_wr = tx_valid && tx_in_payload2;
wire	tx_hdr_wr = tx_valid && ~tx_hdr_done && ~tx_frame_end;
wire [2:0] tx_hdr_addr = tx_hdr_addr_ff[2:0] + { 2'b00, tx_hdr_wr };
wire [1:0] tx_pkt_num = tx_pkt_num_ff[1:0] + { 1'b0, tx_payload_start };

wire [1:0] tx_rem_enc =
		((tx_rem[3:0] == 4'b0000) ? 2'b00 : 2'b00) |
		((tx_rem[3:0] == 4'b0001) ? 2'b11 : 2'b00) |
		((tx_rem[3:0] == 4'b0011) ? 2'b10 : 2'b00) |
		((tx_rem[3:0] == 4'b0111) ? 2'b01 : 2'b00);

wire	tx_rem_bad_pre = tx_rem[3] || (tx_rem[2] && (tx_rem[1:0] != 2'b11)) ||
		(tx_rem[1] && ~tx_rem[0]);

wire	tx_rem1_bad = tx_valid && tx_rem_bad_pre;
wire	tx_rem2_bad = tx_valid && (tx_rem[3:0] != 4'b0000) && tx_eop_n;
wire	tx_frame_start_err = tx_frame_start && tx_in_frame_ff;
wire	tx_foot_err = tx_valid && tx_frame_end && ~tx_valid_payload_end_ff;
wire	tx_out_frame_err = tx_valid && ~tx_in_frame && ~tx_in_frame_ff;
wire [3:0] tx_in_ctls = { tx_frame_end, tx_payload_end, tx_payload_start,
						tx_frame_start };
wire	tx_ctls_good =
		(tx_in_ctls[3:0] == 4'b0000) ||
		(tx_in_ctls[3:0] == 4'b0001) ||
		(tx_in_ctls[3:0] == 4'b0010) ||
		(tx_in_ctls[3:0] == 4'b0100) ||
		(tx_in_ctls[3:0] == 4'b1000) ||
		(tx_in_ctls[3:0] == 4'b0110);	// tx_sop and tx_eop
wire	tx_ctl_err = ~tx_ctls_good;
wire	tx_payload_err = tx_valid && tx_payload_end &&
				~(tx_payload_start || tx_in_payload_ff);

wire [1:0] tx_pkt_enc = { tx_payload_start, tx_payload_end };

wire [3:0] tx_upper = { tx_pkt_enc[1:0], tx_rem_enc[1:0] };

wire [8:0] tx_fifo_addr = tx_fifo_addr_ff[8:0] + { 8'h00, tx_fifo_wr };

wire [8:0] rx_fifo_addr_inced = rx_fifo_addr_ff[8:0] + 9'h1;
wire	rx_ptr_diffs = (tx_fifo_addr_ff[8:0] != rx_fifo_addr_ff[8:0]);
wire	rx_ptr2_diffs = (tx_fifo_addr_ff[8:0] != rx_fifo_addr_inced[8:0]);
wire	rx_has_data = rx_ptr_diffs && (rx_ptr2_diffs || ~tx_fifo_wr_ff);

wire	tx_hdrram_full = (tx_pkt_num_ff[0] == rx_pkt_num_ff[0]) &&
			(tx_pkt_num_ff[1] != rx_pkt_num_ff[1]);

wire [8:0] tx_fifo_size = (tx_fifo_addr_ff[8:0] - rx_fifo_addr_ff[8:0]);
wire	tx_fifo_full = (tx_fifo_size >= 9'h1e0);
wire	tx_rdy = ~tx_hdrram_full && ~tx_fifo_full && ~tx_dbg_rdy_deassert &&
			(~reg0_en_rdy_first_pkt || tx_seen_pkt_ff);

wire	tx_hdr_err = (tx_payload_start || tx_frame_end) &&
					(tx_hdr_addr_ff[2:0] != 3'b000);

always @(posedge SYS_Clk) begin
	reg0_ctl_ff[31:0] <= (dcrrst_l) ? reg0_ctl[31:0] : 32'h0;
	reg3_data_ff[31:0] <= (rst_l) ? reg3_data[31:0] : 32'h0;
	reg4_data2_ff[31:0] <= (rst_l) ? reg4_data2[31:0] : 32'h0;
	reg5_tx_dbgcnt_ff[31:0] <= (rst_l) ? reg5_tx_dbgcnt[31:0] : 32'h0;
	reg6_rx_dbgcnt_ff[31:0] <= (rst_l) ? reg6_rx_dbgcnt[31:0] : 32'h0;
	dcr_read_data_ff[31:0] <= (dcrrst_l) ? dcr_read_data[31:0] : 32'h0;

	tx_fifo_addr_ff[8:0] <= (rst_l) ? tx_fifo_addr[8:0] : 9'h0;
	tx_hdr_addr_ff[2:0] <= (rst_l) ? tx_hdr_addr[2:0] : 3'h0;
	tx_pkt_num_ff[1:0] <= (rst_l) ? tx_pkt_num[1:0] : 2'b00;
	tx_in_frame_ff <= (rst_l) ? tx_in_frame : 1'b0;
	tx_in_payload_ff <= (rst_l) ? tx_in_payload : 1'b0;
	tx_hdr_done_ff <= (rst_l) ? tx_hdr_done : 1'b0;
	tx_fifo_wr_ff <= (rst_l) ? tx_fifo_wr : 1'b0;
	tx_sof_n_ff <= tx_sof_n;
	tx_eof_n_ff <= tx_eof_n;
	tx_sop_n_ff <= tx_sop_n;
	tx_eop_n_ff <= tx_eop_n;
	tx_valid_payload_end_ff <= (rst_l) ? tx_valid_payload_end : 1'b0;
	tx_rdy_ff <= (rst_l) ? tx_rdy : 1'b0;
	tx_seen_pkt_ff <= (rst_l) ? tx_seen_pkt : 1'b0;
end

assign	tx_dst_rdy_n = ~tx_rdy_ff;

// RX design:
// All LocalLink outputs are from registers.

// Cycle 0: calculate what to drive onto bus in cycle 1.
// Cycle 1: Drive registered sigs onto bus, determine if accepted,
//		prepare what to drive onto bus in cycle 2.

// Requires a rx_stage_ff to hold the "head" of the RX FIFO:
// Cycle 0: Drive rx_fifo_addr to BRAMs
// cycle 1: bram_output is captured in rx_stage_ff
// cycle 2: rx_stage_ff is driven to bus.  If a valid xfer happened this
//		cycle, capture new data in rx_stage_ff and inc rx_fifo_addr.
// Note that when driving FIFO[0] data onto the bus, rx_fifo_addr_ff = 1,
//   and rx_fifo_addr will be incremented to 2 if data accepted.

reg [3:0] rx_hdr_cntr_ff;
reg [2:0] rx_footer_cntr_ff;
reg [2:0] rx_foot_addr_ff;
reg	rx_hdr_cntrnon0_ff, rx_hdr_start_ff, rx_hdr_done_ff, rx_in_payload_ff;
reg	rx_in_pkt_ff, rx_src_rdy_ff;
reg	rx_eof_ff, rx_sop_ff, rx_eop_ff, rx_sop_done_ff, rx_eop_done_ff;
reg	rx_sof_ff, rx_sof_done_ff, rx_payload_end_ff;
reg	rx_in_footer_ff, rx_footer_end_ff, rx_stage_valid_ff;
reg [31:0] rx_hdr_data_ff, rx_footer_data_ff, rx_out_data_ff;
reg [35:0] rx_stage_data_ff;
reg [3:0] rx_out_rem_ff;

wire [35:0] rx_fifo_raw;
wire [31:0] rx_hdrram_raw;


wire	rx_valid_xfer = ~rx_src_rdy_n && ~rx_dst_rdy_n;
wire	rx_stage_valid_xfer = rx_valid_xfer && rx_in_payload_ff;
wire	rx_fifo_inc = (rx_has_data && ~rx_stage_valid_ff) ||
		(rx_stage_valid_ff && rx_stage_valid_xfer && rx_has_data);
wire [8:0] rx_fifo_addr = (rx_fifo_inc) ? rx_fifo_addr_inced[8:0] :
							rx_fifo_addr_ff[8:0];

wire	rx_stage_latchnew = rx_fifo_inc;
wire	rx_stage_hold = rx_stage_valid_ff &&
					~(rx_valid_xfer && rx_in_payload_ff);
wire	rx_stage_valid = rx_stage_latchnew || rx_stage_hold;

wire [35:0] rx_stage_data = (rx_stage_latchnew) ? rx_fifo_raw[35:0] :
							rx_stage_data_ff[35:0];

wire [3:0] rx_upper = rx_stage_data[35:32];
wire [3:0] rx_rem_dec =
		((rx_upper[1:0] == 2'b00) ? 4'b0000 : 4'b0000) |
		((rx_upper[1:0] == 2'b11) ? 4'b0001 : 4'b0000) |
		((rx_upper[1:0] == 2'b10) ? 4'b0011 : 4'b0000) |
		((rx_upper[1:0] == 2'b01) ? 4'b0111 : 4'b0000);
wire [1:0] rx_fifo_stat = rx_upper[3:2];

wire	rx_hdr_start = rx_stage_valid_ff && (~rx_in_pkt_ff || ~rx_sof_done_ff);
wire	rx_hdr_cntrnon0 = (rx_hdr_cntr_ff[3:0] != 4'h0);
wire	rx_hdr_dodec = rx_hdr_cntrnon0 && rx_valid_xfer;
wire [3:0] rx_hdr_cntr_deced = rx_hdr_cntr_ff[3:0] - { 3'b000, rx_hdr_dodec };
wire [3:0] rx_hdr_cntr = (rx_hdr_start) ? reg0_hdr_cnt[3:0] :
						rx_hdr_cntr_deced[3:0];

wire	rx_hdr_end_pre = ~rx_hdr_cntrnon0 ||
		((rx_hdr_cntr_ff[3:1] == 3'b000) && rx_valid_xfer);
wire	rx_hdr_end = rx_in_pkt_ff && ~rx_hdr_done_ff && rx_hdr_end_pre &&
					rx_valid_xfer;
wire	rx_hdr_done = rx_in_pkt_ff && (rx_hdr_end || rx_hdr_done_ff);

wire	rx_payload_start = rx_in_pkt_ff && rx_hdr_end;
wire	rx_in_payload2 = rx_payload_start || rx_in_payload_ff;
wire	rx_payload_end = rx_in_payload2 && rx_stage_valid && rx_fifo_stat[0];
wire	rx_payload_end_done = rx_payload_end_ff && rx_valid_xfer;
wire	rx_in_payload = ~rx_payload_end_done && rx_in_payload2;


wire	rx_footer_start = rx_in_pkt_ff && rx_eop_ff && rx_valid_xfer;
wire	rx_footer_cntrnon0 = (rx_footer_cntr_ff[2:0] != 3'b000);
wire	rx_footer_dodec = rx_footer_cntrnon0 && rx_valid_xfer;
wire [2:0] rx_footer_cntr_deced = rx_footer_cntr_ff[2:0] -
						{ 2'b00, rx_footer_dodec };
wire [2:0] rx_footer_cntr = (rx_footer_start) ? 3'b111 :
						rx_footer_cntr_deced[2:0];
wire	rx_footer_end_pre = ~rx_footer_cntrnon0 ||
			((rx_footer_cntr_ff[2:1] == 2'b00) && rx_valid_xfer);
wire	rx_footer_end = rx_in_pkt_ff && rx_in_footer_ff && rx_footer_end_pre;
wire	rx_footer_end_done = rx_footer_end_ff && rx_valid_xfer;
wire	rx_in_footer = ~rx_footer_end_done && (rx_footer_start ||
							rx_in_footer_ff);
wire	rx_foot_addr_doinc = rx_valid_xfer && rx_in_footer_ff;
wire [2:0] rx_foot_addr = rx_foot_addr_ff[2:0] + { 2'b00, rx_foot_addr_doinc };
wire [1:0] rx_pkt_num = rx_pkt_num_ff[1:0] + { 1'b0, rx_footer_end_done };

wire	rx_foot_err = ~rx_in_pkt_ff && (rx_foot_addr_ff[2:0] != 3'b000);
wire	rx_foot_rem_bit = rx_in_footer_ff && rx_foot_addr[2] &&
				reg0_rx_foot_rem_mask[rx_foot_addr[1:0]];

wire	rx_in_pkt = ~rx_footer_end_done && (rx_hdr_start || rx_in_pkt_ff);

wire [31:0] rx_hdr_data = rx_hdrram_raw[31:0];
wire [31:0] rx_footer_data = rx_hdrram_raw[31:0];

wire	rx_src_rdy_pre = (rx_in_payload) ? rx_stage_valid : rx_in_pkt;
wire	rx_src_rdy = rx_src_rdy_pre && ~rx_dbg_rdy_deassert;

wire	rx_sof_done = rx_in_pkt &&
			((rx_sof_ff && rx_valid_xfer) || rx_sof_done_ff);
wire	rx_sof = rx_in_pkt && ~rx_sof_done;

wire	rx_sop_done = rx_in_pkt &&
			((rx_sop_ff && rx_valid_xfer) || rx_sop_done_ff);
wire	rx_sop = rx_in_payload && ~rx_sop_done;

wire	rx_eop_done = rx_in_pkt &&
			((rx_eop_ff && rx_valid_xfer) || rx_eop_done_ff);
wire	rx_eop = rx_payload_end && ~rx_eop_done;

wire	rx_eof = rx_footer_end && ~rx_footer_end_done;
wire [3:0] rx_out_rem = (rx_in_payload) ? rx_rem_dec[3:0] :
				{ 4 { rx_foot_rem_bit } };

wire [31:0] rx_out_data = (rx_in_payload) ? rx_stage_data[31:0] :
			(rx_hdr_cntrnon0) ? rx_hdr_data[31:0] :
					rx_footer_data[31:0];

always @(posedge SYS_Clk) begin
	rx_fifo_addr_ff[8:0] <= (rst_l) ? rx_fifo_addr[8:0] : 9'h0;
	rx_hdr_cntr_ff[3:0] <= (rst_l) ? rx_hdr_cntr[3:0] : 4'h0;
	rx_foot_addr_ff[2:0] <= (rst_l) ? rx_foot_addr[2:0] : 3'b000;
	rx_pkt_num_ff[1:0] <= (rst_l) ? rx_pkt_num[1:0] : 2'b00;
	rx_hdr_cntrnon0_ff <= (rst_l) ? rx_hdr_cntrnon0 : 1'b0;
	rx_hdr_done_ff <= (rst_l) ? rx_hdr_done : 1'b0;
	rx_footer_cntr_ff[2:0] <= (rst_l) ? rx_footer_cntr[2:0] : 3'b000;
	rx_hdr_start_ff <= (rst_l) ? rx_hdr_start : 1'b0;
	rx_in_payload_ff <= (rst_l) ? rx_in_payload : 1'b0;
	rx_in_pkt_ff <= (rst_l) ? rx_in_pkt : 1'b0;
	rx_in_footer_ff <= (rst_l) ? rx_in_footer : 1'b0;
	rx_footer_end_ff <= (rst_l) ? rx_footer_end : 1'b0;
	rx_payload_end_ff <= (rst_l) ? rx_payload_end : 1'b0;
	rx_src_rdy_ff <= (rst_l) ? rx_src_rdy : 1'b0;
	rx_sof_ff <= (rst_l) ? rx_sof : 1'b0;
	rx_sof_done_ff <= (rst_l) ? rx_sof_done : 1'b0;
	rx_eof_ff <= (rst_l) ? rx_eof : 1'b0;
	rx_sop_ff <= (rst_l) ? rx_sop : 1'b0;
	rx_sop_done_ff <= (rst_l) ? rx_sop_done : 1'b0;
	rx_eop_ff <= (rst_l) ? rx_eop : 1'b0;
	rx_eop_done_ff <= (rst_l) ? rx_eop_done : 1'b0;
	rx_hdr_data_ff[31:0] <= (rst_l) ? rx_hdr_data[31:0] : 32'h0;
	rx_footer_data_ff[31:0] <= (rst_l) ? rx_footer_data[31:0] : 32'h0;
	rx_stage_data_ff[35:0] <= (rst_l) ? rx_stage_data[35:0] : 36'h0;
	rx_stage_valid_ff <= (rst_l) ? rx_stage_valid : 1'b0;
	rx_out_rem_ff[3:0] <= (rst_l) ? rx_out_rem[3:0] : 4'h0;
	rx_ptr_diffs_ff <= (rst_l) ? rx_ptr_diffs : 1'b0;
	rx_out_data_ff[31:0] <= rx_out_data[31:0];
end

wire [3:0] reg4_rem = reg4_data2_ff[3:0];
wire	reg4_sof = reg4_data2_ff[4];
wire	reg4_sop = reg4_data2_ff[5];
wire	reg4_eop = reg4_data2_ff[6];
wire	reg4_eof = reg4_data2_ff[7];
wire	rx_drv_true = ~reg4_data2_ff[8] || rx_src_rdy_ff;

assign rx_src_rdy_n = ~rx_src_rdy_ff;

assign rx_data[31:0] = (rx_drv_true) ? rx_out_data_ff[31:0] :
							reg3_data_ff[31:0];
assign rx_rem[3:0] = (rx_drv_true) ? rx_out_rem_ff[3:0] : reg4_rem[3:0];

assign rx_sof_n = (rx_drv_true) ? ~rx_sof_ff : ~reg4_sof;
assign rx_eof_n = (rx_drv_true) ? ~rx_eof_ff : ~reg4_eof;
assign rx_sop_n = (rx_drv_true) ? ~rx_sop_ff : ~reg4_sop;
assign rx_eop_n = (rx_drv_true) ? ~rx_eop_ff : ~reg4_eop;

assign	tx_intr_out = tx_intr_in;
assign	rx_intr_out = rx_intr_in;

fiforam Fiforam (.clk(SYS_Clk),
		.we(tx_fifo_wr),
		.addr0(tx_fifo_addr_ff[8:0]),
		.addr1(rx_fifo_addr[8:0]),
		.wr_data0({ tx_upper[3:0], tx_data[31:0]} ),
		.rd_data1(rx_fifo_raw[35:0])
);


hdrram Hdrram (.clk(SYS_Clk),
		.we(tx_hdr_wr),
		.addr0({ tx_pkt_num_ff[0], tx_hdr_addr_ff[2:0] } ),
		.addr1({ rx_pkt_num[0], rx_foot_addr[2:0] }),
		.data0_in(tx_data[31:0]),
		.data1_out(rx_hdrram_raw[31:0])
);

wire [31:0] err_new = { 16'h0,
		4'h0,							//15:12
		3'b000, rx_foot_err,					//11:8
		tx_payload_err, tx_rem2_bad,
					tx_rem1_bad, tx_out_frame_err,	// 7:4
		tx_frame_start_err, tx_foot_err,
						tx_hdr_err, tx_ctl_err	// 3:0
};

wire [31:0] reg2_err = reg2_err_pre[31:0] | err_new[31:0];

always @(posedge SYS_Clk) begin
	reg2_err_ff[31:0] <= (dcrrst_l) ? reg2_err[31:0] : 32'h0;
end

reg [63:0] tx_dbg_ff, rx_dbg_ff;

wire [63:0] tx_dbg = {
	6'h0,							// 31:26
		tx_hdrram_full,					// 25
	tx_fifo_addr_ff[8:0],					// 24:16
	tx_fifo_wr, tx_in_frame, tx_in_payload, tx_frame_end,	// 15:12
	tx_intr_in, tx_fifo_full, tx_src_rdy_n, tx_dst_rdy_n,	// 11:8
	tx_eof_n, tx_eop_n, tx_sop_n, tx_sof_n,			// 7:4
	tx_rem[3:0],						// 3:0

	tx_data[31:0]						// 31:0
	};

wire [63:0] rx_dbg = {
	6'h0,							// 31:26
		global_test_en_l,				// 25
	rx_fifo_addr_ff[8:0],					// 24:16
	rx_stage_hold, rx_stage_valid, rx_stage_latchnew, rx_fifo_inc, // 15:12
	rx_intr_in, tx_seen_pkt_ff, rx_src_rdy_n, rx_dst_rdy_n,	// 11:8
	rx_eof_n, rx_eop_n, rx_sop_n, rx_sof_n,			// 7:4
	rx_rem[3:0],						// 3:0

	rx_data[31:0]						// 31:0
	};

always @(posedge SYS_Clk) begin
	tx_dbg_ff[63:0] <= tx_dbg[63:0];
	rx_dbg_ff[63:0] <= rx_dbg[63:0];
end

assign debug_out_127_0[127:0] = { rx_dbg_ff[63:0], tx_dbg_ff[63:0] };

assign dcr_ack = dcr_read_ack_2ff || dcr_write_ack_ff;
wire [0:31] dcr_rd_dbus = (dcr_read_ack_2ff) ? dcr_read_data_ff[31:0] :
							dcr_wr_dbus[0:31];

endmodule

