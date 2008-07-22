/******************************************************************************
 *
 *          File Name : history_ram.v
 *            Version : 0.1
 *               Date : Feb 21, 2008
 *        Description : dual port ram for LZS decode
 *       Dependencies :
 * 
 *            Company : Beijing Soul
 *             Author : Chen Tong
 *
 *****************************************************************************/

module history_ram ( /*AUTOARG*/
   // Outputs
   read_data,
   // Inputs
   clk, read_address, write_address, write_data,
   write_valid
   );
   
   /*AUTOOUTPUT*/
   /*AUTOINPUT*/
   /*AUTOREG*/
   /*AUTOWIRE*/
   
   /* Local port */   
   input     clk;
   input [10:0] read_address;
   input [10:0] write_address;
   input [7:0]     write_data;
   input 		     write_valid;
   
   output [7:0]    read_data;
   // End definition
   
   /* Local variable */
   reg [7:0] 	   mem [(1<<11)-1:0];
   reg [10:0] 	   read_add;
   // End definition
   
   always @(posedge clk)
     begin
	if (write_valid)
	  mem[write_address] <= #1 write_data;
	read_add <= #1 read_address;
     end

   assign read_data = mem[read_add];
   
endmodule   
