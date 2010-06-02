//-----------------------------------------------------------------------------
// system_tb.v
//-----------------------------------------------------------------------------

`timescale 1 ps / 100 fs

`uselib lib=unisims_ver

// START USER CODE (Do not remove this line)

// User: Put your directives here. Code in this
//       section will not be overwritten.

// END USER CODE (Do not remove this line)

module system_tb
  (
  );

  // START USER CODE (Do not remove this line)

  // User: Put your signals here. Code in this
  //       section will not be overwritten.

  // END USER CODE (Do not remove this line)

  real sys_clk_PERIOD = 10000.000000;
  real sys_rst_LENGTH = 160000;

  reg sys_clk;
  reg sys_rst;
  wire Bus2IP_Clk;
  wire Bus2IP_Reset;
  reg [0:31] IP2Bus_Data;
  reg IP2Bus_WrAck;
  reg IP2Bus_RdAck;
  reg IP2Bus_AddrAck;
  reg IP2Bus_Error;
  wire [0:31] Bus2IP_Addr;
  wire [0:31] Bus2IP_Data;
  wire Bus2IP_RNW;
  wire [0:3] Bus2IP_BE;
  wire Bus2IP_Burst;
  wire [0:7] Bus2IP_BurstLength;
  wire Bus2IP_CS;
  wire Bus2IP_WrReq;
  wire Bus2IP_RdReq;
  wire Bus2IP_RdCE;
  wire Bus2IP_WrCE;
  reg IP2Bus_MstRd_Req;
  reg IP2Bus_MstWr_Req;
  reg [0:31] IP2Bus_Mst_Addr;
  reg [0:3] IP2Bus_Mst_BE;
  reg IP2Bus_Mst_Lock;
  reg IP2Bus_Mst_Reset;
  wire Bus2IP_Mst_CmdAck;
  wire Bus2IP_Mst_Cmplt;
  wire Bus2IP_Mst_Error;
  wire Bus2IP_Mst_Rearbitrate;
  wire Bus2IP_Mst_Cmd_Timeout;
  wire [0:31] Bus2IP_MstRd_d;
  wire Bus2IP_MstRd_src_rdy_n;
  reg [0:31] IP2Bus_MstWr_d;
  wire Bus2IP_MstWr_dst_rdy_n;
  wire tx_interrupt;
  wire rx_interrupt;
  reg DCR_Read;
  reg DCR_Write;
  reg [0:9] DCR_ABus;
  reg [0:31] DCR_Sl_DBus;
  wire Sl_dcrAck;
  wire [0:31] Sl_dcrDBus;
  wire Sl_dcrTimeoutWait;

  system
    dut (
      .sys_clk ( sys_clk ),
      .sys_rst ( sys_rst ),
      .Bus2IP_Clk ( Bus2IP_Clk ),
      .Bus2IP_Reset ( Bus2IP_Reset ),
      .IP2Bus_Data ( IP2Bus_Data ),
      .IP2Bus_WrAck ( IP2Bus_WrAck ),
      .IP2Bus_RdAck ( IP2Bus_RdAck ),
      .IP2Bus_AddrAck ( IP2Bus_AddrAck ),
      .IP2Bus_Error ( IP2Bus_Error ),
      .Bus2IP_Addr ( Bus2IP_Addr ),
      .Bus2IP_Data ( Bus2IP_Data ),
      .Bus2IP_RNW ( Bus2IP_RNW ),
      .Bus2IP_BE ( Bus2IP_BE ),
      .Bus2IP_Burst ( Bus2IP_Burst ),
      .Bus2IP_BurstLength ( Bus2IP_BurstLength ),
      .Bus2IP_CS ( Bus2IP_CS ),
      .Bus2IP_WrReq ( Bus2IP_WrReq ),
      .Bus2IP_RdReq ( Bus2IP_RdReq ),
      .Bus2IP_RdCE ( Bus2IP_RdCE ),
      .Bus2IP_WrCE ( Bus2IP_WrCE ),
      .IP2Bus_MstRd_Req ( IP2Bus_MstRd_Req ),
      .IP2Bus_MstWr_Req ( IP2Bus_MstWr_Req ),
      .IP2Bus_Mst_Addr ( IP2Bus_Mst_Addr ),
      .IP2Bus_Mst_BE ( IP2Bus_Mst_BE ),
      .IP2Bus_Mst_Lock ( IP2Bus_Mst_Lock ),
      .IP2Bus_Mst_Reset ( IP2Bus_Mst_Reset ),
      .Bus2IP_Mst_CmdAck ( Bus2IP_Mst_CmdAck ),
      .Bus2IP_Mst_Cmplt ( Bus2IP_Mst_Cmplt ),
      .Bus2IP_Mst_Error ( Bus2IP_Mst_Error ),
      .Bus2IP_Mst_Rearbitrate ( Bus2IP_Mst_Rearbitrate ),
      .Bus2IP_Mst_Cmd_Timeout ( Bus2IP_Mst_Cmd_Timeout ),
      .Bus2IP_MstRd_d ( Bus2IP_MstRd_d ),
      .Bus2IP_MstRd_src_rdy_n ( Bus2IP_MstRd_src_rdy_n ),
      .IP2Bus_MstWr_d ( IP2Bus_MstWr_d ),
      .Bus2IP_MstWr_dst_rdy_n ( Bus2IP_MstWr_dst_rdy_n ),
      .tx_interrupt ( tx_interrupt ),
      .rx_interrupt ( rx_interrupt ),
      .DCR_Read ( DCR_Read ),
      .DCR_Write ( DCR_Write ),
      .DCR_ABus ( DCR_ABus ),
      .DCR_Sl_DBus ( DCR_Sl_DBus ),
      .Sl_dcrAck ( Sl_dcrAck ),
      .Sl_dcrDBus ( Sl_dcrDBus ),
      .Sl_dcrTimeoutWait ( Sl_dcrTimeoutWait )
    );

  // Clock generator for sys_clk

  initial
    begin
      sys_clk = 1'b0;
      forever #(sys_clk_PERIOD/2.00)
        sys_clk = ~sys_clk;
    end

  // Reset Generator for sys_rst

  initial
    begin
      sys_rst = 1'b0;
      #(sys_rst_LENGTH) sys_rst = ~sys_rst;
    end

  // START USER CODE (Do not remove this line)

     wire [0:31] IP2Bus_Data_i;
     wire IP2Bus_WrAck_i;
     wire IP2Bus_RdAck_i;
     wire IP2Bus_AddrAck_i;
     wire IP2Bus_Error_i;

     wire IP2Bus_MstRd_Req_i;
     wire IP2Bus_MstWr_Req_i;
     wire [0:31] IP2Bus_Mst_Addr_i;
     wire [0:3] IP2Bus_Mst_BE_i;
     wire IP2Bus_Mst_Lock_i;
     wire IP2Bus_Mst_Reset_i;
     wire [0:31] IP2Bus_MstWr_d_i;

     wire DCR_Read_i;
     wire DCR_Write_i;
     wire [0:9] DCR_ABus_i;
     wire [0:31] DCR_Sl_DBus_i;
     always @(*)
	begin
	IP2Bus_Data = IP2Bus_Data_i;
	IP2Bus_WrAck = IP2Bus_WrAck_i;
	IP2Bus_RdAck = IP2Bus_RdAck_i;
	IP2Bus_AddrAck = IP2Bus_AddrAck_i;
	IP2Bus_Error = IP2Bus_Error_i;

	IP2Bus_MstRd_Req=IP2Bus_MstRd_Req_i;
	IP2Bus_MstWr_Req=IP2Bus_MstWr_Req_i;
	IP2Bus_Mst_Addr=IP2Bus_Mst_Addr_i;
	IP2Bus_Mst_BE=IP2Bus_Mst_BE_i;
	IP2Bus_Mst_Lock=IP2Bus_Mst_Lock_i;
	IP2Bus_Mst_Reset=IP2Bus_Mst_Reset_i;
	IP2Bus_MstWr_d=IP2Bus_MstWr_d_i;

	DCR_Sl_DBus = DCR_Sl_DBus_i;
	DCR_ABus = DCR_ABus_i;
	DCR_Read =  DCR_Read_i;
	DCR_Write = DCR_Write_i;
	end

  lldma_tb 
    lldma_tb (
		.rx_interrupt(rx_interrupt),
		.tx_interrrupt(tx_interrupt),

		.Bus2IP_Clk ( Bus2IP_Clk ),
		.Bus2IP_Reset ( Bus2IP_Reset ),
		.IP2Bus_Data ( IP2Bus_Data_i ),
		.IP2Bus_WrAck ( IP2Bus_WrAck_i ),
		.IP2Bus_RdAck ( IP2Bus_RdAck_i ),
		.IP2Bus_AddrAck ( IP2Bus_AddrAck_i ),
		.IP2Bus_Error ( IP2Bus_Error_i ),
		.Bus2IP_Addr ( Bus2IP_Addr ),
		.Bus2IP_Data ( Bus2IP_Data ),
		.Bus2IP_RNW ( Bus2IP_RNW ),
		.Bus2IP_BE ( Bus2IP_BE ),
		.Bus2IP_Burst ( Bus2IP_Burst ),
		.Bus2IP_BurstLength ( Bus2IP_BurstLength ),
		.Bus2IP_CS ( Bus2IP_CS ),
		.Bus2IP_WrReq ( Bus2IP_WrReq ),
		.Bus2IP_RdReq ( Bus2IP_RdReq ),
		.Bus2IP_RdCE ( Bus2IP_RdCE ),

		.IP2Bus_MstRd_Req ( IP2Bus_MstRd_Req_i ),
		.IP2Bus_MstWr_Req ( IP2Bus_MstWr_Req_i ),
		.IP2Bus_Mst_Addr ( IP2Bus_Mst_Addr_i ),
		.IP2Bus_Mst_BE ( IP2Bus_Mst_BE_i ),
		.IP2Bus_Mst_Lock ( IP2Bus_Mst_Lock_i ),
		.IP2Bus_Mst_Reset ( IP2Bus_Mst_Reset_i ),
		.Bus2IP_Mst_CmdAck ( Bus2IP_Mst_CmdAck ),
		.Bus2IP_Mst_Cmplt ( Bus2IP_Mst_Cmplt ),
		.Bus2IP_Mst_Error ( Bus2IP_Mst_Error ),
		.Bus2IP_Mst_Rearbitrate ( Bus2IP_Mst_Rearbitrate ),
		.Bus2IP_Mst_Cmd_Timeout ( Bus2IP_Mst_Cmd_Timeout ),
		.Bus2IP_MstRd_d ( Bus2IP_MstRd_d ),
		.Bus2IP_MstRd_src_rdy_n ( Bus2IP_MstRd_src_rdy_n ),
		.IP2Bus_MstWr_d ( IP2Bus_MstWr_d_i ),
		.Bus2IP_MstWr_dst_rdy_n ( Bus2IP_MstWr_dst_rdy_n ),
		.DCR_Read ( DCR_Read_i ),
		.DCR_Write ( DCR_Write_i ),
		.DCR_ABus ( DCR_ABus_i ),
		.DCR_Sl_DBus ( DCR_Sl_DBus_i ),
		.Sl_dcrAck ( Sl_dcrAck ),
		.Sl_dcrDBus ( Sl_dcrDBus ),
		.Sl_dcrTimeoutWait ( Sl_dcrTimeoutWait )
	);
  // END USER CODE (Do not remove this line)

endmodule

