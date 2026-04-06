//-------------------------------------------------------------------------
// Module Name: ADC_Reg_ctrl1
// Description: SPI slave Register module that receives a 16-bit control register
// Date: 08-08-2025
// Author: Pratheek
// Version: v1.1
//-------------------------------------------------------------------------
module ADC_Reg_ctrl1 #(
        parameter ADDR_SIZE = 16,
        parameter SIZE = 32

     )(
        input logic rst_n_i,                        // Active Low Reset
        input logic sclk_i,                         // SPI Clock
        input logic mosi_i,                         // Master Out Slave In
        input logic slave_active_i,                 // Slave Active
        input logic read_en_i,                      // Read Enable
        input logic write_en_i,                     // Write Enable
        input logic [ADDR_SIZE-1:0] reg_addr_i,     // Register Address

        //To Master
        output logic miso_o,                        // Master In Slave Out

        output	logic [15:0]	SPI_ctrl_o	        //control data

);

    // Defaults
    localparam CONTROL_DATA =32'h0000_0002;


    // ---------------------------------------------------------------------------
    // Address decoding and read/write logic
    // ---------------------------------------------------------------------------

        logic enable;

        always_comb begin
            if (slave_active_i) begin
                        case (reg_addr_i)
                                16'b0000000000000000 : enable = 1'b1; // cntrl
                            default : enable = 1'b0;
                        endcase
            end
            else begin
                enable = 1'b0;
            end
        end

//----------------------------------------R0----------------------------------------
                SEG_REG_ctrld #(.REG_SIZE(16),
                  .DEFAULT(CONTROL_DATA),
                  .SIZE(SIZE)) R0_0 (
                .rst_n_i(rst_n_i),
                .sclk_i(sclk_i),
                .MOSI_i(mosi_i),
                .enable_i(enable),
                .wenable_i(write_en_i),
                .renable_i(read_en_i),
                .MISO_o(miso_o),
                .RegOut_o(SPI_ctrl_o)
        );
  
    endmodule
