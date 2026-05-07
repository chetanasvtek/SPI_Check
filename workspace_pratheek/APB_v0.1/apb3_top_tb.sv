`timescale 1ns/1ps

import apb3_pkg::*;

module apb3_top_tb;

    //--------------------------------------------------------------------------
    // Clock / reset
    //--------------------------------------------------------------------------

    logic                   pclk;
    logic                   presetn;

    //--------------------------------------------------------------------------
    // APB master signals
    //--------------------------------------------------------------------------

    logic [APB_AW-1:0]      paddr;
    logic                   psel;
    logic                   penable;
    logic                   pwrite;
    logic [APB_DW-1:0]      pwdata;

    logic [APB_DW-1:0]      prdata;
    logic                   pready;
    logic                   pslverr;

    integer                 log_file;
    integer                 error_count;
    logic [APB_DW-1:0]      data;

    //--------------------------------------------------------------------------
    // DUT instance
    //--------------------------------------------------------------------------

    apb3_top dut (
        .i_pclk    (pclk),
        .i_presetn (presetn),
        .i_paddr   (paddr),
        .i_psel    (psel),
        .i_penable (penable),
        .i_pwrite  (pwrite),
        .i_pwdata  (pwdata),
        .o_prdata  (prdata),
        .o_pready  (pready),
        .o_pslverr (pslverr)
    );

    //--------------------------------------------------------------------------
    // Clock generation
    //--------------------------------------------------------------------------

    initial begin
        pclk = 1'b0;
        forever #5 pclk = ~pclk;
    end

    //--------------------------------------------------------------------------
    // APB master tasks
    //--------------------------------------------------------------------------

    task apb_write(
        input logic [APB_AW-1:0]      addr,
        input logic [APB_DW-1:0]      data
    );
        begin
            paddr   <= addr;
            pwdata  <= data;
            pwrite  <= 1'b1;
            psel    <= 1'b1;
            penable <= 1'b0;
            @(posedge pclk);
            penable <= 1'b1;
            wait (pready == 1'b1);
            @(posedge pclk);
            psel    <= 1'b0;
            penable <= 1'b0;
            pwrite  <= 1'b0;
            $fdisplay(log_file, "%0t: WRITE addr=0x%0h data=0x%0h ready=%0b err=%0b", $time, addr, data, pready, pslverr);
        end
    endtask

    task apb_read(
        input  logic [APB_AW-1:0]      addr,
        output logic [APB_DW-1:0]      data
    );
        begin
            paddr   <= addr;
            pwrite  <= 1'b0;
            psel    <= 1'b1;
            penable <= 1'b0;
            @(posedge pclk);
            penable <= 1'b1;
            wait (pready == 1'b1);
            data <= prdata;
            @(posedge pclk);
            psel    <= 1'b0;
            penable <= 1'b0;
            $fdisplay(log_file, "%0t: READ  addr=0x%0h data=0x%0h ready=%0b err=%0b", $time, addr, data, pready, pslverr);
        end
    endtask

    task automatic check_value(
        input string                   desc,
        input logic [APB_DW-1:0]       actual,
        input logic [APB_DW-1:0]       expected
    );
        begin
            if (actual !== expected) begin
                error_count = error_count + 1;
                $fdisplay(log_file, "%0t: ERROR %s: got 0x%0h expected 0x%0h", $time, desc, actual, expected);
            end else begin
                $fdisplay(log_file, "%0t: PASS  %s: value = 0x%0h", $time, desc, actual);
            end
        end
    endtask

    //--------------------------------------------------------------------------
    // Test scenario
    //--------------------------------------------------------------------------

    initial begin
        log_file    = $fopen("apb3_top_tb.log", "w");
        error_count = 0;

        psel    = 1'b0;
        penable = 1'b0;
        paddr   = '0;
        pwrite  = 1'b0;
        pwdata  = '0;

        presetn = 1'b0;
        repeat (4) @(posedge pclk);
        presetn = 1'b1;
        @(posedge pclk);

        $fdisplay(log_file, "APB3 top test started");

        // Basic register writes and reads
        apb_write(16'h0000, 32'h1111_1111);
        apb_write(16'h0004, 32'h2222_2222);
        apb_write(16'h0008, 32'h1234_5678); 
        apb_write(16'h000C, 32'hA5A5_A5A5);
        apb_write(16'h0014, 32'hffff_ffff); 



        apb_read(16'h0000, data);
        check_value("reg0 readback", data, 32'h1111_1111);

        apb_read(16'h0004, data);
        check_value("reg1 readback", data, 32'h0000_0000);

        apb_read(16'h0008, data);
        check_value("reg2 reset value", data, 32'h0000_0000);

        apb_read(16'h000C, data);
        check_value("reg3 first read", data, 32'hA5A5_A5A5);

        apb_read(16'h0014, data);
        check_value("reg4 first read", data, 32'hFFFF_FFFF);

        apb_read(16'h0010, data);
        check_value("reg5 first read", data, 32'h1234_5678);

        apb_read(16'h0010, data);
        check_value("reg5 first read", data, 32'h0000_0000);

        apb_read(16'h0018, data);
        check_value("reg6 first read", data, 32'h1234_5678);

        // Invalid access should generate PSLVERR from the slave
        apb_read(16'h0020, data);
        if (!pslverr) begin
            error_count = error_count + 1;
            $fdisplay(log_file, "%0t: ERROR invalid access did not assert PSLVERR", $time);
        end else begin
            $fdisplay(log_file, "%0t: PASS  invalid access asserted PSLVERR", $time);
        end

        $fdisplay(log_file, "APB3 top test completed with %0d error(s)", error_count);
        if (error_count == 0)
            $fdisplay(log_file, "TEST RESULT: SUCCESS");
        else
            $fdisplay(log_file, "TEST RESULT: FAILURE");

        $fclose(log_file);
        #20;
        $finish;
    end

endmodule
