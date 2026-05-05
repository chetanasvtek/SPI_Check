/////////////////////////////////////////////////////////////
// Module Name : APB_Master
// Description : APB3 Master (Single Slave)
//               - Supports single PSEL
//               - Follows APB3 protocol (IDLE, SETUP, ACCESS)
//               - Compatible with 16-bit address slave
//
// Author      : Susmitha
// Version     : 1.1
// Date        : 05/05/2026
/////////////////////////////////////////////////////////////

module APB_Master #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16   // Updated as per slave spec
) (
    input  logic PCLK,
    input  logic PRESETn,

    input  logic [ADDR_WIDTH-1:0] PSI_ADDR,
    input  logic PSI_WRITE,
    input  logic [DATA_WIDTH-1:0] PSI_WDATA,
    input  logic Transfer,

    input  logic [DATA_WIDTH-1:0] PRDATA,
    input  logic PSLVERR,
    input  logic PREADY,

    output logic [DATA_WIDTH-1:0] PSO_RDATA,
    output logic PSO_SLVERR,

    output logic [ADDR_WIDTH-1:0] PADDR,
    output logic [DATA_WIDTH-1:0] PWDATA,
    output logic PWRITE,
    output logic PSEL,       //  single slave
    output logic PENABLE
);

    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } state_e;

    state_e CurrentState, NextState;

/////////////////////////////////////////////////////////////
// Next State Logic
/////////////////////////////////////////////////////////////
    always_comb begin
        case (CurrentState)
            IDLE:   
                NextState = (Transfer) ? SETUP : IDLE;

            SETUP:  
                NextState = ACCESS;

            ACCESS: begin
                if (PSLVERR)
                    NextState = IDLE;
                else if (PREADY && Transfer)
                    NextState = SETUP;
                else if (PREADY && !Transfer)
                    NextState = IDLE;
                else
                    NextState = ACCESS; // wait state
            end
        endcase
    end

/////////////////////////////////////////////////////////////
// State Register
/////////////////////////////////////////////////////////////
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            CurrentState <= IDLE;
        else
            CurrentState <= NextState;
    end

/////////////////////////////////////////////////////////////
// Output Logic (Aligned with APB timing)
/////////////////////////////////////////////////////////////
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PSEL       <= 0;
            PENABLE    <= 0;
            PADDR      <= 0;
            PWRITE     <= 0;
            PWDATA     <= 0;
            PSO_RDATA  <= 0;
            PSO_SLVERR <= 0;
        end
        else begin
            case (NextState)

                IDLE: begin
                    PSEL    <= 0;
                    PENABLE <= 0;
                end

                SETUP: begin
                    PSEL    <= 1;              // select slave
                    PENABLE <= 0;              // setup phase
                    PADDR   <= PSI_ADDR;
                    PWRITE  <= PSI_WRITE;
                    PWDATA  <= PSI_WDATA;
                end

                ACCESS: begin
                    PSEL    <= 1;
                    PENABLE <= 1;

                    if (PREADY) begin
                        if (!PWRITE)
                            PSO_RDATA <= PRDATA;

                        PSO_SLVERR <= PSLVERR;
                    end
                end

            endcase
        end
    end

endmodule