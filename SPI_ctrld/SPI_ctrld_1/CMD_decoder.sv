//-------------------------------------------------------------------------
// Module Name: CMD_decoder
// Description: SPI slave Command Decoder module that receives a 16-bit control register
// Date: 08-08-2025
// Author: Pratheek
// Version: v1.1
//-------------------------------------------------------------------------
module CMD_decoder #(parameter int SLAVE_ID=0, 
    parameter int ADDR_SIZE=16, 
    parameter int SLAVE_ID_SIZE=8, 
    parameter int CMD_SIZE=32

    )(
    input logic enable_i, //Decodes during Deadzone period + Trans Data
    input logic [CMD_SIZE-1:0] cmd_i,
    output logic read_en_o,
    output logic write_en_o,
    output logic slave_active_o,
    output logic [ADDR_SIZE-1:0] reg_addr_o
);

    logic rw;
    logic [ADDR_SIZE-1:0] reg_addr;
    logic [SLAVE_ID_SIZE-1:0] slave_id;

    logic slave_act;

    always_comb begin
        reg_addr = cmd_i[ADDR_SIZE-1:0];
        slave_id = cmd_i[ADDR_SIZE + SLAVE_ID_SIZE - 1:ADDR_SIZE];
        rw = cmd_i[31];
        if(enable_i) begin
            slave_act = (slave_id == SLAVE_ID)? 1'b1 : 1'b0;
            if(slave_act) begin
                read_en_o      =  ~rw;
                write_en_o     =  rw;
                reg_addr_o     =  reg_addr;
            end
            else begin
                read_en_o      =  1'b0;
                write_en_o     =  1'b0;
                reg_addr_o     =  '0;
            end
        end
        else begin
            read_en_o      =  1'b0;
            write_en_o     =  1'b0;
            reg_addr_o     =  '0;
            slave_act      =  1'b0;
        end
    end

    assign slave_active_o = slave_act;
endmodule