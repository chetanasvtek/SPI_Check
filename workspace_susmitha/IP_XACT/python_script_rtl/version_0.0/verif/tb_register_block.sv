`timescale 1ns/1ps

module tb_register_block();

    // Clock and Reset
    logic clk = 0;
    logic rst_n;
    
    // Interface signals
    logic [15:0] addr;
    logic        wen;
    logic [31:0] wdata;
    logic [31:0] rdata;
    
    // Outputs
    logic [31:0] out_global_ctrl;
    logic [31:0] out_int_status_wlc;
    logic [31:0] out_dev_id;
    logic [31:0] out_int_clr;
    
    // Inputs
    logic [31:0] dev_id_reg_in = 32'hDEAD_BEEF; // Static ID for RO test

    // File Descriptor
    int fd;

    // Instantiate DUT
    register_block dut (.*);

    // Clock Generation
    always #5 clk = ~clk;

    // Task for Register Write and Verification
    task verify_reg(input [15:0] t_addr, input [31:0] t_data, input string name, input bit is_wo = 0);
        logic [31:0] sampled_out;
        
        // Write Phase
        @(posedge clk);
        addr  <= t_addr;
        wen   <= 1;
        wdata <= t_data;
        
        @(posedge clk);
        wen   <= 0;
        
        // Read/Check Phase
        #1; // Wait for combinational settle
        
        // Determine which output port to check based on address
        case(t_addr)
            16'h0000: sampled_out = out_global_ctrl;
            16'h0004: sampled_out = out_int_status_wlc;
            16'h000c: sampled_out = out_int_clr;
            default:  sampled_out = 32'hX;
        endcase

        $fdisplay(fd, "--------------------------------------------------");
        $fdisplay(fd, "Register: %s | Addr: 0x%h", name, t_addr);
        $fdisplay(fd, "Written Data: 0x%h", t_data);
        $fdisplay(fd, "Output Port:  0x%h", sampled_out);
        $fdisplay(fd, "Bus Read:     0x%h", rdata);

        // Comparison Logic
        if (is_wo) begin
            if (sampled_out == t_data && rdata == 0)
                $fdisplay(fd, "RESULT: MATCH (Write-Only Check Passed)");
            else
                $fdisplay(fd, "RESULT: MISMATCH!");
        end else begin
            if (sampled_out == t_data && rdata == t_data)
                $fdisplay(fd, "RESULT: MATCH");
            else
                $fdisplay(fd, "RESULT: MISMATCH!");
        end
    endtask

    initial begin
        // Open Log file
        fd = $fopen("register_check.txt", "w");
        
        // Reset sequence
        rst_n = 0;
        addr = 0; wen = 0; wdata = 0;
        repeat(2) @(posedge clk);
        rst_n = 1;
        
        $fdisplay(fd, "Starting Register Verification...");

        // 1. Check Global Control (RW)
        verify_reg(16'h0000, 32'hAAAA_5555, "GLOBAL_CTRL");

        // 2. Check Interrupt Status (RW)
        verify_reg(16'h0004, 32'h1234_5678, "INT_STATUS_WLC");

        // 3. Check Interrupt Clear (Write-Only)
        // Per your RTL, reading 0x000C returns 0
        verify_reg(16'h000c, 32'hFFFF_FFFF, "INT_CLR", 1);

        // 4. Check Device ID (Read-Only)
        @(posedge clk);
        addr <= 16'h0024;
        wen  <= 0;
        #1;
        $fdisplay(fd, "--------------------------------------------------");
        $fdisplay(fd, "Register: DEV_ID | Addr: 0x0024");
        $fdisplay(fd, "Bus Read: 0x%h | Port Out: 0x%h", rdata, out_dev_id);
        if (rdata == 32'hDEAD_BEEF && out_dev_id == 32'hDEAD_BEEF)
            $fdisplay(fd, "RESULT: MATCH (Read-Only Check Passed)");
        else
            $fdisplay(fd, "RESULT: MISMATCH!");

        $fdisplay(fd, "--------------------------------------------------");
        $fdisplay(fd, "Verification Complete.");
        $fclose(fd);
        $finish;
    end

endmodule