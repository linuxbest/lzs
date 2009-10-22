module comp_unit(/*AUTOARG*/
   // Outputs
   DMALLRSTENGINEACK, LLDMARXD, LLDMARXREM, LLDMARXSOFN, LLDMARXEOFN,
   LLDMARXSOPN, LLDMARXEOPN, LLDMARXSRCRDYN, LLDMATXDSTRDYN,
   // Inputs
   CPMDMALLCLK, LLDMARSTENGINEREQ, DMALLRXDSTRDYN, DMALLTXD,
   DMALLTXREM, DMALLTXSOFN, DMALLTXEOFN, DMALLTXSOPN, DMALLTXEOPN,
   DMALLTXSRCRDYN, DMATXIRQ, DMARXIRQ
   );
   // local link system singal
   input           CPMDMALLCLK;
   input           LLDMARSTENGINEREQ;
   output          DMALLRSTENGINEACK;
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

   wire            clk;
   wire            rst_n;
   reg [3:0]       tx_state;
   reg [3:0]       tx_state_n;
   reg [3:0]       rx_state;
   reg [3:0]       rx_state_n;
   wire            op_copy;
   wire [3:0]     DMALLTXREM;
   reg [31:0]      flag;
   reg [31:0]      src_len; 
   reg [31:0]      data0;
   reg [31:0]      data1;
   reg [3:0]       rem;
   
   assign clk = CPMDMALLCLK;
   assign rst_n = 1;
   assign op_copy = flag[29];
    
   always @(posedge clk)
     if (!rst_n)
       tx_state <= TX_IDLE;
     else 
       tx_state <= tx_state_n;
   
   always @(*)
     begin
        tx_state_n = 'bX;
        case (tx_state)
          TX_IDLE   : begin 
             if (!LLDMARXSOFN)
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
             if (!DMALLTXEOPN) 
               tx_state_n = TX_END;
	     else if (DMALLTXSRCRDYN && LLDMATXDSTRDYN)
               tx_state_n = TX_PAYLOAD1;
             else
               tx_state_n = TX_PAYLOAD;
              end 
          TX_PAYLOAD1: begin
             if (!DMALLTXEOPN) 
               tx_state_n = TX_END;
	     else if (DMALLTXSRCRDYN && LLDMATXDSTRDYN)
               tx_state_n = TX_PAYLOAD;
	     else
               tx_state_n = TX_PAYLOAD1;
          end
          TX_COPY: begin
             if (!DMALLTXEOPN) 
               tx_state_n = TX_END;
	     else
               tx_state_n = TX_PAYLOAD1;
          end
          TX_END: begin 
             if (!DMALLTXEOFN)
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
     end else begin
        case (tx_state)
          TX_IDLE   : begin 
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
             flag <= DMALLTXD;
	  end 
          TX_HEAD5  : begin 
             src_len <= DMALLTXD;
	  end 
          TX_HEAD6  : begin 
	  end 
          TX_HEAD7  : begin 
	  end 
          TX_PAYLOAD: begin
             if (!DMALLTXEOPN) begin
                case (DMALLTXREM)
                  4'b0000 : data0 <= DMALLTXD;
                  4'b0001 : data0 <= {DMALLTXD[31:8],8'h0};
                  4'b0011 : data0 <= {DMALLTXD[31:16],16'h0};
                  4'b0111 : data0 <= {DMALLTXD[31:24],24'h0};
                endcase
	     end else if (DMALLTXSRCRDYN && LLDMATXDSTRDYN) begin
		data0 <= DMALLTXD;
             end
          end 
          TX_PAYLOAD1: begin
             if (!DMALLTXEOPN) begin
                case (DMALLTXREM)
                  4'b0000 : data1 <= DMALLTXD;
                  4'b0001 : data1 <= {DMALLTXD[31:8],8'h0};
                  4'b0011 : data1 <= {DMALLTXD[31:16],16'h0};
                  4'b0111 : data1 <= {DMALLTXD[31:24],24'h0};
                endcase
	     end else if (DMALLTXSRCRDYN && LLDMATXDSTRDYN) begin
		data1 <= DMALLTXD;
             end
          end
          TX_COPY: begin
              data0 <= DMALLTXD;
              rem <= DMALLTXREM;
          end 
          TX_END    : begin 
	  end 
        endcase
     end   
   
   always @(posedge clk)
     if (!rst_n)
       rx_state <= RX_IDLE;
     else 
       rx_state <= rx_state_n;
   
   always @(*)
     begin
        tx_state_n <= 'bX;
        case (rx_state)
          RX_IDLE:    begin
             if (op_copy)
               rx_state_n = RX_COPY;
          //   else if (start)
          //     rx_state_n = RX_PAYLOAD;
             else 
               rx_state_n = RX_IDLE;
          end 
          RX_HEAD0  : begin 
             rx_state_n = RX_HEAD1;
	  end 
          RX_HEAD1  : begin 
             rx_state_n = RX_HEAD2;
	  end 
          RX_HEAD2  : begin 
             rx_state_n = RX_HEAD2;
	  end 
          RX_HEAD3  : begin 
             rx_state_n = RX_HEAD2;
	  end 
          RX_HEAD4  : begin 
             rx_state_n = RX_HEAD2;
	  end 
          RX_HEAD5  : begin 
             rx_state_n = RX_HEAD2;
	  end 
          RX_HEAD6  : begin 
             rx_state_n = RX_HEAD2;
	  end 
          RX_HEAD7  : begin 
             rx_state_n = RX_IDLE;
	  end 
          RX_PAYLOAD: begin
	  end  
          RX_PAYLOAD1: begin
	  end  
          RX_COPY: begin
             if (!LLDMARXEOPN) begin
                rx_state_n = RX_HEAD0;
             end else begin
                rx_state_n = RX_COPY;
             end
	  end  
	endcase
     end    
   reg [31:0]    LLDMARXD;
   reg [31:0]    LLDMARXREM;
   always @(posedge clk)
     if (!rst_n) begin
          LLDMARXD <= 0;
          LLDMARXREM <= 0;
     end else begin
        case (rx_state)
          RX_IDLE:    begin
          end 
          RX_HEAD0  : begin 
	  end 
          RX_HEAD1  : begin 
	  end 
          RX_HEAD2  : begin 
	  end 
          RX_HEAD3  : begin 
	  end 
          RX_HEAD4  : begin 
             LLDMARXD <= flag;
	  end 
          RX_HEAD5  : begin 
             LLDMARXD <= src_len;
	  end 
          RX_HEAD6  : begin 
	  end 
          RX_HEAD7  : begin 
	  end 
          RX_PAYLOAD: begin
	  end  
          RX_PAYLOAD1: begin
	  end  
          RX_COPY: begin
             LLDMARXD <= data0;
             LLDMARXREM <= rem;
	  end  
	endcase
      end
   //----------mod & ch instance -------------
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
             .wb_clk_i                  (ACLK),
             .m_reset                   (m_reset),
             .m_enable                  (m_enable),
             .dc                        (dc[23:0]),
             .m_src                     (m_src[63:0]),
             .m_src_last                (m_src_last),
             .m_src_almost_empty        (m_src_almost_empty),
             .m_src_empty               (m_src_empty),
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
           .wb_clk_i                    (ACLK),
           .wb_rst_i                    (reset),
           .src_xfer                    (src_xfer),
           .dst_xfer                    (dst_xfer),
           .src_last                    (src_last),
           .dst_last                    (dst_last),
           .src_dat_o                   (src_dat_o),
           .dst_dat_o                   (),
           .src_dat64_o                 (src_dat64_o),
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










 
