// Generated Register Block for complex_ip_core
module complex_ip_core_regs #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32
) (
    input  logic                   clk,
    input  logic                   rst_n,

    // --- Bus Interface ---
    input  logic [ADDR_WIDTH-1:0]  waddr,
    input  logic [DATA_WIDTH-1:0]  wdata,
    input  logic                   wen,
    input  logic [ADDR_WIDTH-1:0]  raddr,
    output logic [DATA_WIDTH-1:0]  rdata,

    // --- Full Register Output Ports ---
    output logic [31:0]            out_reg_global_ctrl,
    output logic [31:0]            out_reg_timer_cfg,
    output logic [31:0]            out_reg_int_clr,
    output logic [31:0]            out_reg_clk_ctrl,
    output logic [31:0]            out_reg_adc_cfg,
    output logic [31:0]            out_reg_gpio_dir,
    output logic [31:0]            out_reg_filter_coeff,
    output logic [31:0]            out_reg_proto_set,

    // --- Individual Field Ports ---
    output logic         out_f_global_ctrl_enable,
    output logic         out_f_global_ctrl_soft_reset,
    output logic [1:0]   out_f_global_ctrl_mode_select,
    output logic         out_f_global_ctrl_int_en,
    input  logic         in_f_global_status_busy,
    input  logic         in_f_global_status_fifo_empty,
    input  logic         in_f_global_status_fifo_full,
    input  logic [3:0]   in_f_global_status_error_state,
    output logic [7:0]   out_f_timer_cfg_prescaler,
    output logic         out_f_timer_cfg_auto_reload,
    output logic         out_f_timer_cfg_one_shot,
    output logic         out_f_int_clr_clr_tx,
    output logic         out_f_int_clr_clr_rx,
    output logic         out_f_int_clr_clr_err,
    output logic         out_f_int_clr_clr_all,
    output logic [3:0]   out_f_clk_ctrl_div_factor,
    output logic [1:0]   out_f_clk_ctrl_src_sel,
    output logic         out_f_clk_ctrl_gate_en,
    output logic [9:0]   out_f_adc_cfg_sample_rate,
    output logic [1:0]   out_f_adc_cfg_resolution,
    output logic         out_f_adc_cfg_vref_sel,
    output logic [7:0]   out_f_gpio_dir_port_a_dir,
    output logic [7:0]   out_f_gpio_dir_port_b_dir,
    output logic         out_f_gpio_dir_pull_up_en,
    output logic [7:0]   out_f_filter_coeff_coeff_a,
    output logic [7:0]   out_f_filter_coeff_coeff_b,
    output logic [7:0]   out_f_filter_coeff_coeff_c,
    output logic         out_f_filter_coeff_bypass,
    output logic [15:0]  out_f_proto_set_baud_rate,
    output logic [1:0]   out_f_proto_set_parity,
    output logic         out_f_proto_set_stop_bits,
    input  logic [3:0]   in_f_dev_id_ver_major,
    input  logic [3:0]   in_f_dev_id_ver_minor,
    input  logic [7:0]   in_f_dev_id_custom_tag,
    input  logic [15:0]  in_f_dev_id_fixed_id
);

    // Internal Storage
    logic [31:0] q_global_ctrl;
    logic [31:0] q_timer_cfg;
    logic [31:0] q_int_clr;
    logic [31:0] q_clk_ctrl;
    logic [31:0] q_adc_cfg;
    logic [31:0] q_gpio_dir;
    logic [31:0] q_filter_coeff;
    logic [31:0] q_proto_set;

    // Write Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_global_ctrl <= 0x000000ff;
            q_timer_cfg <= 32'h0;
            q_int_clr <= 32'h0;
            q_clk_ctrl <= 32'h0;
            q_adc_cfg <= 32'h0;
            q_gpio_dir <= 32'h0;
            q_filter_coeff <= 32'h0;
            q_proto_set <= 32'h0;
        end else if (wen) begin
            case (waddr)
                0x000000000 : q_global_ctrl <= wdata;
                0x000000008 : q_timer_cfg <= wdata;
                0x00000000C : q_int_clr <= wdata;
                0x000000010 : q_clk_ctrl <= wdata;
                0x000000014 : q_adc_cfg <= wdata;
                0x000000018 : q_gpio_dir <= wdata;
                0x00000001C : q_filter_coeff <= wdata;
                0x000000020 : q_proto_set <= wdata;
                default : ;
            endcase
        end
    end

    // Read Logic
    always_comb begin
        case (raddr)
            0x000000000 : rdata = q_global_ctrl;
            0x000000004 : rdata = (1'(in_f_global_status_busy) << 0) | (1'(in_f_global_status_fifo_empty) << 1) | (1'(in_f_global_status_fifo_full) << 2) | (4'(in_f_global_status_error_state) << 8);
            0x000000008 : rdata = q_timer_cfg;
            0x00000000C : rdata = q_int_clr;
            0x000000010 : rdata = q_clk_ctrl;
            0x000000014 : rdata = q_adc_cfg;
            0x000000018 : rdata = q_gpio_dir;
            0x00000001C : rdata = q_filter_coeff;
            0x000000020 : rdata = q_proto_set;
            0x000000024 : rdata = (4'(in_f_dev_id_ver_major) << 0) | (4'(in_f_dev_id_ver_minor) << 4) | (8'(in_f_dev_id_custom_tag) << 8) | (16'(in_f_dev_id_fixed_id) << 16);
            default : rdata = 32'h0;
        endcase
    end

    // Port Mapping
    assign out_reg_global_ctrl = q_global_ctrl;
    assign out_f_global_ctrl_enable = q_global_ctrl[0];
    assign out_f_global_ctrl_soft_reset = q_global_ctrl[1];
    assign out_f_global_ctrl_mode_select = q_global_ctrl[5:4];
    assign out_f_global_ctrl_int_en = q_global_ctrl[8];
    assign out_reg_timer_cfg = q_timer_cfg;
    assign out_f_timer_cfg_prescaler = q_timer_cfg[7:0];
    assign out_f_timer_cfg_auto_reload = q_timer_cfg[16];
    assign out_f_timer_cfg_one_shot = q_timer_cfg[17];
    assign out_reg_int_clr = q_int_clr;
    assign out_f_int_clr_clr_tx = q_int_clr[0];
    assign out_f_int_clr_clr_rx = q_int_clr[1];
    assign out_f_int_clr_clr_err = q_int_clr[2];
    assign out_f_int_clr_clr_all = q_int_clr[31];
    assign out_reg_clk_ctrl = q_clk_ctrl;
    assign out_f_clk_ctrl_div_factor = q_clk_ctrl[3:0];
    assign out_f_clk_ctrl_src_sel = q_clk_ctrl[9:8];
    assign out_f_clk_ctrl_gate_en = q_clk_ctrl[16];
    assign out_reg_adc_cfg = q_adc_cfg;
    assign out_f_adc_cfg_sample_rate = q_adc_cfg[9:0];
    assign out_f_adc_cfg_resolution = q_adc_cfg[13:12];
    assign out_f_adc_cfg_vref_sel = q_adc_cfg[16];
    assign out_reg_gpio_dir = q_gpio_dir;
    assign out_f_gpio_dir_port_a_dir = q_gpio_dir[7:0];
    assign out_f_gpio_dir_port_b_dir = q_gpio_dir[15:8];
    assign out_f_gpio_dir_pull_up_en = q_gpio_dir[24];
    assign out_reg_filter_coeff = q_filter_coeff;
    assign out_f_filter_coeff_coeff_a = q_filter_coeff[7:0];
    assign out_f_filter_coeff_coeff_b = q_filter_coeff[15:8];
    assign out_f_filter_coeff_coeff_c = q_filter_coeff[23:16];
    assign out_f_filter_coeff_bypass = q_filter_coeff[31];
    assign out_reg_proto_set = q_proto_set;
    assign out_f_proto_set_baud_rate = q_proto_set[15:0];
    assign out_f_proto_set_parity = q_proto_set[17:16];
    assign out_f_proto_set_stop_bits = q_proto_set[20];

endmodule