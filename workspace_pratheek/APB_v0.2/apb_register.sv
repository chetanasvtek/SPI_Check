//-----------------------------------------------------------------------------
// Title         : APB Register Block
// Description   : This module implements a register block that interfaces with an APB3 slave interface. 
// It includes various types of registers (RW, RO, WO, W1C, W1S, RC, TOW) and handles read/write operations based on the APB protocol.
// Version       : 0.3
// Author        : Pratheek Shet
// Date          : 07 May 2026
//-----------------------------------------------------------------------------
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

    input  logic [31:0]       dev_id_ro_i,     // RO Register input Signal
    input  logic [31:0]       error_count_rc_i, // RC Register input Signal

    output logic [APB_DW-1:0] o_reg_rdata,
    output logic              o_reg_ready,
    output logic              o_reg_error,

    // Exported Register Ports for Hardware Integration
    output logic [31:0]       global_ctrl_o,
    output logic [31:0]       command_wo_o,
    output logic [31:0]       status_w1c_o,
    output logic [31:0]       sticky_set_w1s_o,
    output logic [31:0]       error_count_rc_o,
    output logic [31:0]       polarity_tow_o
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
    logic addr_hit;

    always_comb begin
        addr_hit = 1'b0;
        if (i_reg_wr_en) begin
            case (i_reg_addr)
                16'h0000: addr_hit = 1'b0;
                16'h0004: addr_hit = 1'b0;
                16'h0008: addr_hit = 1'b0;
                16'h000C: addr_hit = 1'b0;
                16'h0014: addr_hit = 1'b0;
                default : addr_hit = 1'b1;
            endcase
        end
        else if (i_reg_rd_en) begin
            case (i_reg_addr)
                16'h0000: addr_hit = 1'b0;
                16'h0008: addr_hit = 1'b0;
                16'h000C: addr_hit = 1'b0;
                16'h0010: addr_hit = 1'b0;
                16'h0014: addr_hit = 1'b0;
                16'h0018: addr_hit = 1'b0;
                default : addr_hit = 1'b1;
            endcase
        end
    end

    // Write Logic
    always_ff @(posedge i_clk or negedge i_resetn) begin
        if (!i_resetn) begin
            reg_global_ctrl <= 32'h0;
            reg_command_wo <= 32'h0;
            reg_status_w1c <= 32'h12345678;
            reg_sticky_set_w1s <= 32'h0;
            reg_polarity_tow <= 32'hFFFFFFFF;
        end 
        else if (i_reg_wr_en && i_reg_enable) begin
            case (i_reg_addr)
                16'h0000: reg_global_ctrl <= i_reg_wdata;
                16'h0004: reg_command_wo <= i_reg_wdata;
                16'h0008: reg_status_w1c <= reg_status_w1c & ~i_reg_wdata;
                16'h000C: reg_sticky_set_w1s <= reg_sticky_set_w1s | i_reg_wdata;
                16'h0014: reg_polarity_tow <= reg_polarity_tow ^ i_reg_wdata;
            endcase
        end
        else if (i_reg_rd_en) begin
            if (i_reg_addr == 16'h0010) reg_error_count_rc <= 32'h0;
        end
    end

    // Sampling logic for externally driven registers
    always_ff @(posedge i_clk or negedge i_resetn) begin
        if (!i_resetn) begin
            reg_dev_id_ro <= 32'h12345678;
            reg_error_count_rc <= 32'h12345678;
        end else begin
            reg_dev_id_ro <= dev_id_ro_i;
            reg_error_count_rc <= error_count_rc_i;
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

    assign o_reg_ready = (i_reg_wr_en || i_reg_rd_en);
    assign o_reg_error = addr_hit;

    // Export Register Values to Output Ports
    assign global_ctrl_o     = reg_global_ctrl;
    assign command_wo_o      = reg_command_wo;
    assign status_w1c_o      = reg_status_w1c;
    assign sticky_set_w1s_o  = reg_sticky_set_w1s;
    assign error_count_rc_o  = reg_error_count_rc;
    assign polarity_tow_o    = reg_polarity_tow;

endmodule