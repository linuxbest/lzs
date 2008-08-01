/******************************************************************************
 *   File Name :  tb_data.v
 *     Version :  0.1
 *        Date :  2008 02 26
 *  Description:
 * Dependencies:
 *
 *
 *      Company:  Beijing Soul
 *
 *          Bug:
 *
 *****************************************************************************/

module tb_data(/*AUTOARG*/
   // Outputs
   stream_valid, stream_data, stream_empty, fo_full, clk,
   ce_decode, rst,
   // Inputs
   stream_ack, stream_width
   );
   
   parameter LZF_FILE = "/home/kevin/lzf-hg.git/lzs/01.lzs";
   parameter LZF_WIDTH = 20;
   parameter LZF_SIZE  = 65536;
   parameter IN_WIDTH = 13;
   
   integer src_file , src_cnt;
   reg [15:0] left;
   reg [63:0] src_char;
   reg [15:0] temp;
   reg [LZF_WIDTH-1:0] src_size;

   output 	       stream_valid;
   output [IN_WIDTH-1:0]       stream_data;
   output 	       stream_empty;
   output 	       fo_full;
      
   input 	       stream_ack;
   input [3:0] 	       stream_width;

   output 	       clk;
   output 	       ce_decode;
   output 	       rst;
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			ce_decode;
   reg			clk;
   reg			fo_full;
   reg			rst;
   reg [IN_WIDTH-1:0]	stream_data;
   reg			stream_empty;
   reg			stream_valid;
   // End of automatics

   task getword;
      input [31:0] file;
      output [15:0] data;
      //integer       low, high;
      reg [7:0] low, high;
      begin	 
	 high = $fgetc(file);
	 low  = $fgetc(file);
	 
	 data = high << 8 | low;
      end
   endtask // getword
  
   reg [255:0] lzs_file;
   reg dummy;

   initial begin
      ce_decode  = 0;
      fo_full = 0;
      rst = 0;
     
      if (0 == $value$plusargs("LZS_FILE=%s", lzs_file))
        lzs_file = LZF_FILE;
      if (0 == $value$plusargs("LZS_SIZE=%d", src_size))
        src_size = LZF_SIZE;

      src_file = $fopen(lzs_file, "r");
      //$write("src_file %d, %s, %d\n", src_file, lzs_file, src_size);

      stream_valid = 0;
      stream_data  = 0;
      stream_empty = 0;
      left = 0;
      
      rst = 0;
      @(negedge clk);
      rst = 1;
      @(negedge clk);
      @(negedge clk);
      rst = 0;
      @(negedge clk);
      ce_decode = 1; 

      getword(src_file, temp);
      src_char[63:48] = temp;
      getword(src_file, temp);
      src_char[47:32] = temp;
      getword(src_file, temp);
      src_char[31:16] = temp;
      getword(src_file, temp);
      src_char[15:00] = temp;
      left = 64;
      stream_valid = 1;
            
      for (src_cnt = 2; src_cnt < src_size; dummy = 1) begin
	 stream_data = src_char[63:64-IN_WIDTH];
	 @(posedge clk);
	 if (stream_ack) begin
	    src_char = src_char << stream_width;
	    if (left - stream_width < 32) begin
	       getword(src_file, temp);
	       $write("data %h, left %d, used %d, %h, temp %h\n", 
                               src_char[63:64-IN_WIDTH], left, stream_width, 
                               src_char, temp);
	       src_char = src_char | (temp << (48 - left + stream_width));
	       left = left + 'd16;
	       src_cnt = src_cnt + 2;
	    end else begin
	       $write("data %h, left %d, used %d, %h, temp %h, %h\n", 
                               src_char[63:64-IN_WIDTH], left, stream_width, 
                               src_char, temp, src_char >> 3);
            end
	    left = left - stream_width;	    
	 end // if (stream_ack)
      end // for (src_cnt = 2;...
      
      stream_valid = 0;
      stream_empty = 1;
      @(negedge clk);
      
   end
   
   initial begin
      clk = 1'b0;
   end
   always #7.5 clk = !clk;

endmodule // tb_data   
// Local Variables:
// verilog-library-directories:("../src" ".")
// verilog-library-files:("")
// verilog-library-extensions:(".v" ".h")
// End:
