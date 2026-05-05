/////////////////////////////////////////////////////////////
// Module Name : APB_Master
// Description : AMBA APB3 Master module
//               - Implements APB3 protocol FSM (IDLE, SETUP, ACCESS)
//               - Handles read and write transactions
//               - Supports parameterized data/address width
//               - Includes address decoding for multiple slaves
//
// Parameters  : DATA_WIDTH - Width of data bus
//               ADDR_WIDTH - Width of address bus
//               NO_SLAVES  - Number of APB slaves
//
// Author      : Susmitha
// Version     : 1.0
// Date        : 05/05/2026
/////////////////////////////////////////////////////////////
module APB_Master #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter NO_SLAVES  = 4
) (
    input logic PCLK,
    input logic PRESETn,
    input logic [ADDR_WIDTH-1 : 0] PSI_ADDR,
    input logic PSI_WRITE,
    input logic [DATA_WIDTH-1 : 0] PSI_WDATA,
    input logic Transfer,
    input logic [DATA_WIDTH-1 : 0] PRDATA,
    input logic PSLVERR,
    input logic PREADY,
    output logic [DATA_WIDTH-1 : 0] PSO_RDATA,
    output logic PSO_SLVERR,
    output logic [ADDR_WIDTH-1 : 0] PADDR,
    output logic [DATA_WIDTH-1 : 0] PWDATA,
    output logic PWRITE,
    output logic [NO_SLAVES-1 : 0] PSELx,
    output logic PENABLE
);

    // Using typedef enum for FSM states
    typedef enum logic [2:0] {
        IDLE   = 3'b001,
        SETUP  = 3'b010,
        ACCESS = 3'b100
    } state_e;

    state_e NextState, CurrentState;

// Next State Logic
    always_comb begin
        case (CurrentState)
            IDLE: begin
                if (Transfer) begin
                    NextState = SETUP;
                end
                else begin
                    NextState = IDLE;
                end
            end
            SETUP: begin
                NextState = ACCESS;
            end
            ACCESS: begin
                if (PSLVERR) begin
                    NextState = IDLE;
                end 
                else begin
                    if (PREADY && Transfer) begin
                        NextState = SETUP;
                    end 
                    else if (PREADY && !Transfer) begin
                        NextState = IDLE;
                    end
                    else begin
                        NextState = ACCESS;
                    end
                end
            end
        endcase
    end

// State Memory
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            CurrentState <= IDLE;
        end else begin
            CurrentState <= NextState;
        end
    end

// output Logic
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PENABLE    <= '0;
            PADDR      <= '0; 
            PWRITE     <= '0;
            PSO_RDATA  <= '0;
            PSO_SLVERR <= '0;
            PWDATA     <= '0;

        end
        else if (NextState == SETUP) begin
            PENABLE <= '0;
            PADDR   <= PSI_ADDR; 
            PWRITE  <= PSI_WRITE;
            if (PSI_WRITE == 1) begin // WRITE
                PWDATA <= PSI_WDATA;
            end
        end
        else if (NextState == ACCESS) begin
            PENABLE <= '1;
            if (PREADY == 1) begin
                if (PSI_WRITE == 0) begin
                    PSO_RDATA <= PRDATA;
                end
                PSO_SLVERR <= PSLVERR;
            end
        end
        else begin
            PENABLE <= '0;
        end
    end

// ADDRESS Decoding
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PSELx <= '0;
        end
        else if (NextState == IDLE) begin
            PSELx <= '0;
        end
        else begin
            case (PSI_ADDR[31:30])
                2'b00: PSELx <= 4'b0001;
                2'b01: PSELx <= 4'b0010;
                2'b10: PSELx <= 4'b0100;
                2'b11: PSELx <= 4'b1000;
                default: begin
                   PSELx <= '0;
                end
            endcase
        end
    end
endmodule