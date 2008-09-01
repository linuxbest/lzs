module mix(/*AUTOARG*/
   // Outputs
   OA, OB, OC,
   // Inputs
   a, b, c, clk, shift
   );

   input [31:0] a, b, c;
   output [31:0] OA, OB, OC;
   input         clk;
   input [4:0] 	 shift;

   assign        OA = (a - c) ^ ( (c << shift) | (c >> (32 - shift)) );
   assign        OC = c + b;
   assign        OB = b;
endmodule // mix
