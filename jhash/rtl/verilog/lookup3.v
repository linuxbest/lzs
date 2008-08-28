module mix(/*AUTOARG*/
   // Outputs
   OA, OB, OC,
   // Inputs
   a, b, c, clk, shift
   );
   input [31:0] a, b, c;
   output [31:0] OA, OB, OC;
   input 	 clk;
   input [4:0] 	 shift;
   
   assign 	 OA = (a - c) ^ ( (c << shift) | (c >> (32 - shift)) );
   assign 	 OC = c + b;
   assign 	 OB = b;
   
endmodule

module lookup3(/*AUTOARG*/
   // Outputs
   x, y, z, done,
   // Inputs
   k0, k1, k2, clk, en, rst, length
   );
   output [31:0] x, y, z;
   output 	 done;
   
   input [31:0]  k0, k1, k2;
   input 	 clk;
   input 	 en;
   input 	 rst;
   
   reg [31:0] 	 x, y, z;
   reg [4:0] 	 shift;

   wire [31:0] 	 OA, OB, OC;
   reg [31:0] 	 a, b, c;
   
   mix M0(/*AUTOINST*/
	  // Outputs
	  .OA				(OA[31:0]),
	  .OB				(OB[31:0]),
	  .OC				(OC[31:0]),
	  // Inputs
	  .a				(a[31:0]),
	  .b				(b[31:0]),
	  .c				(c[31:0]),
	  .clk				(clk),
	  .shift			(shift[4:0]));

   reg [2:0] 	 round;
   always @(posedge clk)
     if (rst)
       round <= #1 0;
     else if (en)
       round <= #1 round + 1;

   input [31:0]  length;
   wire [31:0] 	 length_val = (length << 2) + 32'hdeadbeef;
   
   always @(posedge clk)
     if (en) 
       case (round)
	 /* a -= c;  a ^= rot(c, 4);  c += b; */
	 0: begin
	    a <= #1 k0 + length_val;
	    b <= #1 k1 + length_val;
	    c <= #1 k2 + length_val;
	    shift <= #1 4;
	 end
	 
	 /* b -= a;  b ^= rot(a, 6);  a += c; */
	 1: begin /* DONE */
	    a <= #1 OB /* b */;
	    b <= #1 OC /* c */;
	    c <= #1 OA /* a */;
	    shift <= #1 6;
	 end
	 
	 /* c -= b;  c ^= rot(b, 8);  b += a; */
	 2: begin
	    a <= #1 OB /* c */;
	    b <= #1 OC /* a */;
	    c <= #1 OA /* b */;
	    shift <= #1 8;
	 end
	 /* a -= c;  a ^= rot(c,16);  c += b; */
	 3: begin
	    a <= #1 OB/* a */;
	    b <= #1 OC/* b */;
	    c <= #1 OA/* c */;
	    shift <= #1 16;
	 end
	 /*  b -= a;  b ^= rot(a,19);  a += c */
	 4: begin
	    a <= #1 OB/* b */;
	    b <= #1 OC/* c */;
	    c <= #1 OA/* a */;
	    shift <= #1 19;
	 end
	 /* c -= b;  c ^= rot(b, 4);  b += a; */
	 5: begin
	    a <= #1 OB/* c */;
	    b <= #1 OC/* a */;
	    c <= #1 OA/* b */;
	    shift <= #1 4;
	 end
       endcase
   
   always @(posedge clk)
     if (round == 6) begin
	x <= #1 OA;
	y <= #1 OB;
	z <= #1 OC;
     end
   
   assign done = round == 7;
   
endmodule // lookup3   