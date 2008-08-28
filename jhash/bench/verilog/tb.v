module top;
   reg clk = 1;
   always #1 clk = !clk;

   reg [31:0] k0, k1, k2, length;
   wire [31:0] x, y ,z;
   wire        done;
   reg 	       en;
   reg 	       rst;
   
   lookup3 T3(/*AUTOINST*/
	      // Outputs
	      .x			(x[31:0]),
	      .y			(y[31:0]),
	      .z			(z[31:0]),
	      .done			(done),
	      // Inputs
	      .k0			(k0[31:0]),
	      .k1			(k1[31:0]),
	      .k2			(k2[31:0]),
	      .clk			(clk),
	      .en			(en),
	      .rst			(rst),
	      .length			(length[31:0]));

   initial begin
      length = 32'h3;
      k0 = "aaaa";
      k1 = "bbbb";
      k2 = "cccc";
      
      #2 en = 0;
      #2 rst = 1;
      #2 rst = 0;
      #2 en = 1;
      $write("%h %h %h\n", k0, k1, k2);
      
      while (done == 0) begin
	 @(posedge clk);
	 $write("%h, %h, %h, %h\n", T3.OA, T3.OB, T3.OC, T3.round);
      end
      
      $finish;
   end
endmodule // top
