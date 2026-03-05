`timescale 1ns/1ps
//------------------------------------------------------------------------------
// Module : det_1011
// Description: Mealy/Moore FSM sequence detector for pattern "1011"
//              Supports overlap (e.g., 1011011 detects twice).
//              Active-low reset (rstn).
// Ports  : clk  - clock
//          rstn - active-low synchronous reset
//          in   - serial input bit
//          out  - high for one cycle when "1011" is detected
//------------------------------------------------------------------------------
module det_1011 (
    input  logic clk,
    input  logic rstn,
    input  logic in,
    output logic out
);

    // State encoding
    parameter IDLE  = 0,
              S1    = 1,
              S10   = 2,
              S101  = 3,
              S1011 = 4;

    reg [2:0] cur_state, next_state;

    // Output: combinational, high when in detection state
    assign out = (cur_state == S1011) ? 1'b1 : 1'b0;

    // State register
    always @(posedge clk) begin
        if (!rstn)
            cur_state <= IDLE;
        else
            cur_state <= next_state;
    end

    // Next-state logic (overlap: trailing bits of 1011 reused as prefix)
    always @(cur_state or in) begin
        case (cur_state)
            IDLE  : next_state = in ? S1    : IDLE;
            S1    : next_state = in ? S1    : S10;   // "11..." → stay S1
            S10   : next_state = in ? S101  : IDLE;
            S101  : next_state = in ? S1011 : S10;   // "1010..." → back to S10
            S1011 : next_state = in ? S1    : S10;   // overlap: "1" restarts; "0" → S10
            default: next_state = IDLE;
        endcase
    end

endmodule : det_1011
