module comp_unit(/*AUTOARG*/
   // Outputs
   LLDMARSTENGINEREQ, LLDMARXD, LLDMARXREM, LLDMARXSOFN, LLDMARXEOFN,
   LLDMARXSOPN, LLDMARXEOPN, LLDMARXSRCRDYN, LLDMATXDSTRDYN, src_last,
   dst_end, dst_start,
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
   // debug interface
   output          src_last;
   output          dst_end;
   output          dst_start;
   
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
   wire            op_copy1;
   wire            op_comp;
   wire            op_decomp;
   wire [3:0]      DMALLTXREM_r;
   reg [31:29]     flag;
   reg [31:0]      src_len; 
   reg [31:0]      data0;
   reg [31:0]      data1;
   reg [31:0]      rx_data_comp;
   reg [3:0]       rem;
   reg             copy_start;
   reg             copy_stop;
   reg             copy_end;
   wire            DMALLRSTENGINEACK;
   wire            LLDMATXDSTRDYN;
   reg [31:0]      LLDMARXD_r;
   reg [3:0]       LLDMARXREM_r;
   reg             LLDMARXSRCRDYN_r;
   reg             LLDMARXSOPN_r;
   reg             LLDMARXEOPN_r;
   reg             LLDMARXEOFN_r;
   reg             rx_sof_r_n;
   
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
   reg  rx_end;
   reg [15:0] len_cnt;
   //------------lldma interface define---------------------
   wire Rst = ~rst_n;
   wire SYS_Clk = clk;
   wire [31:0] rx_data;	    
   wire [3:0] rx_rem;	    
   wire rx_sof_n;    
   wire rx_eof_n;    
   wire rx_sop_n;    
   wire rx_eop_n;    
   wire rx_src_rdy_n;
   wire rx_dst_rdy_n;
   
   wire [31:0]     tx_data;
   wire [31:0]     tx_rem;
   wire      tx_sof_n;
   wire      tx_eof_n;
   wire      tx_sop_n;
   wire      tx_eop_n;
   wire      tx_src_rdy_n;
   wire      tx_dst_rdy_n;
   
   reg       tx_end_rdy;
   reg [9:0] task_index;
   
   assign LLDMARSTENGINEREQ = 0;
   //--------------rx interface mux-----------------------------
   assign LLDMARXD = LLDMARXD_r;
   assign LLDMARXREM = LLDMARXREM_r;
   assign LLDMARXSOFN = rx_sof_r_n;
   assign LLDMARXEOFN = LLDMARXEOFN_r;
   assign LLDMARXSOPN = LLDMARXSOPN_r;
   assign LLDMARXEOPN = LLDMARXEOPN_r;
   assign LLDMARXSRCRDYN = LLDMARXSRCRDYN_r;

  //--------------rx interface mux-----------------------------
   assign tx_data      = DMALLTXD;     
   assign tx_rem      = DMALLTXREM;
   assign tx_sof_n    = DMALLTXSOFN;
   assign tx_eof_n    = DMALLTXEOFN;
   assign tx_sop_n    = DMALLTXSOPN;
   assign tx_eop_n    = DMALLTXEOPN;
   assign tx_src_rdy_n= DMALLTXSRCRDYN;
   assign LLDMATXDSTRDYN = (~src_start && (op_comp || op_decomp || op_copy1))
                                   && (tx_end_rdy || tx_busy)
                                   /*|| (tx_dst_rdy_n && op_copy)*/ || tx_busy;
   assign clk = CPMDMALLCLK;
   assign rst_n = ~DMALLRSTENGINEACK && reset_n;
   assign op_copy = flag[29];
   assign op_copy1 = 0;
   assign op_decomp = flag[30];
   assign op_comp = flag[31];
   
   always @(posedge clk)
     if (!rst_n)
       tx_state <= TX_IDLE;
     else
       tx_state <= tx_state_n;
   
   always @(*)
     begin
        case (tx_state)
          TX_IDLE   : begin 
             if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
		if (!DMALLTXSOFN)
		  tx_state_n = TX_HEAD1;
		else 
		  tx_state_n = TX_IDLE;
             end else 
               tx_state_n = TX_IDLE;
	  end 
          TX_HEAD1  : begin 
             if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
		tx_state_n = TX_HEAD2;
             end else
               tx_state_n = TX_HEAD1;
	  end 
          TX_HEAD2  : begin 
             if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
		tx_state_n = TX_HEAD3;
             end else
               tx_state_n = TX_HEAD2;
	  end 
          TX_HEAD3  : begin 
             if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
		tx_state_n = TX_HEAD4;
             end else
               tx_state_n = TX_HEAD3;
	  end 
          TX_HEAD4  : begin 
             if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
		tx_state_n = TX_HEAD5;
             end else
               tx_state_n = TX_HEAD4;
	  end 
          TX_HEAD5  : begin 
             if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
		tx_state_n = TX_HEAD6;
             end else
               tx_state_n = TX_HEAD5;
	  end 
          TX_HEAD6  : begin 
             if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
		tx_state_n = TX_HEAD7;
             end else
               tx_state_n = TX_HEAD6;
	  end 
          TX_HEAD7  : begin 
             if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
		if (op_copy)
		  tx_state_n = TX_COPY;
		else 
		  tx_state_n = TX_PAYLOAD;
             end else
               tx_state_n = TX_HEAD7;
	  end 
          TX_PAYLOAD: begin
	     if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
		if (!DMALLTXEOPN) 
		  tx_state_n = TX_END;
		else 
		  tx_state_n = TX_PAYLOAD1;
             end else if (rx_end) 
		tx_state_n = TX_END;
             else
		tx_state_n = TX_PAYLOAD;
          end
          TX_PAYLOAD1: begin
	     if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
		if (!DMALLTXEOPN) 
		  tx_state_n = TX_END;
		else
		  tx_state_n = TX_PAYLOAD;
             end else if (rx_end) 
		tx_state_n = TX_END;
             else
		tx_state_n = TX_PAYLOAD1;
          end
          TX_COPY: begin
	     if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
		if (!DMALLTXEOPN) 
		  tx_state_n = TX_END;
		else
		  tx_state_n = TX_COPY;
             end else 
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
        copy_start <= 1;
        copy_end <= 1;
        tx_end_rdy <= 1;
        /*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	data0 <= 32'h0;
	data1 <= 32'h0;
	flag <= 3'h0;
	src_last <= 1'h0;
	src_len <= 32'h0;
	src_xfer <= 1'h0;
	tx_busy <= 1'h0;
        task_index <= 0;
	// End of automatics
     end else begin
        case (tx_state)
          TX_IDLE   : begin 
             src_xfer <= 0;
             tx_busy <= 0;
	  end 
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
             task_index <= DMALLTXD[9:0];
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
          end 
          TX_END    : begin 
             src_last <= 1;
             copy_start <= 1;
             copy_end <= 0;
             src_xfer <= !DMALLTXEOFN;
             tx_end_rdy <= 0;
	     if (!DMALLTXSRCRDYN && !LLDMATXDSTRDYN) begin
		if (!DMALLTXEOFN)
		  tx_busy <= 1;
             end
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
        case (rx_state)
          RX_IDLE:    begin
             if (!DMALLRXDSTRDYN) begin
		if (op_copy)
               rx_state_n = RX_COPY;
		else if (dst_start && (op_comp || op_decomp || op_copy1))
		  rx_state_n = RX_PAYLOAD;
		else 
		  rx_state_n = RX_IDLE;
             end else 
               rx_state_n = RX_IDLE;
          end 
          RX_HEAD0  : begin 
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
		rx_state_n = RX_HEAD1;
             end else 
               rx_state_n = RX_HEAD0;
	  end 
          RX_HEAD1  : begin 
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
		rx_state_n = RX_HEAD2;
             end else 
               rx_state_n = RX_HEAD1;
	  end 
          RX_HEAD2  : begin 
           if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
              rx_state_n = RX_HEAD3;
           end else 
             rx_state_n = RX_HEAD2;
	  end 
          RX_HEAD3  : begin 
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
		rx_state_n = RX_HEAD4;
             end else 
               rx_state_n = RX_HEAD3;
	  end 
          RX_HEAD4  : begin 
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
		rx_state_n = RX_HEAD5;
             end else 
               rx_state_n = RX_HEAD4;
	  end 
          RX_HEAD5  : begin 
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
		rx_state_n = RX_HEAD6;
             end else 
               rx_state_n = RX_HEAD5;
	  end 
          RX_HEAD6  : begin 
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
		rx_state_n = RX_HEAD7;
             end else 
               rx_state_n = RX_HEAD6;
	  end 
          RX_HEAD7  : begin 
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
		rx_state_n = RX_END;
             end else 
               rx_state_n = RX_HEAD7;
	  end 
          RX_PAYLOAD: begin
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
		rx_state_n = RX_PAYLOAD1;
             end else begin
		rx_state_n = RX_PAYLOAD;
             end
	  end  
          RX_PAYLOAD1: begin
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
		if (ocnt > src_len[18:3])
		  rx_state_n = RX_HEAD0;
		else if ((ocnt == len_cnt) && dst_start)
		  rx_state_n = RX_HEAD0;
		else 
		  rx_state_n = RX_PAYLOAD;
             end else begin
		rx_state_n = RX_PAYLOAD1;
             end
	  end  
          RX_COPY: begin
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
		if (!LLDMARXEOFN) 
		  rx_state_n = RX_END;
		else
		  rx_state_n = RX_COPY;
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
   reg           cpl_status;
   always @(posedge clk)
     if (!rst_n) begin
        rx_sof_r_n    <= 1;
        LLDMARXSOPN_r <= 1;
        LLDMARXEOPN_r <= 1;
        LLDMARXEOFN_r <= 1;
        reset_n       <= 1'b1;
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	LLDMARXD_r <= 32'h0;
	LLDMARXREM_r <= 4'h0;
	LLDMARXSRCRDYN_r <= 1'h0;
	cpl_status <= 1'h0;
	dst_xfer <= 1'h0;
	rx_data_comp <= 32'h0;
        rx_end <= 0;
	// End of automatics
     end else begin
        case (rx_state)
          RX_IDLE:    begin
             reset_n <= 1'b1;
             if (dst_start && (op_comp || op_decomp || op_copy1))begin
		if (!DMALLRXDSTRDYN) begin
                   LLDMARXSRCRDYN_r <= 0;
		   rx_sof_r_n <= 0;
		end else begin
                   LLDMARXSRCRDYN_r <= 1;
		   rx_sof_r_n <= 1;
		end
             end 
          end 
          RX_HEAD0  : begin 
             LLDMARXSRCRDYN_r <= 0;
             dst_xfer <= 0;
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
		LLDMARXREM_r <= 4'h0;
		LLDMARXSOPN_r <= 1;
		dst_xfer <= 0;
		LLDMARXEOPN_r <= 1;
             end
	  end 
          RX_HEAD1  : begin 
	  end 
          RX_HEAD2  : begin 
	  end 
          RX_HEAD3  : begin 
             dst_xfer <= 1;
             rx_end <= 1;
             LLDMARXSRCRDYN_r <= !tx_busy;
	  end 
          RX_HEAD4  : begin 
             LLDMARXSRCRDYN_r <= !tx_busy;
             LLDMARXD_r <= {flag,cpl_status,28'h0};
	  end 
          RX_HEAD5  : begin 
             if (op_copy)
               LLDMARXD_r <= src_len;
             else
               LLDMARXD_r <= {13'h0,ocnt,3'h0};
	  end 
          RX_HEAD6  : begin 
             LLDMARXD_r <= {22'h0,task_index};
	  end 
          RX_HEAD7  : begin 
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
		LLDMARXEOFN_r <= 0;
             end
	  end 
          RX_PAYLOAD: begin
             rx_sof_r_n <= 1;
             LLDMARXEOPN_r <= 1;
             LLDMARXSRCRDYN_r <= ~dst_start;
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
                LLDMARXSOPN_r <= rx_sof_r_n;
                LLDMARXD_r <= dst_dat64_i;
                rx_data_comp <= dst_dat_i;
                dst_xfer <= 1;
	     end else begin
                dst_xfer <= 0;
	     end
	  end  
          RX_PAYLOAD1: begin
             dst_xfer <= 0;
             LLDMARXSOPN_r <= 1;
             LLDMARXSRCRDYN_r <= ~dst_start;
             if (!LLDMARXSRCRDYN && !DMALLRXDSTRDYN) begin
                LLDMARXD_r <= rx_data_comp;
		if (ocnt > src_len[18:3]) begin
                   LLDMARXREM_r <= 4'h7;
                   cpl_status <= 0;
                   LLDMARXEOPN_r <= 0;
		end else if ((ocnt == len_cnt) && dst_start) begin
                   LLDMARXREM_r <= 4'h0;
                   cpl_status <= 1;
                   LLDMARXEOPN_r <= 0;
		end else begin
                   LLDMARXEOPN_r <= 1;
		end
	     end
	  end
          RX_COPY: begin
	  end  
          RX_END: begin
             LLDMARXEOFN_r <= 1;
	     LLDMARXREM_r <= 0;
             LLDMARXSRCRDYN_r <= 1;
             dst_xfer <= 1;
             rx_end <= 1;
             if(LLDMARXEOFN && tx_busy)
               reset_n <= 1'b0;
             else
               reset_n <= 1'b1;
	  end  
	endcase
     end
   always @(posedge clk)
     if (!rst_n)
       len_cnt <= 1;
     else if (dst_xfer)
       len_cnt <= len_cnt + 1;
   
   
   //----------mod & ch instance -------------
   
   wire        m_src_getn;
   wire        m_dst_putn;
   wire [63:0] m_dst;
   wire        m_dst_last;
   wire        m_endn;
   wire [7:0]  m_cap;
   wire        m_reset;
   wire        m_enable;
   wire [23:0] dc;  
   wire [63:0] m_src;
   wire        m_src_last; 
   wire        m_src_empty;
   wire        m_src_almost_empty;
   wire        m_dst_almost_full;
   wire        m_dst_full;
   
   assign    m_reset = ~rst_n;
   assign    m_enable = 1;
   assign    dc[6:4] = {op_decomp,op_comp,op_copy1};
   assign    dc[3:0] = 'b0;
   assign    dc[23:7] = 'b0;

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
             .m_src_almost_empty        (m_src_almost_empty),
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
           .src_dat_o                   (data0),
           .dst_dat_o                   (),
           .src_dat64_o                 (data1),
           .dst_dat64_o                 (),
           .dc                          (dc[23:0]),
           .m_reset                     (m_reset),
           .m_src_getn                  (m_src_getn),
           .m_dst_putn                  (m_dst_putn),
           .m_dst                       (m_dst[63:0]),
           .m_dst_last                  (m_dst_last),
           .m_endn                      (m_endn));

endmodule // comp_unit

// Local Variables:
// verilog-library-directories:(".")
// verilog-library-files:("lldma_exerciser.v")
// verilog-library-extensions:(".v" ".h")
// End:





 
