 `timescale 1ns/1ps
module SPI_ctrl1_slave_tb;

  // Clock and reset
    logic rst_n_i;

    logic clk_i;
    logic [31:0] spi_master_tx_byte;
    logic spi_master_tx_dv;
    logic spi_master_tx_ready;
    logic [31:0] spi_master_rx_byte;
    logic spi_master_rx_dv;
    logic spi_mosi;
    logic spi_clk;
    logic spi_cs;
    logic spi_miso;
    logic [15:0] ctrl_o1;

    logic spi_cs_i;

//reset for the slave 
    logic rstn;

  //---------------------------------------------
  // Instantiate CDC version
  //---------------------------------------------
  SPI_ctrld1 u_slave1 (
    .rst_n_i(rstn),
    .sclk_i(spi_clk),
    .cs_i(spi_cs_i),
    .mosi_i(spi_mosi),
    .miso_o(spi_miso),
    .SPI_ctrld1_o(ctrl_o1)
  );

        // Instantiate SPI_Master
        SPI_master #(
                    .SPI_MODE(0),
                    .CLKS_PER_HALF_BIT(2)
                ) spi_master_inst (
                    .Rst_L_i(rst_n_i),
                    .Clk_i(clk_i),
                    .TX_Word_i(spi_master_tx_byte),
                    .TX_DV_i(spi_master_tx_dv),
                    .TX_Ready_o(spi_master_tx_ready),
                    .RX_DV_o(spi_master_rx_dv),
                    .RX_Word_o(spi_master_rx_byte),
                    .SPI_Clk_o(spi_clk),
                    .SPI_MISO_i(spi_miso),
                    .SPI_MOSI_o(spi_mosi),
                    .SPI_CS_o(spi_cs)
                );

      // SPI Clock Generation
      initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i;
      end



        // Task to send a word over SPI using SPI_Master
        task send_spi_word(input bit [31:0] word_data);
            @(posedge clk_i);
            spi_master_tx_byte = word_data;
            spi_master_tx_dv = 1'b1;
            @(posedge clk_i);
            spi_master_tx_dv = 1'b0;
            @(posedge clk_i);
            wait(spi_master_tx_ready);
        endtask

      // Task to initialize
  task initialize();
    spi_master_tx_byte = 32'h0000_0000;
    spi_master_tx_dv = 1'b0;

  endtask

  task reset();
    rst_n_i = 0;
    #10;
    rst_n_i = 1;


  endtask

initial begin
    //#3000ns;
     rstn = 0;
    #10;
    rstn = 1;
    // #1000ns;
end  

//cs_i signal controlling 

initial begin
   spi_cs_i = 1'b0;
  #10;
   spi_cs_i = 1'b1; // Assert CS to start communication
   #1336ns;
 //#3960;
  spi_cs_i = 1'b0;
  #10ns;
  spi_cs_i = 1'b1;
  #710ns;
  spi_cs_i = 1'b0;
  //#2271ns;
  // #1322ns;
   // spi_cs_i = 1'b1; 
  //  #1310;
  //  spi_cs_i = 1'b0; // de-assert CS to end communication
  end

  //---------------------------------------------
  // Stimulus
  //---------------------------------------------
  initial begin
    // Reset
    initialize();
    reset();

  //  send_spi_word(32'h0024_0000);
  //  send_spi_word(32'h0000_0000); // Test 1: Read Default Value
    
  send_spi_word(32'h8024_0000);
    //send_spi_word(32'h0000_05BC); // Test 2: Write 16'hA5BC
  send_spi_word(32'hFFFF_FFFF);
   // send_spi_word(32'h8024_0000);
  //send_spi_word(32'h0000_FF00); // Test 3: Write 16'hFF00

  send_spi_word(32'h0024_0000);
  send_spi_word(32'h0000_0000); // Test 4: Read Value


    $display("\nFinal Output Values:");
    $monitor("ctrl_o = %h", ctrl_o1);

    #500;
    $finish;
  end

endmodule
