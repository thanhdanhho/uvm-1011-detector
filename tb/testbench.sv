`timescale 1ns/1ps
//==============================================================================
// Module : testbench
// Description: UVM top-level testbench for det_1011.
//   - Generates clock and drives initial reset (driver takes over immediately)
//   - Instantiates DUT and det_if interface
//   - Pushes virtual interface into uvm_config_db
//   - Calls run_test() to launch the UVM test specified by +UVM_TESTNAME
//   - Handles VCD waveform dumping based on +DUMP_WAVE plusarg
//   - Waveform naming: waves/<test>_<seed>_<tool>.vcd
//==============================================================================

// Import UVM package (must precede `include of UVM macros)
import uvm_pkg::*;
`include "uvm_macros.svh"

// Import the project package (all TB classes compiled in order)
import det_pkg::*;

module testbench;

    // -------------------------------------------------------------------------
    // Clock: 10 ns period (100 MHz)
    // -------------------------------------------------------------------------
    logic clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Interface instance
    // -------------------------------------------------------------------------
    det_if dut_if (.clk(clk));

    // -------------------------------------------------------------------------
    // DUT instance — connect via interface signals
    // -------------------------------------------------------------------------
    det_1011 dut (
        .clk  (clk),
        .rstn (dut_if.rstn),
        .in   (dut_if.in),
        .out  (dut_if.out)
    );

    // -------------------------------------------------------------------------
    // Waveform dump (VCD — works on both QuestaSim and VCS)
    // Controlled by +DUMP_WAVE=1 plusarg; file named by +WAVE_FILE=<path>
    // -------------------------------------------------------------------------
    string wave_file;
    int    dump_wave;

    initial begin
        dump_wave = 0;
        if ($value$plusargs("DUMP_WAVE=%0d", dump_wave)) begin end
        if (dump_wave) begin
            if (!$value$plusargs("WAVE_FILE=%s", wave_file))
                wave_file = "waves/sim.vcd";
            $dumpfile(wave_file);
            $dumpvars(0, testbench);  // dump all signals in this scope
            `uvm_info("TB", {"Waveform: ", wave_file}, UVM_LOW)
        end
    end

    // -------------------------------------------------------------------------
    // UVM startup
    //   1. Push virtual interface handle into config_db (root scope).
    //   2. Call run_test() — UVM picks the test class from +UVM_TESTNAME.
    // -------------------------------------------------------------------------
    initial begin
        // Provide the virtual interface to every component that asks for "vif"
        uvm_config_db #(virtual det_if)::set(
            uvm_root::get(), "*", "vif", dut_if);

        // Launch UVM test (blocks until all phases complete)
        run_test();
    end

endmodule : testbench
