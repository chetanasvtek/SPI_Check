//-------------------------------------------------------------------------
// Module Name: SEG_REG
// Description: SPI slave Register module that receives a 16-bit control register
// Date: 08-08-2025
// Author: Pratheek
// Version: v1.1
//-------------------------------------------------------------------------
module SEG_REG_ctrld #(
    parameter SIZE = 32,
    parameter REG_SIZE = 32,
    parameter DEFAULT = 0
    )(
    input logic rst_n_i,                    // Active Low Reset
    input logic sclk_i,                     // SPI Clock
    input logic MOSI_i,                     // Master Out Slave In
    input logic enable_i,                   // Enable Input
    input logic wenable_i,                  // Write Enable Input
    input logic renable_i,                  // Read Enable Input
    output logic MISO_o,                    // Master In Slave Out
    output logic [REG_SIZE-1:0] RegOut_o    // Register output
);

    localparam COUNT_SIZE = $clog2(SIZE);

    logic [SIZE-1:0] Reg;
    logic [SIZE-1:0] shift_reg;
    logic MISO;
    logic [COUNT_SIZE-1:0] count; 
    logic [COUNT_SIZE-1:0] bit_cnt; 
    logic Preload_MISO;
    //src = 1 | from MOSI line
    //src = 0 | from din line

    //dst = 1 | from MISO line
    //dst = 0 | from dout line

    always_ff @(posedge sclk_i, negedge rst_n_i) begin
        if(!rst_n_i) begin
            Reg <= DEFAULT;
            MISO  <= 1'b0;
            count <= 5'b11110;
            bit_cnt <= 5'b00000;
            shift_reg <= '0;

        end
        else if(enable_i) begin
                if (wenable_i) begin
                        // Reg <= {Reg[SIZE-2:0], MOSI_i};
                        if (bit_cnt == SIZE-1) begin
                            Reg     <= {shift_reg[SIZE-2:0], MOSI_i};  // Full SIZE-bit value
                            shift_reg        <= '0; 
                            bit_cnt          <= '0; 
                        end
                        else begin
                            shift_reg <= {shift_reg[SIZE-2:0], MOSI_i};         // Shift in mosi_i
                            bit_cnt   <= bit_cnt + 1'b1;                        // Increment bit counter
                            end
                end
                else if(renable_i) begin
                        MISO <= Reg[count];
                        count <= count - 1'b1;
                end
                else begin
                        MISO <= 1'b0;
                        count <= 5'b11110;
                        bit_cnt <= 5'b00000;
                        shift_reg <= '0;
                end
        end
        else begin
                    MISO  <= 1'b0;
                    count <= 5'b11110;
                    bit_cnt <= 5'b00000;
                    shift_reg <= '0;
        end
    end

    always @(posedge sclk_i or negedge enable_i)
    begin
    if (!enable_i)
    begin
      Preload_MISO <= 1'b1;
    end
    else
    begin
      Preload_MISO <= 1'b0;
    end
  end

    //During Writing and reading RegOut value changes
    assign MISO_Mux = Preload_MISO ? Reg[SIZE-1] : MISO;
    assign MISO_o =  renable_i? MISO_Mux : 1'b0;
    assign RegOut_o = Reg[REG_SIZE-1:0];

endmodule