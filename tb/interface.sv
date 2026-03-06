`timescale 1ns/1ps
//------------------------------------------------------------------------------
// Interface : det_if
// Description: SystemVerilog clocking-block interface for det_1011 DUT.
interface det_if (input logic clk);

    logic rstn;   // active-low reset  (driven by driver)
    logic in;     // serial input bit  (driven by driver)
    logic out;    // detection output  (driven by DUT, read by monitor)

    clocking driver_cb @(posedge clk);
        default input #1 output #1;
        output rstn;
        output in;
        input  out;
    endclocking


    clocking monitor_cb @(posedge clk);
        default input #1;
        input rstn;
        input in;
        input out;
    endclocking

    modport driver_mp  (clocking driver_cb,  input clk);
    modport monitor_mp (clocking monitor_cb, input clk);

endinterface : det_if
