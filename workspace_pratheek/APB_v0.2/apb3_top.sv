//------------------------------------------------------------------------------
//  Module      : apb3_top
//  Description : Top-level APB3 wrapper connecting the APB slave interface to the
//                register block.
//  Version     : 1.0
//  Author      : Generated
//  Date        : 04 May 2026
//------------------------------------------------------------------------------

import apb3_pkg::*;
module apb3_top (

    input  logic                    i_pclk,
    input  logic                    i_presetn,

    input  logic [APB_AW-1:0]       i_paddr,
    input  logic                    i_psel,
    input  logic                    i_penable,
    input  logic                    i_pwrite,
    input  logic [APB_DW-1:0]       i_pwdata,

    output logic [APB_DW-1:0]       o_prdata,
    output logic                    o_pready,
    output logic                    o_pslverr

    // Exported Register Ports for Hardware Integration
    output logic [31:0]               global_ctrl_o,
    output logic [31:0]               command_wo_o,
    output logic [31:0]               status_w1c_o,
    output logic [31:0]               sticky_set_w1s_o,
    output logic [31:0]               error_count_rc_o,
    output logic [31:0]               polarity_tow_o,

    input  logic [31:0]               dev_id_ro_i,     // RO Register input Signal
    input  logic [31:0]               error_count_rc_i // RC Register input Signal
);

    //--------------------------------------------------------------------------
    // Register interface signals
    //--------------------------------------------------------------------------

    logic                    reg_wr_en;
    logic                    reg_rd_en;
    logic [APB_AW-1:0]       reg_addr;
    logic [APB_DW-1:0]       reg_wdata;
    logic [APB_DW-1:0]       reg_rdata;
    logic                    reg_ready;
    logic                    reg_error;
    logic                    reg_enable;

    //--------------------------------------------------------------------------
    // APB slave interface instance
    //--------------------------------------------------------------------------

    apb3_slave_if u_apb3_slave_if (
        .i_pclk      (i_pclk),
        .i_presetn   (i_presetn),
        .i_paddr     (i_paddr),
        .i_psel      (i_psel),
        .i_penable   (i_penable),
        .i_pwrite    (i_pwrite),
        .i_pwdata    (i_pwdata),

        .o_prdata    (o_prdata),
        .o_pready    (o_pready),
        .o_pslverr   (o_pslverr),

        .o_reg_en    (reg_enable),
        .o_reg_wr_en (reg_wr_en),
        .o_reg_rd_en (reg_rd_en),
        .o_reg_addr  (reg_addr),
        .o_reg_wdata (reg_wdata),

        .i_reg_rdata (reg_rdata),
        .i_reg_ready (reg_ready),
        .i_reg_error (reg_error)
    );

    //--------------------------------------------------------------------------
    // Register block instance
    //--------------------------------------------------------------------------

    apb_register u_reg_block (
        .i_clk        (i_pclk),
        .i_resetn     (i_presetn),
        .i_reg_wr_en  (reg_wr_en),
        .i_reg_rd_en  (reg_rd_en),
        .i_reg_addr   (reg_addr),
        .i_reg_wdata  (reg_wdata),
        .i_reg_enable (reg_enable),

        .o_reg_rdata  (reg_rdata),
        .o_reg_ready  (reg_ready),
        .o_reg_error  (reg_error),

        .dev_id_ro_i       (dev_id_ro_i),
        .error_count_rc_i  (error_count_rc_i),
        .global_ctrl_o      (global_ctrl_o),
        .command_wo_o       (command_wo_o),
        .status_w1c_o       (status_w1c_o),
        .sticky_set_w1s_o   (sticky_set_w1s_o),
        .error_count_rc_o   (error_count_rc_o),
        .polarity_tow_o     (polarity_tow_o)
    );

endmodule
