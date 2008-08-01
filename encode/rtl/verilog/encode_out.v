/******************************************************************************
 *   File Name :  encode_out.v
 *     Version :  0.1
 *        Date :  2008 02 27
 *  Description:  encode output module
 * Dependencies:
 *
 *
 *      Company:  Beijing Soul
 *
 *          BUG:
 *
 *****************************************************************************/
module encode_out(/*AUTOARG*/
   // Outputs
   data_o, valid_o, done_o,
   // Inputs
   clk, rst, ce, cnt_output_enable, cnt_finish, cnt_output,
   cnt_len
   );
   input clk, rst, ce;
   
   input cnt_output_enable, cnt_finish;
   input [12:0] cnt_output;
   input [3:0] cnt_len;

   /* output */
   output [15:0] data_o;
   output 	 valid_o;
   output 	 done_o;

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [15:0]		data_o;
   reg			done_o;
   reg			valid_o;
   // End of automatics
   
   reg [3:0] 		din_len;
   reg [12:0] 		din_data;
   reg 			din_valid;
   always @(/*AS*/cnt_len or cnt_output or cnt_output_enable)
     begin
	/* if the end mark output done, stop drive the output data */
	din_len = cnt_len;
	din_data = cnt_output;
	din_valid = cnt_output_enable;
     end // always @ (...

   reg 			state, state_next;
   reg [3:0] 		cnt, cnt_next;
   reg [29:0] 		sreg; /* 13 + 15 = 28 */
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  sreg <= #1 0;
	else if (din_valid)
	  sreg <= #1 (sreg << din_len) | din_data;
     end
   
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  state <= #1 0;
	else
	  state <= #1 state_next;
     end

   always @(posedge clk or posedge rst) 
     begin
	if (rst)
	  cnt <= #1 0;
	else
	  cnt <= #1 cnt_next;
     end  

   always @(/*AS*/cnt or din_len or din_valid)
     begin
	state_next = 0;
	cnt_next = cnt;
	
	if (din_valid)
	  {state_next, cnt_next} = cnt + din_len;
     end // always @ (...

   
   always @(posedge clk)
     begin
	data_o <= #1 sreg >> cnt;
     end
   
   always @(posedge clk)
     valid_o <= #1 state;
   
   always @(posedge clk)
     if (cnt_finish && state == 0 && state == 0)
       done_o <= #1 1'b1;
     else
       done_o <= #1 1'b0;
   
endmodule // encode_out

// Local Variables:
// verilog-library-directories:("." "../../rtl/verilog/")
// verilog-library-files:("")
// verilog-library-extensions:(".v" ".h")
// End:
