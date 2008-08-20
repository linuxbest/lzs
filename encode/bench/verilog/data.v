/******************************************************************************
 *   File Name :  data.v
 *     Version :  0.1
 *        Date :  2008 02 27
 *  Description:  data source module
 * Dependencies:
 *
 *
 *      Company:  Beijing Soul
 *
 *          BUG:
 *
 *****************************************************************************/

module data(/*AUTOARG*/
   // Outputs
   clk, rst, src_empty, ce, fo_full, m_last, fi, fi_cnt,
   // Inputs
   m_src_getn, m_endn
   );
   parameter LZF_WIDTH = 20;
   parameter LZF_SIZE  = 512;
   parameter LZF_FILE  = "../../../../files/01";
   //parameter LZF_FILE  = "../../../../files/texbook.pdf";
   parameter LZF_DEBUG = 1;
   parameter LZF_DELAY = 20;
   parameter LZF_FIFO_AW = 5;
   
   /* output parts */
   output    clk, rst, src_empty, ce, fo_full, m_last;
   output [63:0] fi;
   output [LZF_WIDTH-1:0] fi_cnt;

   wire 		  m_last;
   reg			clk = 1'b1;
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			ce;
   reg [LZF_WIDTH-1:0]	fi_cnt;
   reg			fo_full;
   reg			rst;
   reg			src_empty;
   // End of automatics
   
   input 	 m_src_getn, m_endn;
   reg 		 src_clr, src_we;
   wire 	 src_FIFO_full, src_FIFO_empty, 
		 src_FIFO_emptyN, src_FIFO_fullN;
   reg [63:0] 	 src_din;
   wire [63:0] 	 fi;

   wire [LZF_FIFO_AW-1:0] src_waddr, src_raddr;
   wire 		  src_rallow, src_wallow;

   reg 			  src_last;
   
   fifo_control #(.ADDR_LENGTH(LZF_FIFO_AW))
     src_FIFO (.rclock_in(clk),
	       .wclock_in(clk),
	       .renable_in(!m_src_getn),
	       .wenable_in(src_we),
	       .reset_in(rst),
	       .clear_in(rst),
	       .almost_empty_out(src_FIFO_emptyN),
	       .almost_full_out(src_FIFO_fullN),
	       .empty_out(src_FIFO_empty),
	       .waddr_out(src_waddr),
	       .raddr_out(src_raddr),
	       .rallow_out(src_rallow),
	       .wallow_out(src_wallow),
	       .full_out(src_FIFO_full));

   tpram #(.aw(LZF_FIFO_AW), .dw(65))
	src_mem (.clk_a(clk),
		 .rst_a(rst),
		 .ce_a(1'b1),
		 .we_a(src_wallow),
		 .addr_a(src_waddr),
		 .di_a({src_last, src_din}),
		 .do_a(),
		 .oe_a(1'b1),
		 
		 .clk_b(clk),
		 .rst_b(rst),
		 .ce_b(1'b1),
		 .we_b(1'b0),
		 .oe_b(1'b1),
		 .addr_b(src_raddr),
		 .do_b({m_last, fi}),
		 .di_b(0));

   always @(/*AS*/src_FIFO_empty or src_FIFO_emptyN)
     if (src_FIFO_emptyN == 0 && src_FIFO_empty == 0)
       src_empty = 0;
     else
       src_empty = 1;

   reg [63:0] 	 mem[65535:0];
   
   reg [7:0] 	 char;
   integer 	 i, f, j, k;
   
   initial begin
      ce = 0;
      rst = 0;
      
      src_clr = 0;
      src_din = 0;
      src_we  = 0;
      j = 0;
      if (0 == $value$plusargs("size=%d", fi_cnt))
       fi_cnt = LZF_SIZE;
      $write("size is %h\n", fi_cnt);
      fo_full = 0;
      src_last  = 0;
      
      /* read the memory */
      f = $fopen(LZF_FILE, "r");
      for (i = 0; i < fi_cnt ; i = i + 8) begin
	 src_din[07:00] = $fgetc(f);
	 src_din[15:08] = $fgetc(f);
	 src_din[23:16] = $fgetc(f);
	 src_din[31:24] = $fgetc(f);
	 src_din[39:32] = $fgetc(f);
	 src_din[47:40] = $fgetc(f);
	 src_din[55:48] = $fgetc(f);
	 src_din[63:56] = $fgetc(f);
	 mem[j] = src_din;
	 j = j + 1;
      end

      /* reset */
      @(negedge clk);
      rst = 1;
      @(negedge clk);
      @(negedge clk);
      @(negedge clk);
      @(negedge clk);
      rst = 0;
      @(negedge clk);
      ce = 1;

      for (i = 0; i < j; f = f + 1/*loop*/) begin
	 if (src_empty && src_we == 0) begin
	    for (k = 0; k < LZF_DELAY; k = k + 1) begin
	       @(negedge clk);
	    end
	    src_we = 1;
	 end else if (src_FIFO_fullN) begin
	    src_we = 0;
	 end
	 src_din = mem[i];
	 if (src_we) begin
	    if (LZF_DEBUG) $write("%h:%h, %h\n", i, src_din, j);
	    i = i + 1;
	 end
	 @(negedge clk);
      end
      src_we = 0;

      @(negedge clk);
      src_last = 1'b1;
      src_we   = 1'b1;
      @(negedge clk);

      wait (!m_endn)
	$finish;
   end

   always #7.5 clk = !clk;
endmodule // data

// Local Variables:
// verilog-library-directories:("." "../../common/")
// verilog-library-files:("")
// verilog-library-extensions:(".v" ".h")
// End:
