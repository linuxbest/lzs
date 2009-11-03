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
   reg             copy_end;
   wire             DMALLRSTENGINEACK;
//   reg [2:0]       rst_cnt;
   wire          LLDMATXDSTRDYN;
   reg          LLDMARXSRCRDYN;
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

   assign clk = CPMDMALLCLK;
   assign rst_n = ~DMALLRSTENGINEACK && reset_n;
   assign op_copy = flag[29];
   assign op_decomp = flag[30];
   assign op_comp = flag[31];
   assign LLDMATXDSTRDYN = (~src_start && (op_comp || op_decomp)) || (DMALLRXDSTRDYN && op_copy) || tx_busy;
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
        copy_stop <= 0;
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
	     if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
                if (!DMALLTXEOPN) begin
                   src_xfer <= 1;
		   data1 <= 0;
                   case (DMALLTXREM)
                     4'b0000 : data0 <= DMALLTXD;
                     4'b0001 : data0 <= {DMALLTXD[31:8],8'h0};
                     4'b0011 : data0 <= {DMALLTXD[31:16],16'h0};
                     4'b0111 : data0 <= {DMALLTXD[31:24],24'h0};
                   endcase
	        end else begin
                   src_xfer <= 0;
		   data0 <= DMALLTXD;
                end
             end else begin
                src_xfer <= 0;
             end
          end 
          TX_PAYLOAD1: begin
	     if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
                src_xfer <= 1;
                if (!DMALLTXEOPN) begin
                   case (DMALLTXREM)
                     4'b0000 : data1 <= DMALLTXD;
                     4'b0001 : data1 <= {DMALLTXD[31:8],8'h0};
                     4'b0011 : data1 <= {DMALLTXD[31:16],16'h0};
                     4'b0111 : data1 <= {DMALLTXD[31:24],24'h0};
                   endcase
	        end else begin
		   data1 <= DMALLTXD;
                end
             end else begin
                src_xfer <= 0;
             end
          end
          TX_COPY: begin
	     if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
                copy_stop <= 0;
                data0 <= DMALLTXD;
                rem <= DMALLTXREM;
             end else begin
                copy_stop <= 1;
             end  
             copy_start <= DMALLTXSOPN;
             copy_end <= DMALLTXEOPN;
          end 
          TX_END    : begin 
             src_last <= 1;
             copy_start <= 1;
             copy_end <= DMALLTXEOPN;
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
             if (op_copy)
               rx_state_n = RX_COPY;
             else if (dst_start && (op_comp || op_decomp))
               rx_state_n = RX_PAYLOAD;
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
        rx_sof_n <= 1;
        dst_xfer <= 0;
        cpl_status <= 0;
        LLDMARXD <= 0;
        LLDMARXREM <= 0;
        LLDMARXSRCRDYN <= 0;
        LLDMARXSOPN <= 1;
        LLDMARXEOPN <= 1;
        LLDMARXEOFN <= 1;
        reset_n <= 1'b1;
     end else begin
        case (rx_state)
          RX_IDLE:    begin
             reset_n <= 1'b1;
             if (dst_start && (op_comp || op_decomp)) begin
		if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
		   rx_sof_n <= 0;
		end else begin
		   rx_sof_n <= 1;
		end
             end
          end 
          RX_HEAD0  : begin 
             LLDMARXREM <= 4'h0;
             LLDMARXSOPN <= 1;
             dst_xfer <= 0;
             LLDMARXSRCRDYN <= 0;
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
             dst_xfer <= 0;
             rx_sof_n <= 1;
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
                LLDMARXSOPN <= rx_sof_n;
                LLDMARXD <= dst_dat64_i;
		//  if (ocnt >= src_len[18:3]) begin
		//     LLDMARXREM <= 4'hf;
		//     cpl_status <= 0;
		//     dst_xfer <= 0;
		//     LLDMARXEOPN <= 0;
		if (dst_end) begin
                   LLDMARXREM <= 4'h7;
                   cpl_status <= 1;
                   LLDMARXEOPN <= 0;
		end else begin
                   LLDMARXEOPN <= 1;
		end
             end
	  end  
          RX_PAYLOAD1: begin
             LLDMARXSOPN <= 1;
             LLDMARXSRCRDYN <= ~dst_start;
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
                LLDMARXD <= dst_dat_i;
		if (ocnt >= src_len[18:3]) begin
                   LLDMARXREM <= 4'h7;
                   cpl_status <= 0;
                   dst_xfer <= 0;
                   LLDMARXEOPN <= 0;
		end else if (dst_end) begin
                   LLDMARXREM <= 4'h7;
                   cpl_status <= 1;
                   dst_xfer <= 0;
                   LLDMARXEOPN <= 0;
		end else begin
                   dst_xfer <= 1;
                   LLDMARXEOPN <= 1;
		end
	     end
	  end
          RX_COPY: begin
	     LLDMARXSRCRDYN <= copy_stop;
	     LLDMARXSOPN <= copy_start;
	     LLDMARXEOPN <= copy_end;
	     LLDMARXD <= data0;
	     LLDMARXREM <= rem;
             if (!copy_end) begin
                cpl_status <= 1;
             end
             if (!LLDMARXEOPN) begin
                LLDMARXREM <= 0;
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
   assign LLDMARXSOFN = copy_start && rx_sof_n;
   
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
/*
   mod u_mod(
             // Outputs
             .m_src_getn                (m_src_getn),
             .m_dst_putn                (m_dst_putn),
             .m_dst                     (m_dst[63:0]),
             .m_dst_last                (m_dst_last),
             .m_endn                    (m_endn),
             .m_cap                     (m_cap[7:0]),
             // Inputs
             .wb_clk_i                  (clk),
             .m_reset                   (m_reset),
             .m_enable                  (m_enable),
             .dc                        (dc[23:0]),
             .m_src                     (m_src[63:0]),
             .m_src_last                (m_src_last),
             
             .m_src_empty               (m_src_empty),
             .m_src_almost_empty          (m_src_almost_empty),
             .m_dst_almost_full         (m_dst_almost_full),
             .m_dst_full                (m_dst_full));
   
   ch u_ch(
           // Outputs
           .src_stop                    (src_stop),
           .dst_stop                    (dst_stop),
           .src_start                   (src_start),
           .dst_start                   (dst_start),
           .src_end                     (src_end),
           .dst_end                     (dst_end),
           .src_dat_i                   (),
           .dst_dat_i                   (dst_dat_i),
           .src_dat64_i                 (),
           .dst_dat64_i                 (dst_dat64_i),
           .m_src                       (m_src[63:0]),
           .m_src_last                  (m_src_last),
           .m_src_almost_empty          (m_src_almost_empty),
           .m_src_empty                 (m_src_empty),
           .m_dst_almost_full           (m_dst_almost_full),
           .m_dst_full                  (m_dst_full),
           .ocnt                        (ocnt[15:0]),
           // Inputs
           .wb_clk_i                    (clk),
           .wb_rst_i                    (~rst_n),
           .src_xfer                    (src_xfer),
           .dst_xfer                    (dst_xfer),
           .src_last                    (src_last),
           .dst_last                    (dst_last),
           .src_dat_o                   (data1),
           .dst_dat_o                   (),
           .src_dat64_o                 (data0),
           .dst_dat64_o                 (),
           .dc                          (dc[23:0]),
           .m_reset                     (m_reset),
           .m_src_getn                  (m_src_getn),
           .m_dst_putn                  (m_dst_putn),
           .m_dst                       (m_dst[63:0]),
           .m_dst_last                  (m_dst_last),
           .m_endn                      (m_endn));
 */
endmodule // comp_unit






 
