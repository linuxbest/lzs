/******************************************************************************
 *   File Name :  encode_ctl.v
 *     Version :  0.1
 *        Date :  2008 02 27
 *  Description:  encode control module
 * Dependencies:
 *
 *
 *      Company:  Beijing Soul
 *
 *          BUG: 
 *
 *****************************************************************************/
module encode_ctl(/*AUTOARG*/
   // Outputs
   hraddr, cnt_output_enable, cnt_len, cnt_output,
   cnt_finish,
   // Inputs
   clk, rst, data_valid, data_empty, hash_data, hash_data1,
   data_d1, data_d2, hash_ref, iidx, hdata, data, hash_d1,
   hash_data_d1
   );
   parameter LZF_WIDTH = 20;

   input     clk, rst;
   input     data_valid;
   input     data_empty;
   
   input [7:0] hash_data, hash_data1, data_d1, data_d2;
   input [LZF_WIDTH-1:0] hash_ref, iidx;
   
   input [7:0] 		 hdata, data, hash_d1;
   output [10:0] 	 hraddr;
   input 		 hash_data_d1;
   
   /*AUTOREG*/

   reg 			off_valid;
   reg 			iidx_window;
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  iidx_window <= #1 0;
	else if (iidx == 2048)
	  iidx_window <= #1 1;
     end
   
   reg [LZF_WIDTH-1:0] 	min_off, max_off;
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  min_off <= #1 0;
	else if (data_valid && iidx_window)
	  min_off <= #1 min_off + 1;
     end

   always @(posedge clk)
     begin
	if (data_valid)
	  max_off <= #1 iidx;
     end
   
   always @(/*AS*/hash_ref or max_off or min_off)
     begin
	if (hash_ref > min_off && hash_ref < max_off)
	  off_valid = 1;
	else
	  off_valid = 0;
     end

   reg [10:0] off;
   always @(/*AS*/hash_ref or max_off)
     begin
	off = max_off - hash_ref;
     end
   
   parameter [3:0]
		S_IDLE   = 4'h0,
		S_SEARCH = 4'h1,
		S_TR     = 4'h2,
		S_MATCH  = 4'h3,
		S_DELAY  = 4'h4,
		S_END    = 4'h5,
		S_DONE   = 4'h6,
		S_STOP   = 4'h7;

   reg [3:0] 	  state, state_next;
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  state <= #1 S_IDLE;
	else
	  state <= #1 state_next;
     end

   reg [3:0] cnt, cnt_next;
   always @(posedge clk)
     begin
	  cnt <= #1 cnt_next;
     end

   reg cnt_count, cnt_load;
   reg rallow;
   reg [10:0] raddr_plus_one;
   reg [10:0] raddr_reg;
   
   assign hraddr = rallow ? raddr_plus_one : raddr_reg;
   
   always @(/*AS*/cnt_count or cnt_load)
     begin
	if (cnt_load || cnt_count)
	  rallow = 1;
	else
	  rallow = 0;
     end

   reg [LZF_WIDTH-1:0] hash_ref_plus_one;
   always @(/*AS*/hash_ref)
     hash_ref_plus_one = hash_ref + 1'b1;
   
   always @(posedge clk)
     begin
	if (cnt_load)
	  raddr_plus_one <= #1 hash_ref_plus_one + 1'b1;
	else if (cnt_count)
	  raddr_plus_one <= #1 raddr_plus_one + 1'b1;
     end

   always @(posedge clk)
     begin
	if (cnt_load)
	  raddr_reg <= #1 hash_ref_plus_one;
	else if (cnt_count)
	  raddr_reg <= #1 raddr_plus_one;
     end
   
   reg cnt_big7, cnt_big7_next;
   always @(posedge clk)
     begin
	  cnt_big7 <= #1 cnt_big7_next;
     end
   

   always @(/*AS*/cnt or cnt_big7 or cnt_count or cnt_load)
     begin
	cnt_next = 0;
	cnt_big7_next = 0;
	
	if (cnt_load) begin
	   cnt_next = 2;
	   cnt_big7_next = 0;
	end else if (cnt_count) begin
	   cnt_next = cnt + 1;
	   if (cnt_big7 == 0) begin
	      if (cnt == 4'h7) begin
		 cnt_big7_next = 1;
		 cnt_next = 0;
	      end else
		cnt_big7_next = 0;
	   end else begin
	      cnt_big7_next = 1;
	   end
	   if (cnt == 4'hf)
	     cnt_next = 1;
	end else begin
	   cnt_next = cnt;
	   cnt_big7_next = cnt_big7;
	end
     end // always @ (...

   output cnt_output_enable;
   output [3:0] cnt_len;
   output [12:0] cnt_output;
   output 	 cnt_finish;

   reg [2:0] 	 dummy_cnt;
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  dummy_cnt <= #1 0;
	else if (state == S_DONE)
	  dummy_cnt <= #1 dummy_cnt + 1'b1;
     end
   
   reg 		 cnt_finish;
   reg 		 cnt_output_enable, cnt_output_enable_next;
   reg [12:0] 	 cnt_output, cnt_output_next;
   reg [3:0] 	 cnt_len, cnt_len_next;
   
   always @(/*AS*/cnt or cnt_big7 or data_d1 or data_d2
	    or data_empty or data_valid or dummy_cnt
	    or hash_data or hash_data_d1 or hdata
	    or off_valid or state)
     begin
	state_next = S_IDLE;         // state
	cnt_output_enable_next = 0;  // will output the length data
	cnt_load = 0;
	cnt_count = 0;

	case (state)
	  S_IDLE: begin
	     if (data_valid) 
	       state_next = S_DELAY;
	     else
	       state_next = S_IDLE;
	  end

	  S_DELAY: begin
	     if (data_valid) 
	       state_next = S_SEARCH;
	     else
	       state_next = S_DELAY;
	  end
	  
	  S_SEARCH: begin /* cmp d2 with hash data */
	     if (data_valid) begin
		if (data_d2 == hash_data && off_valid) begin
		   state_next = S_TR;
		   cnt_load = 1;
		   cnt_output_enable_next = 1;
		end else begin
		   cnt_output_enable_next = 1;
		   state_next = S_SEARCH;
		end
	     end else if (data_empty) begin
		cnt_output_enable_next = 1;
		state_next = S_END;
	     end else
	       state_next = S_SEARCH;
	  end // case: S_SEARCH
	  
	  S_TR: begin // driver the history memory 
	     if (data_valid && hash_data_d1) begin
		cnt_count = 1;
		state_next = S_MATCH;
	     end else if (data_valid) begin
		state_next = S_SEARCH;
		cnt_output_enable_next = 1;
	     end else if (data_empty) begin
		cnt_output_enable_next = 1;
		state_next = S_END;
	     end else begin
		state_next = S_TR;
	     end
	  end
	  
	  S_MATCH: begin /* cmp d2 with history */
	     if (data_valid) begin
		if (data_d1 == hdata) begin
		   state_next = S_MATCH;
		   cnt_count = 1;
		   if (cnt == 4'h7 && cnt_big7 == 0)
		     cnt_output_enable_next = 1;
		   else if (cnt == 4'hf)
		     cnt_output_enable_next = 1;
		end else begin // if (prev_data == history_do)
		   state_next = S_SEARCH;
		   cnt_output_enable_next = 1;
		end
	     end else if (data_empty) begin // if (stream_valid)
		state_next = S_END;
		cnt_output_enable_next = 1;
	     end else 
		state_next = S_MATCH;
	  end // case: S_MATCH
	  
	  S_END: begin /* output end mark */
	     state_next = S_DONE;
	     cnt_output_enable_next = 1;
	  end

	  S_DONE: begin /* output fake data */
	     state_next = S_DONE;
	     cnt_output_enable_next = 1;
	     if (&dummy_cnt) /* 4 X F = 64 */
	       state_next = S_STOP;
	  end

	  S_STOP: begin
	     state_next = S_STOP;
	  end
	endcase // case(state)
     end // always @ (...

   always @(posedge clk)
     begin
	cnt_output <= #1 cnt_output_next;
	cnt_len    <= #1 cnt_len_next;
     end
   
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  cnt_output_enable <= #1 0;
	else
	  cnt_output_enable <= #1 cnt_output_enable_next;
     end

   always @(/*AS*/state)
     cnt_finish = state == S_STOP;
   
   /* state == S_SEARCH lit char with offset */
   reg [3:0] encode_len_s;
   reg [12:0] encode_data_s;
   /* state == S_MATCH */
   reg [3:0]  encode_len_m;
   reg [12:0] encode_data_m;
   /* length package */
   reg [3:0]  encode_len;
   reg [12:0] encode_data;
   
   always @(/*AS*/cnt_output_enable_next or encode_data_m
	    or encode_data_s or encode_len_m or encode_len_s
	    or state)
     begin
	cnt_output_next = 0;
	cnt_len_next= 0;
	
	if (cnt_output_enable_next && state == S_SEARCH) begin
	   /* output offset and liter data */
	   cnt_output_next = encode_data_s;
	   cnt_len_next = encode_len_s;
	end else if (cnt_output_enable_next && state == S_END) begin
	   /* output end marker */
	   cnt_output_next = 9'b110000000;
	   cnt_len_next    = 4'h9;
	end else if (cnt_output_enable_next && state == S_DONE) begin
	   /* output flush data */
	   cnt_output_next = 9'b000000000;
	   cnt_len_next    = 4'hf;
	end else begin
	   cnt_output_next = encode_data_m;
	   cnt_len_next = encode_len_m;
	end
     end // always @ (...
   
   always @(/*AS*/cnt or cnt_big7 or cnt_count
	    or encode_data or encode_len)
     begin
	if (cnt_big7 == 0) begin
	   if (cnt_count) begin
	      encode_data_m = 4'hf;
	      encode_len_m = 4'h4;
	   end else begin
	      encode_data_m = encode_data;
	      encode_len_m = encode_len;
	   end
	end else begin
	   if (cnt == 4'hf && cnt_count == 0) begin
	      encode_data_m = {4'hf, 4'h0};
	      encode_len_m = 4'h8;
	   end else begin
	      encode_data_m = cnt;
	      encode_len_m = 4'h4;
	   end
	end // else: !if(cnt_big7 == 0)
     end
   
   always @(/*AS*/cnt_load or data_d2 or off)
     begin
	encode_len_s = 0;
	encode_data_s = 0;

	if (cnt_load) begin /* offset */
	   if (off[10:07] == 0) begin /* < 128 */
	      encode_len_s = 4'h9;
	      encode_data_s = {2'b11, off[6:0]};
	   end else begin
	      encode_len_s = 4'hd;
	      encode_data_s = {2'b10, off[10:0]};
	   end
	end else begin
	   encode_len_s = 4'h9;
	   encode_data_s = data_d2;
	end // else: !if(cnt_load)
     end
   
   always @(/*AS*/cnt)
     begin
	encode_len = 0;
	encode_data = 0;
	
	case (cnt[2:0])
	  3'h2: {encode_data, encode_len} = {2'b00, 4'h2};
	  3'h3: {encode_data, encode_len} = {2'b01, 4'h2};
	  3'h4: {encode_data, encode_len} = {2'b10, 4'h2};
	  3'h5: {encode_data, encode_len} = {2'b11, 2'b00, 4'h4};
	  3'h6: {encode_data, encode_len} = {2'b11, 2'b01, 4'h4};
	  3'h7: {encode_data, encode_len} = {2'b11, 2'b10, 4'h4};
	endcase
     end // always @ (...
   
   /* 
    * cnt_output_enable
    * cnt_big7
    * cnt
    * 
    *   big7  finish 
    *    0     1      <= 7 output encode(data/_len)
    *    1     1      >  7 output 4 bit cnt
    *    1     0      if big7==0 && cnt==7+1 output 4'hf and set big7=1
    *                 then big7==1 && cnt=4'hf output 4'hf
    * 
    */
endmodule // encode_ctl
// Local Variables:
// verilog-library-directories:("." "../../../../common/" "../../encode/src" "../../encode_ctl/src/" "../../encode_out/src/" "../../encode_dp/src/")
// verilog-library-files:("")
// verilog-library-extensions:(".v" ".h")
// End:
