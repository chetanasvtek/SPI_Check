module my_register_block (
    input  logic        clk,
    input  logic        rst_n,
    // Native Access Interface
    input  logic [31:0] wr_addr,
    input  logic [31:0] wr_data,
    input  logic        wr_en,
    input  logic [31:0] rd_addr,
    output logic [31:0] rd_data,

    // Exported Register Ports for Hardware Integration
    output logic [31:0] global_ctrl_o,
    output logic [31:0] command_wo_o,
    output logic [31:0] status_w1c_o,
    output logic [31:0] sticky_set_w1s_o,
    output logic [31:0] error_count_rc_o,
    output logic [31:0] polarity_tow_o,
    output logic [31:0] dev_id_ro_o
);

    logic [31:0] global_ctrl_q;
    assign global_ctrl_o = global_ctrl_q;
    logic [31:0] command_wo_q;
    assign command_wo_o = command_wo_q;
    logic [31:0] status_w1c_q;
    assign status_w1c_o = status_w1c_q;
    logic [31:0] sticky_set_w1s_q;
    assign sticky_set_w1s_o = sticky_set_w1s_q;
    logic [31:0] error_count_rc_q;
    assign error_count_rc_o = error_count_rc_q;
    logic [31:0] polarity_tow_q;
    assign polarity_tow_o = polarity_tow_q;
    logic [31:0] dev_id_ro_q;
    assign dev_id_ro_o = dev_id_ro_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            global_ctrl_q <= 32'h0;
            command_wo_q <= 32'h0;
            status_w1c_q <= 32'h0;
            sticky_set_w1s_q <= 32'h0;
            error_count_rc_q <= 32'h0;
            polarity_tow_q <= 32'h0;
            dev_id_ro_q <= 32'hDEADBEEF;
        end else begin
            if (wr_en) begin
                case (wr_addr)
                    32'h00000000: begin
                        global_ctrl_q <= wr_data;
                    end
                    32'h00000004: begin
                        command_wo_q <= wr_data;
                    end
                    32'h00000008: begin
                        status_w1c_q <= status_w1c_q & ~wr_data;
                    end
                    32'h0000000C: begin
                        sticky_set_w1s_q <= sticky_set_w1s_q | wr_data;
                    end
                    32'h00000010: begin
                    end
                    32'h00000014: begin
                        polarity_tow_q <= polarity_tow_q ^ wr_data;
                    end
                    32'h00000018: begin
                    end
                    default: ;
                endcase
            end

            // Read-to-Clear Logic
            case (rd_addr)
                32'h00000010: error_count_rc_q <= '0;
                default: ;
            endcase
        end
    end

    always_comb begin
        rd_data = 32'h0;
        case (rd_addr)
            32'h00000000: rd_data = global_ctrl_q;
            32'h00000008: rd_data = status_w1c_q;
            32'h0000000C: rd_data = sticky_set_w1s_q;
            32'h00000010: rd_data = error_count_rc_q;
            32'h00000014: rd_data = polarity_tow_q;
            32'h00000018: rd_data = dev_id_ro_q;
            default: rd_data = 32'hDEAD_BEEF;
        endcase
    end

endmodule
