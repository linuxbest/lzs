/******************************************************************************
 *
 *         File Name : copy_ref.v
 *           Version : 0.1
 *              Date : Feb 21, 2008
 *       Description : LZS decode sub-module
 *      Dependencies :
 * 
 *           Company : Beijing Soul
 *            Author : Chen Tong
 * 
 *****************************************************************************/

module copy_ref(/*AUTOARG*/
   // Outputs
   decode_result, result_valid, read_address, copy_ref_end,
   // Inputs
   clk, rst, current_state, offset, offset_valid,
   write_address, length, length_valid, length_nostream,
   copy_15_valid, read_data, fo_full, all_end
   );
   
   parameter LENGTH_WIDTH = 16;
   parameter OFFSET_WIDTH = 12;
   
   parameter [2:0] 
		OFULL = 3'b110,
		WAIT = 3'b011;
   
   /* Local port */
   input     clk;
   input     rst;
   input [2:0] current_state;
   input [OFFSET_WIDTH-1:0] offset;
   input 		    offset_valid;
   input [10:0] 	    write_address; 
   input [LENGTH_WIDTH-1:0] length;
   input 		    length_valid;
   input 		    length_nostream; // == 1 indicate stream pause
   input 		    copy_15_valid;
   input [7:0] 		    read_data;
   input 		    fo_full;
   input 		    all_end;
   
   output [7:0] 	    decode_result;
   output 		    result_valid;
   output [10:0] 	    read_address;
   output 		    copy_ref_end;
   // End definition
   
   /*AUTOOUTPUT*/
   /*AUTOINPUT*/
   /*AUTOWIRE*/
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			copy_ref_end;
   reg [10:0]		read_address;
   // End of automatics
   
   /* Local variable */
   reg [LENGTH_WIDTH:0]     copy_num;
   reg [LENGTH_WIDTH-1:0]   pre_num;
   
   assign 		    decode_result = (!copy_ref_end) ? 
					    read_data : {8{'hz}};
   reg 			    result_valid_reg;
   assign 		    result_valid  = (!copy_ref_end) ? 
					    result_valid_reg : 1'bz;
   
   reg [10:0] 		    read_address_reg;
   reg [3:0] 		    long_len_num;
   reg 			    same_one_data;
   reg 			    same_two_data;
   reg 			    same_two_data_valid;
   reg 			    read_valid;
   // End definition

   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  copy_ref_end <= #1 1;
	else if (offset_valid && offset != 0)
	  copy_ref_end <= #1 0;
	else if (copy_num == 0)
	  copy_ref_end <= #1 1;
     end
   
   always @ (posedge clk or posedge rst) 
     begin
	if (rst)
	  read_address_reg<= #1 0;
	else if (offset_valid) // init value of read address to history
	  read_address_reg <= #1 write_address + 1 - offset;
	else if (!copy_ref_end && !same_one_data && !fo_full &&
		 (!length_nostream || (long_len_num > 0)))
	  read_address_reg <= #1 same_two_data ? 
			      read_address_reg - 1 : read_address_reg + 1;
     end
   
   always @ (posedge clk or posedge rst) 
     begin
	if (rst) begin
	   read_valid <= #1 0;
	   read_address <= #1 0;
	end else if (!copy_ref_end && copy_num != 0 && !fo_full &&
		     (!length_nostream || (long_len_num > 0))) begin
	   read_address <= #1 read_address_reg;
	   read_valid <= #1 1; // read address to history ram valid
	end else
	  read_valid <= #1 0;
     end
   
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  result_valid_reg <= #1 0;
	else if (read_valid)
	  result_valid_reg <= #1 1;
	else
	  result_valid_reg <= #1 0;
     end
   
   always @ (posedge clk or posedge rst)
     begin 
	if (rst)
	  same_one_data <= #1 0;
	else if (offset == 1) // indicate copy 1 data for length times
	  same_one_data <= #1 1;
	else if (copy_ref_end)
	  same_one_data <= #1 0;
     end

   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  same_two_data_valid <= #1 0;
	else if (offset == 2) // indicate copy 2 datas for length/2 times
	  same_two_data_valid <= #1 1;
	else if (copy_ref_end)
	  same_two_data_valid <= #1 0;	
     end
   
   always @ (posedge clk or posedge rst)
     begin
	if (rst)
	  same_two_data <= #1 0;
	else if (copy_ref_end)
	  same_two_data <= #1 0;
	else if (same_two_data_valid && !copy_ref_end && !fo_full &&
		 (!length_nostream || (long_len_num > 0)))
	  same_two_data <= #1 same_two_data + 1;
     end
   
   always @ (posedge clk or posedge rst) 
     begin
	if (rst)
	  long_len_num <= #1 0;
	else if (copy_15_valid) 
	  // indicate copy 15 datas because length > this 15
	  long_len_num <= #1 15;
	else if (long_len_num > 0 && !fo_full)
	  long_len_num <= #1 long_len_num - 1;
     end
   
   always @ (posedge clk or posedge rst) 
     begin // prem_num indicate copy data numbers before length valid
	if (rst)
	  pre_num <= #1 0;
	else if (offset_valid)
	  pre_num <= #1 0;
	else if (!copy_ref_end && !fo_full &&
		 (!length_nostream || (long_len_num > 0)))
	  pre_num <= #1 pre_num + 1;
     end
   
   always @ (posedge clk or posedge rst) 
     begin
	if (rst)
	  copy_num <= #1 {LENGTH_WIDTH+1{1'b1}};
	else if (offset_valid)
	  copy_num <= #1 {LENGTH_WIDTH+1{1'b1}};
	else if (length_valid) 
	  // the number of will copy from history after length valid
	  if (fo_full && current_state == WAIT)
	    copy_num <= #1 length - pre_num + 1;
	  else
	    copy_num <= #1 length - pre_num;
	else if (!copy_ref_end && copy_num != 0 && !fo_full && 
		 (!length_nostream || (long_len_num > 0)) &&
		 current_state != OFULL)
	  copy_num <= #1 copy_num - 1;
     end
   
endmodule // copy_ref

