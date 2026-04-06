//-------------------------------------------------------------------------
// Module Name: Track_trans
// Description: SPI slave command amd Data Phase Tracker module that receives a 16-bit control register
// Date: 08-08-2025
// Author: Pratheek
// Version: v1.1
//-------------------------------------------------------------------------
module Track_trans (
    input logic cs_i,               // Chip Select
    input logic rst_n_i,            // Active Low reset
    output logic trans_cmd_o,       // Transmit Command
    output logic active_decode_o    // Active Decoder
);

    logic pac_tracker;
    always_ff @(posedge cs_i or negedge rst_n_i) begin : blockname
        if(!rst_n_i)
            pac_tracker <= 0;
        else
            pac_tracker <= pac_tracker + 1'b1;
    end

    logic trans_active;
    logic trans_deadzone;
    logic trans_data;

    always_comb begin
        trans_active       = cs_i | pac_tracker;
        trans_deadzone     = ~cs_i & trans_active;
        trans_data         = cs_i & ~pac_tracker;
        trans_cmd_o        = cs_i & pac_tracker;
        active_decode_o    = trans_deadzone | trans_data;
    end

endmodule