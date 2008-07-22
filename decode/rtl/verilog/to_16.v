/**************************************************************************  
 *                                                                         
 *          File Name : to_16.v                                            
 *            Version : 0.1                                                  
 *               Date : Mar 26, 2008                                         
 *        Description :                                                      
 *       Dependencies :                                                      
 *                                                                         
 *            Company : Beijing Soul                                        
 *             Author :                                                     
 *                                                                          
 **************************************************************************/

module to_16 (/*AUTOARG*/
   // Outputs
   src_getn, data, die, iidx,
   // Inputs
   clk, rst, fi, m_src_empty, busy
   );
   input clk, rst;
   
   input [63:0] fi;
   input 	m_src_empty;
   output 	src_getn;
   
   output [15:0] data;
   output 	 die;
   output [1:0]  iidx;
   input 	 busy;
   
   reg 		 die, die_n;
   reg 		 src_getn, src_getn_n;
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  src_getn <= #1 1;
	else
	  src_getn <= #1 src_getn_n;
     end
   parameter [1:0]
		S_IDLE = 2'b00,
		S_OE   = 2'b01,
		S_WAIT = 2'b11;
   reg [1:0] 	  state, state_n;
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  state <= #1 S_IDLE;
	else
	  state <= #1 state_n;
     end
   
   reg [1:0] iidx;
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  iidx <= #1 0;
	else if (die_n)
	  iidx <= #1 iidx + 1;
     end
   
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  die <= #1 0;
	else if (die_n)
	  die <= #1 1;
	else
	  die <= #1 0;
     end
   
   reg [15:0] data;
   always @(posedge clk)
     begin
	case (iidx)
	  2'b00: data <= #1 {fi[07:00], fi[15:08]};
	  2'b01: data <= #1 {fi[23:16], fi[31:24]};
	  2'b10: data <= #1 {fi[39:32], fi[47:40]};
	  2'b11: data <= #1 {fi[55:48], fi[63:56]};
	endcase
     end
   
   always @(/*AS*/busy or iidx or m_src_empty or state)
     begin
	state_n = S_IDLE;
	
	die_n = 0;
	src_getn_n = 1;

	case (state)
	  S_IDLE: begin
	     if (m_src_empty) /* first data */
	       state_n = S_IDLE;
	     else begin
		state_n = S_OE;
		die_n = 1;
	     end
	  end

	  S_OE: begin
	     state_n = S_OE;
	     
	     if (!busy) begin
		die_n = 1;
		
		if (iidx == 2'b10) begin
		   if (m_src_empty) begin
		      state_n = S_WAIT;
		   end else begin
		      src_getn_n = 0;
		   end
		end
	     end // if (!busy)
	  end
	  
	  S_WAIT: begin
	     if (m_src_empty)
	       state_n = S_WAIT;
	     else begin
		state_n = S_OE;
		src_getn_n = 0;
	     end
	  end
	endcase
     end
   
endmodule