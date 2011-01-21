module ll_crc(/*AUTOARG*/
   // Outputs
   crc_tx, crc_rx,
   // Inputs
   clk, rst_n, LLDMARXD, LLDMARXREM, LLDMARXSOFN, LLDMARXEOFN,
   LLDMARXSOPN, LLDMARXEOPN, LLDMARXSRCRDYN, DMALLRXDSTRDYN, DMALLTXD,
   DMALLTXREM, DMALLTXSOFN, DMALLTXEOFN, DMALLTXSOPN, DMALLTXEOPN,
   DMALLTXSRCRDYN, LLDMATXDSTRDYN
   );
   
   input          clk;
   input          rst_n;
   // local link RX interface
   input [31:0]   LLDMARXD;
   input [3:0]    LLDMARXREM;
   input          LLDMARXSOFN;
   input          LLDMARXEOFN;
   input          LLDMARXSOPN;
   input          LLDMARXEOPN;
   input          LLDMARXSRCRDYN;
   input          DMALLRXDSTRDYN; 
   // local link TX interface
   input [31:0]   DMALLTXD;
   input [3:0]    DMALLTXREM;
   input          DMALLTXSOFN;
   input          DMALLTXEOFN;
   input          DMALLTXSOPN;
   input          DMALLTXEOPN;
   input          DMALLTXSRCRDYN; 
   input          LLDMATXDSTRDYN;

   // crc data out
   output [31:0]  crc_tx;
   output [31:0]  crc_rx;
 
  /*AUTOREG*/
  /*AUTOWIRE*/
  reg             tx_start;
  reg             rx_start;
  reg             tx_data_valid;
  reg             rx_data_valid;
  reg [31:0]      tx_data;
  reg [31:0]      rx_data;
  wire [31:0]     data_in;
  /**************************************************************************/
  always @(posedge clk)
    begin
      if (!rst_n)
         begin
	   tx_start <= 1'b0;
	 end
      else if (~LLDMATXDSTRDYN && ~DMALLTXSRCRDYN && ~DMALLTXSOPN)
	 begin
	   tx_start <= 1'b1;
	 end
      else if (~LLDMATXDSTRDYN && ~DMALLTXSRCRDYN && ~DMALLTXEOPN)
	 begin
	   tx_start <= 1'b0;
	 end
    end

  always @(posedge clk)
    begin
      if (!rst_n)
         begin
	   rx_start <= 1'b0;
	 end
      else if (~LLDMARXSRCRDYN && ~DMALLRXDSTRDYN && ~LLDMARXSOPN)
	 begin
	   rx_start <= 1'b1;
	 end
      else if (~LLDMARXSRCRDYN && ~DMALLRXDSTRDYN && ~LLDMARXEOPN)
	 begin
	   rx_start <= 1'b0;
	 end
    end

  always @(posedge clk)
    begin
      if (~LLDMATXDSTRDYN && ~DMALLTXSRCRDYN)
         tx_data <= DMALLTXD;
    end

  always @(posedge clk)
    begin
      if (~LLDMARXSRCRDYN && ~DMALLRXDSTRDYN)
         rx_data <= LLDMARXD;
    end

  always @(posedge clk)
    begin
      if (!rst_n)
         begin
           tx_data_valid = 1'b0;
	 end
      else if (~LLDMATXDSTRDYN && ~DMALLTXSRCRDYN && ~DMALLTXSOPN)
	 begin
           tx_data_valid = 1'b1;
	 end
      else if (~LLDMATXDSTRDYN && ~DMALLTXSRCRDYN && tx_start)
	 begin
           tx_data_valid = 1'b1;
	 end
      else
         begin
           tx_data_valid = 1'b0;
	 end
    end

  always @(posedge clk)
    begin
      if (!rst_n)
         begin
           rx_data_valid = 1'b0;
	 end
      else if (~LLDMARXSRCRDYN && ~DMALLRXDSTRDYN && ~LLDMARXSOPN)
	 begin
           rx_data_valid = 1'b1;
	 end
      else if (~LLDMARXSRCRDYN && ~DMALLRXDSTRDYN && rx_start)
	 begin
           rx_data_valid = 1'b1;
	 end
      else
         begin
           rx_data_valid = 1'b0;
	 end
    end

  assign crc_rst = ~rst_n;
  /**************************************************************************/
   wire [31:0] crc_tx;
   wire [31:0] crc_rx;
  crc
   crc0(.crc_out(crc_tx),
	.data_in(tx_data),
	.data_valid(tx_data_valid),
	/*AUTOINST*/
	// Inputs
	.clk				(clk),
	.crc_rst			(crc_rst));
  crc
   crc1(.crc_out(crc_rx),
	.data_in(rx_data),
	.data_valid(rx_data_valid),
	/*AUTOINST*/
	// Inputs
	.clk				(clk),
	.crc_rst			(crc_rst));
endmodule
 
// Local Variables:
// verilog-library-directories:(".")
// verilog-library-files:("lldma_exerciser.v")
// verilog-library-extensions:(".v" ".h")
// End:
