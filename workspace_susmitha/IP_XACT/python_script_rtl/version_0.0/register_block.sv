module register_block (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] addr,
    input  logic        wen,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,

    // Register Outputs (Full Width)
    output logic [15:0] out_global_ctrl,
    output logic [3:0] out_int_status_wlc,
    output logic [31:0] out_dev_id,
    output logic [31:0] out_int_clr,

    // Inputs for RO Registers (External Data)
    input  logic [31:0] dev_id_reg_in
);

    logic [15:0] reg_global_ctrl;
    logic [3:0] reg_int_status_wlc;
    logic [31:0] reg_int_clr;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_global_ctrl <= 16'h1;
            reg_int_status_wlc <= 4'h0;
            reg_int_clr <= 32'h5;
        end else if (wen) begin
            unique case (addr)
                16'h0000: reg_global_ctrl <= wdata[15:0];
                16'h0004: reg_int_status_wlc <= wdata[3:0];
                16'h000c: reg_int_clr <= wdata[31:0];
                default: ;
            endcase
        end
    end

    always_comb begin
        unique case (addr)
            16'h0000: rdata = 32'(reg_global_ctrl);
            16'h0004: rdata = 32'(reg_int_status_wlc);
            16'h0024: rdata = 32'(dev_id_reg_in);
            16'h000c: rdata = '0; // Write-Only
            default: rdata = '0;
        endcase
    end

    // Assignments to top-level ports
    assign out_global_ctrl = reg_global_ctrl;
    assign out_int_status_wlc = reg_int_status_wlc;
    assign out_dev_id = dev_id_reg_in;
    assign out_int_clr = reg_int_clr;

endmodule