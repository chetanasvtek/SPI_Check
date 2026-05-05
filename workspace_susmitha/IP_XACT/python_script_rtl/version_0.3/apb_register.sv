// Generated Register Block: apb_register.sv
module apb_register #( 
    parameter APB_AW = 16,
    parameter APB_DW = 32
) (
    input  logic              clk,
    input  logic              rst_n,
    // Register Interface
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
    logic addr_hit;
    always_comb begin
        addr_hit = 1'b0;
        case (i_reg_addr)
            16'h0000: addr_hit = 1'b1;
            16'h0004: addr_hit = 1'b1;
            16'h0008: addr_hit = 1'b1;
            16'h000C: addr_hit = 1'b1;
            16'h0010: addr_hit = 1'b1;
            16'h0014: addr_hit = 1'b1;
            16'h0018: addr_hit = 1'b1;
            default: addr_hit = 1'b0;
        endcase
    end

    assign o_reg_ready = (i_reg_rd_en || i_reg_wr_en);
    assign o_reg_error = (i_reg_rd_en || i_reg_wr_en) && !addr_hit;

    // Write Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_global_ctrl <= 32'h0;
            reg_command_wo <= 32'h0;
            reg_status_w1c <= 32'h0;
            reg_sticky_set_w1s <= 32'h0;
            reg_error_count_rc <= 32'h0;
            reg_polarity_tow <= 32'h0;
            reg_dev_id_ro <= 32'hDEADBEEF;
        end else if (i_reg_wr_en && addr_hit) begin
            case (i_reg_addr)
                16'h0000: reg_global_ctrl <= i_reg_wdata;
                16'h0004: reg_command_wo <= i_reg_wdata;
                16'h0008: reg_status_w1c <= reg_status_w1c & ~i_reg_wdata;
                16'h000C: reg_sticky_set_w1s <= reg_sticky_set_w1s | i_reg_wdata;
                16'h0014: reg_polarity_tow <= reg_polarity_tow ^ i_reg_wdata;
            endcase
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

    // Special Handling: RC (Read Clear) Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // handled in main reset
        end else if (i_reg_rd_en && addr_hit) begin
            if (i_reg_addr == 16'h0010) reg_error_count_rc <= 32'h0;
        end
    end

endmodule