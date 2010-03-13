/******************************************************************************
 *
 *           File Name : decode.v
 *             Version : 0.1
 *                Date : Feb 20, 2008
 *         Description : LZS decode algorithm output
 *        Dependencies :
 * 
 *             Company : Beijing Soul
 *              Author : Hu Gang
 * 
 *****************************************************************************/
module decode_out (/*AUTOARG*/
   // Outputs
   data_o, valid_o, done_o,
   // Inputs
   clk, rst, out_valid, out_done, out_data
   );
   input clk,
	 rst;

   input out_valid, out_done;
   input [7:0] out_data;

   output [15:0] data_o;
   output 	 valid_o, done_o;

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [15:0]		data_o;
   reg			done_o;
   reg			valid_o;
   // End of automatics

   reg  		cnt;
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  cnt <= #1 1'b0;
	else if (out_valid)
	  cnt <= #1 cnt + 1'b1;
     end

   always @(posedge clk)
     begin
	if (~cnt && out_valid)
	  data_o[7:0] <= #1 out_data;
     end

   always @(posedge clk)
     begin
	if (cnt && out_valid)
	  data_o[15:8] <= #1 out_data;
     end

   always @(posedge clk)
     begin
	if ((&cnt) && out_valid)
	  valid_o <= #1 1'b1;
	else
	  valid_o <= #1 1'b0;
     end
   
   always @(posedge clk)
	done_o <=  #1 out_done;
   
endmodule // decode_out
