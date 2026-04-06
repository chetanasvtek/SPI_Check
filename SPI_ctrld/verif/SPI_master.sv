module SPI_master
  #(parameter SPI_MODE = 0,
    parameter CLKS_PER_HALF_BIT = 2)
  (
   // Control/Data Signals
   input        Rst_L_i,     // FPGA Reset
   input        Clk_i,       // FPGA Clock
   
   // TX (MOSI) Signals
   input  [31:0] TX_Word_i,        // 32-bit word to transmit on MOSI
   input         TX_DV_i,          // Data Valid Pulse with TX_Word_i
   output reg    TX_Ready_o,       // Transmit Ready for next word
   
   // RX (MISO) Signals
   output reg        RX_DV_o,     // Data Valid pulse (1 clock cycle)
   output reg [31:0] RX_Word_o,   // 32-bit word received on MISO

   // SPI Interface
   output reg SPI_Clk_o,
   input      SPI_MISO_i,
   output reg SPI_MOSI_o,
   output reg SPI_CS_o // Chip Select, active 
   );

  wire w_CPOL;
  wire w_CPHA;

  reg [$clog2(CLKS_PER_HALF_BIT*2)-1:0] r_SPI_Clk_Count;
  reg r_SPI_Clk;
  reg [6:0] r_SPI_Clk_Edges;
  reg r_Leading_Edge;
  reg r_Trailing_Edge;
  reg r_TX_DV;

  reg [4:0] r_RX_Bit_Count;
  reg [4:0] r_TX_Bit_Count;
  reg [31:0] r_TX_Word;

  assign w_CPOL  = (SPI_MODE == 2) | (SPI_MODE == 3);
  assign w_CPHA  = (SPI_MODE == 1) | (SPI_MODE == 3);

  always_ff @(posedge Clk_i or negedge Rst_L_i) begin
    if (!Rst_L_i)
      SPI_CS_o <= 1'b0;
    else
      SPI_CS_o <= (r_SPI_Clk_Edges > 0) ? 1'b1 : 1'b0;
  end

  always @(posedge Clk_i or negedge Rst_L_i)
  begin
    if (~Rst_L_i)
    begin
      TX_Ready_o      <= 1'b0;
      r_SPI_Clk_Edges <= 0;
      r_Leading_Edge  <= 1'b0;
      r_Trailing_Edge <= 1'b0;
      r_SPI_Clk       <= w_CPOL;
      r_SPI_Clk_Count <= 0;
    end
    else
    begin
      r_Leading_Edge  <= 1'b0;
      r_Trailing_Edge <= 1'b0;
      
      if (TX_DV_i)
      begin
        TX_Ready_o      <= 1'b0;
        r_SPI_Clk_Edges <= 64;
      end
      else if (r_SPI_Clk_Edges > 0)
      begin
        TX_Ready_o <= 1'b0;
        
        if (r_SPI_Clk_Count == CLKS_PER_HALF_BIT*2-1)
        begin
          r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1'b1;
          r_Trailing_Edge <= 1'b1;
          r_SPI_Clk_Count <= 0;
          r_SPI_Clk       <= ~r_SPI_Clk;
        end
        else if (r_SPI_Clk_Count == CLKS_PER_HALF_BIT-1)
        begin
          r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1'b1;
          r_Leading_Edge  <= 1'b1;
          r_SPI_Clk_Count <= r_SPI_Clk_Count + 1'b1;
          r_SPI_Clk       <= ~r_SPI_Clk;
        end
        else
        begin
          r_SPI_Clk_Count <= r_SPI_Clk_Count + 1'b1;
        end
      end  
      else
      begin
        TX_Ready_o <= 1'b1;
      end
    end
  end

  always @(posedge Clk_i or negedge Rst_L_i)
  begin
    if (~Rst_L_i)
    begin
      r_TX_Word <= 32'h00000000;
      r_TX_DV   <= 1'b0;
    end
    else
    begin
      r_TX_DV <= TX_DV_i;
      if (TX_DV_i)
        r_TX_Word <= TX_Word_i;
    end
  end

  always @(posedge Clk_i or negedge Rst_L_i)
  begin
    if (~Rst_L_i)
    begin
      SPI_MOSI_o     <= 1'b0;
      r_TX_Bit_Count <= 5'b11111;
    end
    else
    begin
      if (TX_Ready_o)
        r_TX_Bit_Count <= 5'b11111;
      else if (r_TX_DV & ~w_CPHA)
      begin
        SPI_MOSI_o     <= r_TX_Word[31];
        r_TX_Bit_Count <= 5'b11110;
      end
      else if ((r_Leading_Edge & w_CPHA) | (r_Trailing_Edge & ~w_CPHA))
      begin
        r_TX_Bit_Count <= r_TX_Bit_Count - 1'b1;
        SPI_MOSI_o     <= r_TX_Word[r_TX_Bit_Count];
      end
    end
  end

  always @(posedge Clk_i or negedge Rst_L_i)
  begin
    if (~Rst_L_i)
    begin
      RX_Word_o      <= 32'h00000000;
      RX_DV_o        <= 1'b0;
      r_RX_Bit_Count <= 5'b11111;
    end
    else
    begin
      RX_DV_o   <= 1'b0;
      if (TX_Ready_o)
        r_RX_Bit_Count <= 5'b11111;
      else if ((r_Leading_Edge & ~w_CPHA) | (r_Trailing_Edge & w_CPHA))
      begin
        RX_Word_o[r_RX_Bit_Count] <= SPI_MISO_i;
        r_RX_Bit_Count            <= r_RX_Bit_Count - 1'b1;
        if (r_RX_Bit_Count == 5'b00000)
          RX_DV_o <= 1'b1;
      end
    end
  end

  always @(posedge Clk_i or negedge Rst_L_i)
  begin
    if (~Rst_L_i)
      SPI_Clk_o <= w_CPOL;
    else
      SPI_Clk_o <= r_SPI_Clk;
  end

endmodule
