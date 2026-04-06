//-------------------------------------------------------------------------
// Module Name: SPI_CMD_SIPO
// Description: SPI slave command Serial in Parallel Out module that receives a 16-bit control register
// Date: 08-08-2025
// Author: Pratheek
// Version: v1.1
//-------------------------------------------------------------------------
module SPI_CMD_SIPO #(
    parameter CMD_SIZE = 32
)(
    input  logic             rst_n_i,               // Active Low Reset
    input  logic             sclk_i,                // SPI Clock
    input  logic             trans_cmd_i,           // Transmit Command
    input  logic             mosi_i,                // Master out Slave In
    output logic [CMD_SIZE-1:0] cmd_o               // Command Output
);

    logic cmd;
    assign cmd = mosi_i & trans_cmd_i;

    logic sclk_en_i;
    assign sclk_en_i = sclk_i & trans_cmd_i;

    always_ff @(posedge sclk_en_i, negedge rst_n_i) begin
        if (!rst_n_i)
            cmd_o <= '0;
        else
          //  cmd_o <= (trans_cmd_i) ? { cmd, cmd_o[CMD_SIZE-1:1]} : cmd_o;
            cmd_o <= (trans_cmd_i) ? { cmd_o[CMD_SIZE-2:0], cmd} : cmd_o;
    end

endmodule
