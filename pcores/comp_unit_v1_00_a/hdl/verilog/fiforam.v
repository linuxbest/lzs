module fiforam (
	input	clk,
	input	we,
	input [8:0] addr0,
	input [8:0] addr1,
	input [35:0] wr_data0,
	output [35:0] rd_data1
);

defparam ram.SRVAL_A = 36'h00000000;

wire [35:0] rd_data0;

RAMB16_S36_S36 ram (
	.CLKA(clk),
	.DIA(wr_data0[31:0]),
	.DIPA(wr_data0[35:32]),
	.ADDRA(addr0[8:0]),
	.WEA(we),
	.ENA(1'b1),
	.SSRA(1'b0),
	.DOA(rd_data0[31:0]),
	.DOPA(rd_data0[35:32]),

	.CLKB(clk),
	.DIB(32'h0),
	.DIPB(4'h0),
	.ADDRB(addr1[8:0]),
	.WEB(1'b0),
	.ENB(1'b1),
	.SSRB(1'b0),
	.DOB(rd_data1[31:0]),
	.DOPB(rd_data1[35:32])
);

endmodule

