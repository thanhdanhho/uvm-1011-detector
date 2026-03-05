`timescale 1ns/1ps
//------------------------------------------------------------------------------
// Interface : det_if
// Description: SystemVerilog clocking-block interface for det_1011 DUT.
//   - driver_cb : output signals driven 1ns AFTER posedge (hold time)
//   - monitor_cb: input  signals sampled 1ns BEFORE posedge (setup time)
// This separation eliminates race conditions between driver and monitor.
//------------------------------------------------------------------------------
interface det_if (input logic clk);

    logic rstn;   // active-low reset  (driven by driver)
    logic in;     // serial input bit  (driven by driver)
    logic out;    // detection output  (driven by DUT, read by monitor)

    // -------------------------------------------------------------------------
    // Driver clocking block
    // output #1 → drives signals 1 ns after posedge (after DUT latches)
    // input  #1 → samples out 1 ns before next posedge (for monitoring)
    // -------------------------------------------------------------------------
    clocking driver_cb @(posedge clk);
        default input #1 output #1;
        output rstn;
        output in;
        input  out;
    endclocking

    // -------------------------------------------------------------------------
    // Monitor clocking block
    // input #1 → samples ALL signals 1 ns before posedge:
    //   - rstn, in : stable setup values the DUT will latch at posedge
    //   - out      : combinational output reflecting cur_state (from prev posedge)
    // -------------------------------------------------------------------------
    clocking monitor_cb @(posedge clk);
        default input #1;
        input rstn;
        input in;
        input out;
    endclocking

    modport driver_mp  (clocking driver_cb,  input clk);
    modport monitor_mp (clocking monitor_cb, input clk);

endinterface : det_if
