//------------------------------------------------------------------------------
//  Module      : apb3_slave_if (spec-clean)
//  Description : APB3 slave interface (protocol compliant)
//  Version     : 1.0
//  Author      : Pratheek
//  Date        : 06 May 2026
//------------------------------------------------------------------------------

import apb3_pkg::*;

module apb3_slave_if (

    // clock & reset
    input  logic                    i_pclk,
    input  logic                    i_presetn,

    // APB3 interface
    input  logic [APB_AW-1:0]       i_paddr,
    input  logic                    i_psel,
    input  logic                    i_penable,
    input  logic                    i_pwrite,
    input  logic [APB_DW-1:0]       i_pwdata,

    output logic [APB_DW-1:0]       o_prdata,
    output logic                    o_pready,
    output logic                    o_pslverr,

    // Register interface
    output logic                    o_reg_en,
    output logic                    o_reg_wr_en,
    output logic                    o_reg_rd_en,
    output logic [APB_AW-1:0]       o_reg_addr,
    output logic [APB_DW-1:0]       o_reg_wdata,

    input  logic [APB_DW-1:0]       i_reg_rdata,
    input  logic                    i_reg_ready,
    input  logic                    i_reg_error
);

    //--------------------------------------------------------------------------
    // FSM
    //--------------------------------------------------------------------------

    typedef enum logic {
        IDLE,
        ACCESS
    } state_e;

    state_e state_p, state_n;

    always_ff @(posedge i_pclk or negedge i_presetn) begin
        if (!i_presetn)
            state_p <= IDLE;
        else
            state_p <= state_n;
    end

    always_comb begin
        state_n = state_p;

        case (state_p)

            IDLE: begin
                if (i_psel && !i_penable)
                    state_n = ACCESS;
            end

            ACCESS: begin
                if (i_reg_ready) begin
                        state_n = IDLE;
                end
            end

        endcase
    end

    //--------------------------------------------------------------------------
    // Register interface (single-cycle pulse at completion)
    //--------------------------------------------------------------------------

    always_comb begin
        o_reg_wr_en = 1'b0;
        o_reg_rd_en = 1'b0;

        if (i_psel) begin
            if (i_pwrite)
                o_reg_wr_en = 1'b1;
            else
                o_reg_rd_en = 1'b1;
        end
    end

    assign o_reg_addr   = i_paddr;
    assign o_reg_wdata  = i_pwdata;
    assign o_reg_en     = i_penable;

    //--------------------------------------------------------------------------
    // APB outputs
    //--------------------------------------------------------------------------

    assign o_pready  = ((state_p == ACCESS) && i_penable) ? i_reg_ready : 1'b0;
    assign o_prdata  = ((state_p == ACCESS) && i_psel && i_penable && !i_pwrite) ? i_reg_rdata : '0;
    assign o_pslverr = ((state_p == ACCESS) && i_psel && i_penable && i_reg_ready) ? i_reg_error : 1'b0;

endmodule