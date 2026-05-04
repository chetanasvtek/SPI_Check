////////////////////////////////////////////////////////////
// Module Name: apb_mast
// Purpose: APB Master 
// Version: 0.0
// Author :Susmitha
// Date : 04/05/2026 
///////////////////////////////////////////////////////////
module apb_mast (

    // PSI => Previous System IN
    // PSO => Previous System OUT
    
    input  logic        PCLK,
    input  logic        PRESETn,
    input  logic [31:0] PSI_ADDR,
    input  logic        PSI_WRITE,
    input  logic [31:0] PSI_WDATA,
    input  logic        PENABLE,     // start signal
    input  logic [31:0] PRDATA,

    output logic [31:0] PSO_RDATA,
    output logic [31:0] PADDR,
    output logic [31:0] PWDATA,
    output logic        PWRITE,
    output logic [3:0]  PSELx,
    output logic        PENABLE
);

    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } state_e;

    state_e CurrentState, NextState;

    // Next State Logic
    always_comb begin
        case (CurrentState)
            IDLE:   NextState = (PENABLE) ? SETUP : IDLE;
            SETUP:  NextState = ACCESS;
            ACCESS: NextState = IDLE;   // always complete in 1 cycle
            default: NextState = IDLE;
        endcase
    end

    // State Register
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            CurrentState <= IDLE;
        else
            CurrentState <= NextState;
    end

    // Output Logic
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PENABLE   <= 0;
            PADDR     <= 0;
            PWRITE    <= 0;
            PWDATA    <= 0;
            PSO_RDATA <= 0;
        end
        else begin
            case (NextState)
                SETUP: begin
                    PENABLE <= 0;
                    PADDR   <= PSI_ADDR;
                    PWRITE  <= PSI_WRITE;
                    if (PSI_WRITE)
                        PWDATA <= PSI_WDATA;
                end

                ACCESS: begin
                    PENABLE <= 1;
                    if (!PSI_WRITE)
                        PSO_RDATA <= PRDATA;
                end

                default: begin
                    PENABLE <= 0;
                end
            endcase
        end
    end

    // Address Decoding
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            PSELx <= 4'b0000;
        else if (NextState == IDLE)
            PSELx <= 4'b0000;
        else begin
            case (PSI_ADDR[31:30])
                2'b00: PSELx <= 4'b0001;
                2'b01: PSELx <= 4'b0010;
                2'b10: PSELx <= 4'b0100;
                2'b11: PSELx <= 4'b1000;
            endcase
        end
    end

endmodule