`timescale 1ns/1ps
//------------------------------------------------------------------------------
// Interface : det_if
// Description: SystemVerilog clocking-block interface for det_1011 DUT.

interface det_if (input logic clk);

    logic rstn;   // active-low reset  (driven by driver)
    logic in;     // serial input bit  (driven by driver)
    logic out;    // detection output  (driven by DUT, read by monitor)

    // Prevent X propagation before driver's power-on reset takes effect
    initial begin
        rstn = 1'b0;
        in   = 1'b0;
    end

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
