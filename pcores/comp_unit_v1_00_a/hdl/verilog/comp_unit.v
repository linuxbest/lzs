module comp_unit(/*AUTOARG*/
   // Outputs
   LLDMARSTENGINEREQ, LLDMARXD, LLDMARXREM, LLDMARXSOFN, LLDMARXEOFN,
   LLDMARXSOPN, LLDMARXEOPN, LLDMARXSRCRDYN, LLDMATXDSTRDYN,
   // Inputs
   CPMDMALLCLK, DMALLRSTENGINEACK, DMALLRXDSTRDYN, DMALLTXD,
   DMALLTXREM, DMALLTXSOFN, DMALLTXEOFN, DMALLTXSOPN, DMALLTXEOPN,
   DMALLTXSRCRDYN, DMATXIRQ, DMARXIRQ
   );
   // local link system singal
   input           CPMDMALLCLK;
   output          LLDMARSTENGINEREQ;
   input           DMALLRSTENGINEACK;
   // local link RX interface
   output [31:0]   LLDMARXD;
   output [3:0]    LLDMARXREM;
   output          LLDMARXSOFN;
   output          LLDMARXEOFN;
   output          LLDMARXSOPN;
   output          LLDMARXEOPN;
   output          LLDMARXSRCRDYN;
   input           DMALLRXDSTRDYN; 
   // local link TX interface
   input [31:0]    DMALLTXD;
   input [3:0]     DMALLTXREM;
   input           DMALLTXSOFN;
   input           DMALLTXEOFN;
   input           DMALLTXSOPN;
   input           DMALLTXEOPN;
   input           DMALLTXSRCRDYN; 
   output          LLDMATXDSTRDYN;
   // local link IRQ
   input           DMATXIRQ;
   input           DMARXIRQ;
   
   parameter TX_IDLE     = 4'h0;
   parameter TX_HEAD1    = 4'h1;
   parameter TX_HEAD2    = 4'h2;
   parameter TX_HEAD3    = 4'h3;
   parameter TX_HEAD4    = 4'h4;
   parameter TX_HEAD5    = 4'h5;
   parameter TX_HEAD6    = 4'h6;
   parameter TX_HEAD7    = 4'h7;
   parameter TX_PAYLOAD  = 4'h8;
   parameter TX_PAYLOAD1 = 4'h9;
   parameter TX_COPY     = 4'ha;
   parameter TX_END      = 4'hb;
   
   parameter RX_IDLE     = 4'h0;
   parameter RX_HEAD0    = 4'h1;
   parameter RX_HEAD1    = 4'h2;
   parameter RX_HEAD2    = 4'h3;
   parameter RX_HEAD3    = 4'h4;
   parameter RX_HEAD4    = 4'h5;
   parameter RX_HEAD5    = 4'h6;
   parameter RX_HEAD6    = 4'h7;
   parameter RX_HEAD7    = 4'h8;
   parameter RX_PAYLOAD  = 4'h9;
   parameter RX_PAYLOAD1 = 4'ha;
   parameter RX_COPY     = 4'hb;
   parameter RX_END      = 4'hc;

   wire            clk;
   wire            rst_n;
   reg [3:0]       tx_state;
   reg [3:0]       tx_state_n;
   reg [3:0]       rx_state;
   reg [3:0]       rx_state_n;
   wire            op_copy;
   wire            op_comp;
   wire            op_decomp;
   wire [3:0]     DMALLTXREM;
   reg [31:29]      flag;
   reg [31:0]      src_len; 
   reg [31:0]      data0;
   reg [31:0]      data1;
   reg [3:0]       rem;
   reg             copy_start;
   reg             copy_stop;
   reg             copy_wr;
   wire             dst_rd;
   reg             copy_end;
   wire             DMALLRSTENGINEACK;
//   reg [2:0]       rst_cnt;
   wire          LLDMATXDSTRDYN;
   wire          LLDMARXSRCRDYN;
   reg          LLDMARXSOPN;
   reg          LLDMARXEOPN;
   reg          LLDMARXEOFN;
   reg          rx_sof_n;
   
   wire [31:0] dst_dat_i;
   wire [31:0] dst_dat64_i;
   wire src_start;
   wire dst_start;
   wire dst_end;
   reg  dst_xfer;
   reg  src_xfer;
   reg  src_last;
   wire [15:0] ocnt;
   reg  reset_n;
   reg  tx_busy;
   
   wire [35:0] dst_data;
   wire src_fifo_full;
   wire dst_fifo_empty;

   assign clk = CPMDMALLCLK;
   assign rst_n = ~DMALLRSTENGINEACK && reset_n;
  // assign op_null = flag[28];
   assign op_copy = flag[29];
   assign op_decomp = flag[30];
   assign op_comp = flag[31];
   assign LLDMATXDSTRDYN = (src_fifo_full && op_copy) || tx_busy;
   assign LLDMARSTENGINEREQ = 0;
/*
   always @(posedge clk)
       if(LLDMARSTENGINEREQ != 1)
         rst_cnt <= 0;
       else 
         rst_cnt <= rst_cnt + 1;
       
   always @(posedge clk)
     begin
        DMALLRSTENGINEACK <= rst_cnt[2];
     end
*/
   always @(posedge clk)
     if (!rst_n)
       tx_state <= TX_IDLE;
     else if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
	tx_state <= tx_state_n;
     end
   
   always @(*)
     begin
	// tx_state_n = 'bX;
        case (tx_state)
          TX_IDLE   : begin 
             if (!DMALLTXSOFN)
               tx_state_n = TX_HEAD1;
             else 
               tx_state_n = TX_IDLE;
	  end 
	  //   TX_HEAD0  : begin 
	  //	  end 
          TX_HEAD1  : begin 
             tx_state_n = TX_HEAD2;
	  end 
          TX_HEAD2  : begin 
             tx_state_n = TX_HEAD3;
	  end 
          TX_HEAD3  : begin 
             tx_state_n = TX_HEAD4;
	  end 
          TX_HEAD4  : begin 
             tx_state_n = TX_HEAD5;
	  end 
          TX_HEAD5  : begin 
             tx_state_n = TX_HEAD6;
	  end 
          TX_HEAD6  : begin 
             tx_state_n = TX_HEAD7;
	  end 
          TX_HEAD7  : begin 
             if (op_copy)
               tx_state_n = TX_COPY;
             else 
               tx_state_n = TX_PAYLOAD;
	  end 
          TX_PAYLOAD: begin
	     if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
		if (!DMALLTXEOPN) 
		  tx_state_n = TX_END;
		else 
		  tx_state_n = TX_PAYLOAD1;
             end else begin
		tx_state_n = TX_PAYLOAD;
             end 
          end
          TX_PAYLOAD1: begin
	     if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
		if (!DMALLTXEOPN) 
		  tx_state_n = TX_END;
		else
		  tx_state_n = TX_PAYLOAD;
	     end else begin
		tx_state_n = TX_PAYLOAD1;
             end
          end
          TX_COPY: begin
             if (!DMALLTXEOPN) 
               tx_state_n = TX_END;
	     else
               tx_state_n = TX_COPY;
          end
          TX_END: begin 
             if (!reset_n)
               tx_state_n = TX_IDLE;
             else
               tx_state_n = TX_END;
	  end 
        endcase
     end   
   always @(posedge clk)
     if (!rst_n) begin
        flag <= 0;
        src_len <= 0;
        data0 <= 0;
        data1 <= 0;
        rem <= 0;
        copy_start <= 1;
        copy_end <= 1;
        copy_wr <= 0;
        src_last <= 0;
        src_xfer <= 0;
        tx_busy <= 0;
     end else begin
        case (tx_state)
          TX_IDLE   : begin 
             src_xfer <= 0;
             tx_busy <= 0;
	  end 
	  //   TX_HEAD0  : begin 
	  //	  end 
          TX_HEAD1  : begin 
	  end 
          TX_HEAD2  : begin 
	  end 
          TX_HEAD3  : begin 
	  end 
          TX_HEAD4  : begin 
             flag <= DMALLTXD[31:29];
	  end 
          TX_HEAD5  : begin 
             src_len <= DMALLTXD;
	  end 
          TX_HEAD6  : begin 
	  end 
          TX_HEAD7  : begin 
	  end 
          TX_PAYLOAD: begin
          end 
          TX_PAYLOAD1: begin
          end
          TX_COPY: begin
	     if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
                case (DMALLTXREM)
                   4'b0000 : rem[1:0] <= 2'b00;
                   4'b0001 : rem[1:0] <= 2'b01;
                   4'b0011 : rem[1:0] <= 2'b10;
                   4'b0111 : rem[1:0] <= 2'b11;
                endcase
                copy_wr <= 1;
                data0 <= DMALLTXD;
                rem[3:2] <= {DMALLTXSOPN,DMALLTXEOPN};
             end else begin
                copy_wr <= 0;
             end  
          end 
          TX_END    : begin 
             src_last <= 1;
             copy_start <= 1;
             src_xfer <= 1 && !DMALLTXSRCRDYN;
             if (!DMALLTXEOFN)
             tx_busy <= 1;
	  end 
        endcase
     end   
   
   always @(posedge clk)
     if (!rst_n)
       rx_state <= RX_IDLE;
     else if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
	rx_state <= rx_state_n;
     end
   
   always @(*)
     begin
        case (rx_state)
          RX_IDLE:    begin
             if (op_copy && !dst_fifo_empty)
               rx_state_n = RX_COPY;
             else 
               rx_state_n = RX_IDLE;
          end 
          RX_HEAD0  : begin 
             rx_state_n = RX_HEAD1;
	  end 
          RX_HEAD1  : begin 
             rx_state_n = RX_HEAD3;
	  end 
          RX_HEAD2  : begin 
             rx_state_n = RX_HEAD3;
	  end 
          RX_HEAD3  : begin 
             rx_state_n = RX_HEAD4;
	  end 
          RX_HEAD4  : begin 
             rx_state_n = RX_HEAD5;
	  end 
          RX_HEAD5  : begin 
             rx_state_n = RX_HEAD6;
	  end 
          RX_HEAD6  : begin 
             rx_state_n = RX_HEAD7;
	  end 
          RX_HEAD7  : begin 
             rx_state_n = RX_END;
	  end 
          RX_PAYLOAD: begin
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
		//   if (ocnt >= src_len[18:3])
		//     rx_state_n = RX_HEAD0;
		if (dst_end)
		  rx_state_n = RX_HEAD0;
		else 
		  rx_state_n = RX_PAYLOAD1;
             end else begin
		rx_state_n = RX_PAYLOAD;
             end
	  end  
          RX_PAYLOAD1: begin
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
		if (ocnt >= src_len[18:3])
		  rx_state_n = RX_HEAD0;
		else if (dst_end)
		  rx_state_n = RX_HEAD0;
		else 
		  rx_state_n = RX_PAYLOAD;
             end else begin
		rx_state_n = RX_PAYLOAD1;
             end
	  end  
          RX_COPY: begin
             if (!LLDMARXEOPN) begin
                rx_state_n = RX_HEAD0;
             end else begin
                rx_state_n = RX_COPY;
             end
	  end  
          RX_END: begin
             if(!reset_n)
               rx_state_n = RX_IDLE;
             else
               rx_state_n = RX_END;
	  end  
	endcase
     end    
   reg [31:0]    LLDMARXD;
   reg [3:0]    LLDMARXREM;
   reg           cpl_status;
   always @(posedge clk)
     if (!rst_n) begin
   //      dst_rd <= 0;
        rx_sof_n <= 1;
        dst_xfer <= 0;
        cpl_status <= 0;
        LLDMARXD <= 0;
        LLDMARXREM <= 0;
        LLDMARXSOPN <= 1;
        LLDMARXEOPN <= 1;
        LLDMARXEOFN <= 1;
        reset_n <= 1'b1;
     end else begin
        case (rx_state)
          RX_IDLE:    begin
               // dst_rd <= 0;
             reset_n <= 1'b1;
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
                if (op_copy && !dst_fifo_empty) begin
		   rx_sof_n <= 0;
		end else begin
		   rx_sof_n <= 1;
		end
             end else begin
		   rx_sof_n <= 1;
             end
          end 
          RX_HEAD0  : begin 
             LLDMARXREM <= 4'h0;
             LLDMARXSOPN <= 1;
             dst_xfer <= 0;
             LLDMARXEOPN <= 1;
	  end 
          RX_HEAD1  : begin 
	  end 
          RX_HEAD2  : begin 
	  end 
          RX_HEAD3  : begin 
	  end 
          RX_HEAD4  : begin 
             LLDMARXD <= {flag,cpl_status,28'h0};
	  end 
          RX_HEAD5  : begin 
             if (op_copy)
               LLDMARXD <= src_len;
             else
               LLDMARXD <= {13'h0,ocnt,3'h0};
	  end 
          RX_HEAD6  : begin 
	  end 
          RX_HEAD7  : begin 
             LLDMARXEOFN <= 0;
//	     LLDMARXREM <= rem;
	  end 
          RX_PAYLOAD: begin
	  end  
          RX_PAYLOAD1: begin
	  end
          RX_COPY: begin
      	     //rx_sof_n <= 1;
             if (!dst_data[34]) begin
                cpl_status <= 1;
             end
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
      	     rx_sof_n <= 1;
	     LLDMARXSOPN <= dst_data[35];
	     LLDMARXD <= dst_data[31:0];
              //  dst_rd <= 1;
             if (!LLDMARXEOPN) begin
	     LLDMARXEOPN <= 1;
             LLDMARXREM <= 4'b0000;
             end else begin
	     LLDMARXEOPN <= dst_data[34];
                case (dst_data[33:32])
                   2'b00 : LLDMARXREM <= 4'b0000;
                   2'b01 : LLDMARXREM <= 4'b0001;
                   2'b10 : LLDMARXREM <= 4'b0011;
                   2'b11 : LLDMARXREM <= 4'b0111;
                endcase
             end
             end else begin
	     //LLDMARXSOPN <= 1;
	     LLDMARXEOPN <= 1;
            //    dst_rd <= 0;
             end   
	  end  
          RX_END: begin
             LLDMARXEOFN <= 1;
	     LLDMARXREM <= 0;
             if(LLDMARXEOFN)
               reset_n <= 1'b0;
             else
               reset_n <= 1'b1;
	  end  
	endcase
     end
   reg        full_cntl;
   wire       half_full;
   always @(posedge clk)
     if (!rst_n)
        full_cntl <= 1;
     else if (half_full || tx_busy) 
        full_cntl <= 0;
     else if(dst_fifo_empty)
        full_cntl <= 1;
        
   assign LLDMARXSOFN = rx_sof_n;
   assign LLDMARXSRCRDYN = dst_fifo_empty || full_cntl;
   assign dst_rd = (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN)&&(rx_state == RX_COPY)?1:0;
   
   //----------mod & ch instance -------------
   
   wire  m_src_getn;
   wire  m_dst_putn;
   wire [63:0] m_dst;
   wire  m_dst_last;
   wire  m_endn;
   wire [7:0] m_cap;
   wire m_reset;
   wire m_enable;
   wire [23:0] dc;  
   wire [63:0] m_src;
   wire  m_src_last; 
   wire  m_src_empty;
   wire  m_src_almost_empty;
   wire  m_dst_almost_full;
   wire  m_dst_full;
   
   assign    m_reset = ~rst_n;
   assign    m_enable = 1;
   assign    dc[6:5] = {op_decomp,op_comp};
   assign    dc[4:0] = 'b0;
   assign    dc[23:7] = 'b0;

     ch_fifo src_fifo(
	.din                ({rem,data0}),
	.prog_full_thresh   (9'h100),
	.rd_clk             (clk),
	.rd_en              (dst_rd),
	.rst                (~rst_n),
	.wr_clk             (clk),
	.wr_en              (copy_wr),
	.almost_empty       (),
	.almost_full        (src_fifo_full),
	.dout               (dst_data),
	.empty              (dst_fifo_empty),
	.full               (half_full),
	.prog_full          ()
      );


/*
 */
endmodule // comp_unit






 
