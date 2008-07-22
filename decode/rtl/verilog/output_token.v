/******************************************************************************
 *
 *           File Name : output_token.v
 *             Version : 0.1
 *                Date : Feb 21, 2008
 *         Description : LZS decode sub-module
 *        Dependencies : 
 * 
 *             Company : Beijing Soul
 *              Author : Chen Tong   
 * 
 ****************************************************************************/

module output_token(/*AUTOARG*/
   // Outputs
   out_data, out_valid, write_address, write_data,
   write_valid,
   // Inputs
   clk, rst, decode_result, result_valid
   );

   /* Local port */
   input clk;
   input rst;
   input [7:0] decode_result;
   input       result_valid;
   
   output [7:0] out_data;
   output 	out_valid;
   output [10:0] write_address;
   output [7:0]  write_data;
   output 	 write_valid;
   // End definition
   
   /*AUTOOUTPUT*/
   /*AUTOINPUT*/
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [7:0]		out_data;
   reg			out_valid;
   reg [10:0]		write_address;
   reg [7:0]		write_data;
   reg			write_valid;
   // End of automatics
   /*AUTOWIRE*/

   /* Local variable */
   reg [10:0] write_address_reg;
   // End definition

   always @(posedge clk or posedge rst) begin
      if (rst) begin
	 out_valid <= #1 0;
	 out_data <= #1 0;
      end else if (result_valid) begin
	 out_data <= #1 decode_result;
	 out_valid <= #1 1;
      end else begin
	 out_valid <= #1 0;
      end
   end
   
   always @(posedge clk or posedge rst) begin
      if (rst)
	write_address_reg <= #1 0;
      else if (result_valid)
	write_address_reg <= #1 write_address_reg + 1;
   end
   
   always @(posedge clk or posedge rst) begin
      if (rst) begin
	 write_valid <= #1 0;
	 write_data <= #1 0;
	 write_address <= #1 0;
      end else if (result_valid) begin
	 write_data <= #1 decode_result;
	 write_address <= #1 write_address_reg;
	 write_valid <= #1 1;   
      end else begin
	 write_valid <= #1 0;
      end
   end // always @ (posedge clk or posedge rst)
   
endmodule // output_token

 
