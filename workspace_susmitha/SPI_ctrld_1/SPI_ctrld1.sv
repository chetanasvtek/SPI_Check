//-------------------------------------------------------------------------
// Module Name: SPI_ctrld1
// Description: SPI slave module that receives a 16-bit control register
// Date: 08-08-2025
// Author: Pratheek
// Version: v1.1
//-------------------------------------------------------------------------
module SPI_ctrld1 #( 
        parameter SLAVE_ID = 36,
        parameter CMD_SIZE = 32,
        parameter ADDR_SIZE = 16,
        parameter SLAVE_ID_SIZE = 8,
        parameter DATA_SIZE=32
)(
    input logic rst_n_i,                    // Active Low Reset

    input logic sclk_i,                     // SPI Clock
    input logic cs_i,                       // Active High Chip select
    input logic mosi_i,                     // Master out Slave In
    output logic miso_o,                    // Master In Slave out

    output	logic [15:0]	SPI_ctrld1_o    // controls Output     
);


    logic trans_cmd_active;
    logic active_decode;
    logic [CMD_SIZE-1:0] cmd;
    logic read_en;
    logic write_en;
    logic [ADDR_SIZE-1:0] reg_addr;
    logic slave_active;

    Track_trans pac_tracker (
        .cs_i(cs_i),
        .rst_n_i(rst_n_i),
        .trans_cmd_o(trans_cmd_active),
        .active_decode_o(active_decode)
    );


    SPI_CMD_SIPO #(
        .CMD_SIZE(CMD_SIZE)
    ) cmd_sipo_inst (
        .rst_n_i(rst_n_i),
        .sclk_i(sclk_i),
        .trans_cmd_i(trans_cmd_active),
        .mosi_i(mosi_i),
        .cmd_o(cmd)
    );



    CMD_decoder #(.SLAVE_ID(SLAVE_ID),
                  .ADDR_SIZE(ADDR_SIZE),
                  .SLAVE_ID_SIZE(SLAVE_ID_SIZE),
                  .CMD_SIZE(CMD_SIZE))
         decoder (
                .enable_i(active_decode),
                .cmd_i(cmd),
                .read_en_o(read_en),
                .write_en_o(write_en),
                .reg_addr_o(reg_addr), 
                .slave_active_o(slave_active)
    );

    ADC_Reg_ctrl1 #(.ADDR_SIZE(ADDR_SIZE),
              .SIZE(DATA_SIZE)) 
            reg_space0 (
                .rst_n_i(rst_n_i),
                .sclk_i(sclk_i),
                .mosi_i(mosi_i),
                .slave_active_i(slave_active),
                .read_en_i(read_en),
                .write_en_i(write_en),
                .reg_addr_i(reg_addr),
                .miso_o(miso_o),

                .SPI_ctrl_o(SPI_ctrld1_o)
    );


endmodule

