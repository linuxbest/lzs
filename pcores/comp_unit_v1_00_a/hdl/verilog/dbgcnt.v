module dbgcnt (
	input	clk,
	input [31:0] dbgcnt_in,
	input	glbl_en_in,
	input	rst_l,
	output	dbg_output
);

reg [13:0] cntr_ff;
reg	state_ff;

wire [13:0] cmp_val = (state_ff) ? dbgcnt_in[29:16] : dbgcnt_in[13:0];
wire	count_hi = (cntr_ff[13:0] >= cmp_val[13:0]);
wire	enable = dbgcnt_in[15] && glbl_en_in;

wire	state_pre = (count_hi) ? ~state_ff : state_ff;
wire	state = (enable) ? state_pre : 1'b0;

wire [13:0] cntr_inced = cntr_ff[13:0] + 14'h1;
wire [13:0] cntr = (enable && ~count_hi) ? cntr_inced[13:0] : 14'h0;

always @(posedge clk) begin
	cntr_ff[13:0] <= (rst_l) ? cntr[13:0] : 14'h0;
	state_ff <= (rst_l) ? state : 1'b0;
end

assign dbg_output = state_ff;
endmodule

