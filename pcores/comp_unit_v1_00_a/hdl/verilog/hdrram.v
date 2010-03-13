module hdrram (
	input	clk,
	input [3:0] addr0,
	input	we,
	input [31:0] data0_in,
	input [3:0] addr1,
	output [31:0] data1_out
);

wire [31:0] dummy;

RAM16X1D ram16x1_0 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[0]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[0]), .DPO(data1_out[0])
);
RAM16X1D ram16x1_1 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[1]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[1]), .DPO(data1_out[1])
);
RAM16X1D ram16x1_2 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[2]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[2]), .DPO(data1_out[2])
);
RAM16X1D ram16x1_3 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[3]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[3]), .DPO(data1_out[3])
);
RAM16X1D ram16x1_4 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[4]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[4]), .DPO(data1_out[4])
);
RAM16X1D ram16x1_5 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[5]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[5]), .DPO(data1_out[5])
);
RAM16X1D ram16x1_6 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[6]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[6]), .DPO(data1_out[6])
);
RAM16X1D ram16x1_7 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[7]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[7]), .DPO(data1_out[7])
);
RAM16X1D ram16x1_8 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[8]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[8]), .DPO(data1_out[8])
);
RAM16X1D ram16x1_9 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[9]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[9]), .DPO(data1_out[9])
);
RAM16X1D ram16x1_10 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[10]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[10]), .DPO(data1_out[10])
);
RAM16X1D ram16x1_11 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[11]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[11]), .DPO(data1_out[11])
);
RAM16X1D ram16x1_12 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[12]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[12]), .DPO(data1_out[12])
);
RAM16X1D ram16x1_13 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[13]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[13]), .DPO(data1_out[13])
);
RAM16X1D ram16x1_14 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[14]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[14]), .DPO(data1_out[14])
);
RAM16X1D ram16x1_15 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[15]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[15]), .DPO(data1_out[15])
);
RAM16X1D ram16x1_16 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[16]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[16]), .DPO(data1_out[16])
);
RAM16X1D ram16x1_17 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[17]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[17]), .DPO(data1_out[17])
);
RAM16X1D ram16x1_18 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[18]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[18]), .DPO(data1_out[18])
);
RAM16X1D ram16x1_19 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[19]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[19]), .DPO(data1_out[19])
);
RAM16X1D ram16x1_20 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[20]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[20]), .DPO(data1_out[20])
);
RAM16X1D ram16x1_21 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[21]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[21]), .DPO(data1_out[21])
);
RAM16X1D ram16x1_22 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[22]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[22]), .DPO(data1_out[22])
);
RAM16X1D ram16x1_23 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[23]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[23]), .DPO(data1_out[23])
);
RAM16X1D ram16x1_24 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[24]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[24]), .DPO(data1_out[24])
);
RAM16X1D ram16x1_25 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[25]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[25]), .DPO(data1_out[25])
);
RAM16X1D ram16x1_26 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[26]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[26]), .DPO(data1_out[26])
);
RAM16X1D ram16x1_27 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[27]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[27]), .DPO(data1_out[27])
);
RAM16X1D ram16x1_28 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[28]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[28]), .DPO(data1_out[28])
);
RAM16X1D ram16x1_29 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[29]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[29]), .DPO(data1_out[29])
);
RAM16X1D ram16x1_30 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[30]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[30]), .DPO(data1_out[30])
);
RAM16X1D ram16x1_31 (
  .A0(addr0[0]), .A1(addr0[1]), .A2(addr0[2]), .A3(addr0[3]),
  .D(data0_in[31]), .WCLK(clk), .WE(we),
  .DPRA0(addr1[0]), .DPRA1(addr1[1]), .DPRA2(addr1[2]),
  .DPRA3(addr1[3]),
  .SPO(dummy[31]), .DPO(data1_out[31])
);

endmodule
