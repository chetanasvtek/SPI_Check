//==============================================================================
// APB CSR REGISTER BLOCK
//------------------------------------------------------------------------------
// Features
//   - Multiple Registers
//   - Multiple Fields per Register
//   - Mixed Access Policies
//   - Illegal Access Detection
//   - Read/Write Permission Checking
//   - Clean Address Decode
//   - APB PSLVERR Style Error Reporting
//
// Supported Access Types
//   RW   : Read Write
//   RO   : Read Only
//   WO   : Write Only
//   RC   : Read Clear
//   W1C  : Write 1 Clear
//   W1S  : Write 1 Set
//   TOW  : Toggle On Write
//
//==============================================================================

import apb3_pkg::*;
module apb_register (

    input  logic              i_clk,
    input  logic              i_resetn,
    //--------------------------------------------------------------------------
    // APB/Register Interface
    //--------------------------------------------------------------------------
    input  logic              i_reg_enable,
    input  logic              i_reg_wr_en,
    input  logic              i_reg_rd_en,
    input  logic [APB_AW-1:0] i_reg_addr,
    input  logic [APB_DW-1:0] i_reg_wdata,
    //--------------------------------------------------------------------------
    // Hardware Inputs
    //--------------------------------------------------------------------------
    input  logic [7:0]        hw_state_ro_i,
    input  logic [15:0]       hw_error_count_rc_i,
    input  logic [31:0]       hw_version_ro_i,
    input  logic [7:0]        hw_fifo_level_ro_i,
    //--------------------------------------------------------------------------
    // APB Outputs
    //--------------------------------------------------------------------------
    output logic [31:0]       o_reg_rdata,
    output logic              o_reg_ready,
    output logic              o_reg_error,
    //--------------------------------------------------------------------------
    // Exported Outputs
    //--------------------------------------------------------------------------
    output logic              enable_o,
    output logic [2:0]        mode_o,
    output logic              start_o,

    output logic [7:0]        irq_enable_o,
    output logic [7:0]        polarity_o,

    output logic [7:0]        threshold_o,
    output logic              soft_reset_o
);

    //==========================================================================
    // REGISTER TABLE
    //==========================================================================
    //
    //--------------------------------------------------------------------------
    // REG_CTRL       : 0x0000
    //--------------------------------------------------------------------------
    // 31:16  error_count     RC
    // 15:8   hw_state        RO
    // 7:5    reserved
    // 4      start           WO
    // 3:1    mode            RW
    // 0      enable          RW
    //
    //--------------------------------------------------------------------------
    // REG_IRQ_CTRL   : 0x0004
    //--------------------------------------------------------------------------
    // 31:24  polarity        TOW
    // 23:16  sticky_irq      W1S
    // 15:8   irq_status      W1C
    // 7:0    irq_enable      RW
    //
    //--------------------------------------------------------------------------
    // REG_STATUS     : 0x0008
    //--------------------------------------------------------------------------
    // 31:16  reserved
    // 15:8   error_flags     RC
    // 7:0    fifo_level      RO
    //
    //--------------------------------------------------------------------------
    // REG_CONFIG     : 0x000C
    //--------------------------------------------------------------------------
    // 31:16  timeout         RW
    // 15:9   reserved
    // 8      soft_reset      WO
    // 7:0    threshold       RW
    //
    //--------------------------------------------------------------------------
    // REG_VERSION    : 0x0010
    //--------------------------------------------------------------------------
    // 31:0   version_id      RO
    //
    //==========================================================================

    //==========================================================================
    // ADDRESS MAP
    //==========================================================================
    localparam logic [15:0] REG_CTRL_ADDR      = 16'h0000;
    localparam logic [15:0] REG_IRQ_CTRL_ADDR  = 16'h0004;
    localparam logic [15:0] REG_STATUS_ADDR    = 16'h0008;
    localparam logic [15:0] REG_CONFIG_ADDR    = 16'h000C;
    localparam logic [15:0] REG_VERSION_ADDR   = 16'h0010;
    //==========================================================================
    // INTERNAL REGISTERS
    //==========================================================================

    //--------------------------------------
    // CTRL REGISTER
    //--------------------------------------
    logic        reg_enable;
    logic [2:0]  reg_mode;
    logic        reg_start;
    logic [7:0]  reg_hw_state_ro;
    logic [15:0] reg_error_count_rc;

    //--------------------------------------
    // IRQ REGISTER
    //--------------------------------------
    logic [7:0] reg_irq_enable;
    logic [7:0] reg_irq_status;
    logic [7:0] reg_sticky_irq;
    logic [7:0] reg_polarity;

    //--------------------------------------
    // STATUS REGISTER
    //--------------------------------------
    logic [7:0] reg_fifo_level_ro;
    logic [7:0] reg_error_flags_rc;

    //--------------------------------------
    // CONFIG REGISTER
    //--------------------------------------
    logic [7:0]  reg_threshold;
    logic        reg_soft_reset;
    logic [15:0] reg_timeout;

    //--------------------------------------
    // VERSION REGISTER
    //--------------------------------------
    logic [31:0] reg_version_ro;

    //==========================================================================
    // ACCESS CONTROL
    //==========================================================================
    logic addr_valid;
    logic access_error;

    always_comb begin
        addr_valid   = 1'b0;
        access_error = 1'b0;
        case (i_reg_addr)

            //--------------------------------------------------------------
            // CTRL REGISTER
            //--------------------------------------------------------------
            REG_CTRL_ADDR: begin
                addr_valid = 1'b1;
                // Entire register contains readable fields
                // Writes allowed to RW/WO fields
            end

            //--------------------------------------------------------------
            // IRQ CTRL REGISTER
            //--------------------------------------------------------------
            REG_IRQ_CTRL_ADDR: begin
                addr_valid = 1'b1;
            end

            //--------------------------------------------------------------
            // STATUS REGISTER
            //--------------------------------------------------------------
            REG_STATUS_ADDR: begin
                addr_valid = 1'b1;
                // STATUS register is RO/RC only
                // WRITE illegal
                if (i_reg_wr_en)
                    access_error = 1'b1;
            end

            //--------------------------------------------------------------
            // CONFIG REGISTER
            //--------------------------------------------------------------
            REG_CONFIG_ADDR: begin
                addr_valid = 1'b1;
            end

            //--------------------------------------------------------------
            // VERSION REGISTER
            //--------------------------------------------------------------
            REG_VERSION_ADDR: begin
                addr_valid = 1'b1;
                // RO register
                // WRITE illegal
                if (i_reg_wr_en)
                    access_error = 1'b1;
            end

            //--------------------------------------------------------------
            // INVALID ADDRESS
            //--------------------------------------------------------------
            default: begin

                addr_valid   = 1'b0;
                access_error = 1'b1;

            end

        endcase
    end

    //==========================================================================
    // WRITE LOGIC
    //==========================================================================
    always_ff @(posedge i_clk or negedge i_resetn) begin
        if (!i_resetn) begin

            //--------------------------------------
            // CTRL
            //--------------------------------------
            reg_enable         <= 1'b0;
            reg_mode           <= 3'b000;
            reg_start          <= 1'b0;

            //--------------------------------------
            // IRQ
            //--------------------------------------
            reg_irq_enable     <= 8'h00;
            reg_irq_status     <= 8'hFF;
            reg_sticky_irq     <= 8'h00;
            reg_polarity       <= 8'hFF;

            //--------------------------------------
            // CONFIG
            //--------------------------------------
            reg_threshold      <= 8'h10;
            reg_soft_reset     <= 1'b0;
            reg_timeout        <= 16'd1000;

        end
        else begin

            //--------------------------------------------------------------
            // DEFAULT WO PULSES
            //--------------------------------------------------------------
            reg_start      <= 1'b0;
            reg_soft_reset <= 1'b0;

            //--------------------------------------------------------------
            // VALID WRITES ONLY
            //--------------------------------------------------------------
            if (i_reg_enable &&
                i_reg_wr_en &&
                !access_error) begin

                case (i_reg_addr)

                    //------------------------------------------------------
                    // CTRL REGISTER
                    //------------------------------------------------------
                    REG_CTRL_ADDR: begin
                        // RW
                        reg_enable <= i_reg_wdata[0];
                        // RW
                        reg_mode <= i_reg_wdata[3:1];
                        // WO pulse
                        reg_start <= i_reg_wdata[4];

                    end

                    //------------------------------------------------------
                    // IRQ CTRL REGISTER
                    //------------------------------------------------------
                    REG_IRQ_CTRL_ADDR: begin

                        //----------------------------------------------
                        // RW
                        //----------------------------------------------
                        reg_irq_enable <= i_reg_wdata[7:0];
                        //----------------------------------------------
                        // W1C
                        //----------------------------------------------
                        reg_irq_status <=
                            reg_irq_status &
                            ~i_reg_wdata[15:8];

                        //----------------------------------------------
                        // W1S
                        //----------------------------------------------
                        reg_sticky_irq <=
                            reg_sticky_irq |
                            i_reg_wdata[23:16];

                        //----------------------------------------------
                        // TOW
                        //----------------------------------------------
                        reg_polarity <=
                            reg_polarity ^
                            i_reg_wdata[31:24];

                    end

                    //------------------------------------------------------
                    // CONFIG REGISTER
                    //------------------------------------------------------
                    REG_CONFIG_ADDR: begin

                        // RW
                        reg_threshold <= i_reg_wdata[7:0];
                        // WO pulse
                        reg_soft_reset <= i_reg_wdata[8];
                        // RW
                        reg_timeout <= i_reg_wdata[31:16];

                    end
                    default: begin
                    end

                endcase
            end

            //--------------------------------------------------------------
            // READ CLEAR REGISTERS
            //--------------------------------------------------------------
            if (i_reg_enable &&
                i_reg_rd_en &&
                !access_error) begin

                case (i_reg_addr)

                    //------------------------------------------------------
                    // CTRL REGISTER RC FIELD
                    //------------------------------------------------------
                    REG_CTRL_ADDR: begin
                        reg_error_count_rc <= 16'h0000;
                    end

                    //------------------------------------------------------
                    // STATUS REGISTER RC FIELD
                    //------------------------------------------------------
                    REG_STATUS_ADDR: begin
                        reg_error_flags_rc <= 8'h00;
                    end

                    default: begin
                    end

                endcase
            end
        end
    end

    //==========================================================================
    // HARDWARE SAMPLING
    //==========================================================================

    always_ff @(posedge i_clk or negedge i_resetn) begin
        if (!i_resetn) begin
            reg_hw_state_ro     <= 8'h00;
            reg_error_count_rc  <= 16'h0000;

            reg_fifo_level_ro   <= 8'h00;
            reg_error_flags_rc  <= 8'h00;

            reg_version_ro      <= 32'h00000000;
        end
        else begin

            //--------------------------------------------------------------
            // RO REGISTERS
            //--------------------------------------------------------------
            reg_hw_state_ro   <= hw_state_ro_i;
            reg_fifo_level_ro <= hw_fifo_level_ro_i;
            reg_version_ro    <= hw_version_ro_i;

            //--------------------------------------------------------------
            // RC REGISTERS
            //--------------------------------------------------------------
            reg_error_count_rc <= hw_error_count_rc_i;

        end
    end

    //==========================================================================
    // READ LOGIC
    //==========================================================================

    always_comb begin
        o_reg_rdata = 32'h0;
        case (i_reg_addr)

            //--------------------------------------------------------------
            // CTRL REGISTER
            //--------------------------------------------------------------
            REG_CTRL_ADDR: begin
                o_reg_rdata[0]      = reg_enable;
                o_reg_rdata[3:1]    = reg_mode;

                // WO reads as 0
                o_reg_rdata[4]      = 1'b0;

                o_reg_rdata[15:8]   = reg_hw_state_ro;
                o_reg_rdata[31:16]  = reg_error_count_rc;

            end

            //--------------------------------------------------------------
            // IRQ CTRL REGISTER
            //--------------------------------------------------------------
            REG_IRQ_CTRL_ADDR: begin

                o_reg_rdata[7:0]    = reg_irq_enable;
                o_reg_rdata[15:8]   = reg_irq_status;
                o_reg_rdata[23:16]  = reg_sticky_irq;
                o_reg_rdata[31:24]  = reg_polarity;

            end

            //--------------------------------------------------------------
            // STATUS REGISTER
            //--------------------------------------------------------------
            REG_STATUS_ADDR: begin

                o_reg_rdata[7:0]   = reg_fifo_level_ro;
                o_reg_rdata[15:8]  = reg_error_flags_rc;

            end

            //--------------------------------------------------------------
            // CONFIG REGISTER
            //--------------------------------------------------------------
            REG_CONFIG_ADDR: begin
                o_reg_rdata[7:0]    = reg_threshold;
                // WO reads as 0
                o_reg_rdata[8]      = 1'b0;
                o_reg_rdata[31:16]  = reg_timeout;

            end

            //--------------------------------------------------------------
            // VERSION REGISTER
            //--------------------------------------------------------------
            REG_VERSION_ADDR: begin
                o_reg_rdata = reg_version_ro;
            end
            default: begin
                o_reg_rdata = 32'h0;
            end
        endcase
    end

    //==========================================================================
    // APB RESPONSE
    //==========================================================================
    assign o_reg_ready = 1'b1;
    assign o_reg_error =
        i_reg_enable &&
        (!addr_valid || access_error);

    //==========================================================================
    // OUTPUT EXPORTS
    //==========================================================================
    assign enable_o       = reg_enable;
    assign mode_o         = reg_mode;
    assign start_o        = reg_start;

    assign irq_enable_o   = reg_irq_enable;
    assign polarity_o     = reg_polarity;

    assign threshold_o    = reg_threshold;
    assign soft_reset_o   = reg_soft_reset;

endmodule