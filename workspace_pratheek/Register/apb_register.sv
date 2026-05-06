// Generated Register Block: apb_register
import apb3_pkg::*;
module apb_register #( 
) (
    input  logic              i_clk,
    input  logic              i_resetn,
    // Register Interface
    input  logic              i_reg_enable,
    input  logic              i_reg_wr_en,
    input  logic              i_reg_rd_en,
    input  logic [APB_AW-1:0] i_reg_addr,
    input  logic [APB_DW-1:0] i_reg_wdata,
    output logic [APB_DW-1:0] o_reg_rdata,
    output logic              o_reg_ready,
    output logic              o_reg_error
);

    // Internal Register Declarations
    logic [31:0] reg_global_ctrl;
    logic [31:0] reg_command_wo;
    logic [31:0] reg_status_w1c;
    logic [31:0] reg_sticky_set_w1s;
    logic [31:0] reg_error_count_rc;
    logic [31:0] reg_polarity_tow;
    logic [31:0] reg_dev_id_ro;

    // Address Decoding and Error Logic
    logic rd_addr_hit;
    logic wr_addr_hit;

    always_comb begin
        rd_addr_hit = 1'b0; // Default to hit, will be cleared if no match
        wr_addr_hit = 1'b0; // Default to hit, will be cleared if no match
        if (i_reg_wr_en) begin
            rd_addr_hit = 1'b1; // No read hit during write
            case (i_reg_addr)
                16'h0000: wr_addr_hit = 1'b1;
                16'h0004: wr_addr_hit = 1'b1;
                16'h0008: wr_addr_hit = 1'b1;
                16'h000C: wr_addr_hit = 1'b1;
                16'h0010: wr_addr_hit = 1'b1;
                16'h0014: wr_addr_hit = 1'b1;
            endcase
        end
        else if (i_reg_rd_en) begin
            wr_addr_hit = 1'b1; // No write hit during read
            case (i_reg_addr)
                16'h0000: rd_addr_hit = 1'b1;
                16'h0008: rd_addr_hit = 1'b1;
                16'h000C: rd_addr_hit = 1'b1;
                16'h0010: rd_addr_hit = 1'b1;
                16'h0014: rd_addr_hit = 1'b1;
                16'h0018: rd_addr_hit = 1'b1; // RO write
            endcase
        end   
    end

    // Write Logic
    always_ff @(posedge i_clk or negedge i_resetn) begin
        if (!i_resetn) begin
            reg_global_ctrl     <= 32'h0;
            reg_command_wo      <= 32'h0;
            reg_status_w1c      <= 32'h12345678;
            reg_sticky_set_w1s  <= 32'h0;
            reg_error_count_rc  <= 32'h12345678;
            reg_polarity_tow    <= 32'hFFFFFFFF;
            reg_dev_id_ro       <= 32'h12345678;
        end 
        else if (i_reg_wr_en && i_reg_enable) begin
            case (i_reg_addr)
                16'h0000: reg_global_ctrl       <= i_reg_wdata;
                16'h0004: reg_command_wo        <= i_reg_wdata;
                16'h0008: reg_status_w1c        <= reg_status_w1c & ~i_reg_wdata;
                16'h000C: reg_sticky_set_w1s    <= reg_sticky_set_w1s | i_reg_wdata;
                16'h0014: reg_polarity_tow      <= reg_polarity_tow ^ i_reg_wdata;
            endcase
        end
        else if (i_reg_rd_en) begin
            if (i_reg_addr == 16'h0010) reg_error_count_rc <= 32'h0;
        end
    end

    // Read Logic
    always_comb begin
        o_reg_rdata = 32'h0;
            case (i_reg_addr)
                16'h0000: o_reg_rdata = reg_global_ctrl;
                16'h0008: o_reg_rdata = reg_status_w1c;
                16'h000C: o_reg_rdata = reg_sticky_set_w1s;
                16'h0010: o_reg_rdata = reg_error_count_rc;
                16'h0014: o_reg_rdata = reg_polarity_tow;
                16'h0018: o_reg_rdata = reg_dev_id_ro;
            endcase
        end
    assign o_reg_ready = 1'b1; // Always ready for simplicity
    assign o_reg_error = (!rd_addr_hit || !wr_addr_hit);


endmodule