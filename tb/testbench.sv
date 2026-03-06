`timescale 1ns/1ps
//==============================================================================
// Module : testbench
// Description: UVM top-level testbench for det_1011.

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

    string wave_file;
    string fsdb_file;
    int    dump_wave;

    initial begin
        dump_wave = 0;
        if ($value$plusargs("DUMP_WAVE=%0d", dump_wave)) begin end
        if (dump_wave) begin
            if (!$value$plusargs("WAVE_FILE=%s", wave_file))
                wave_file = "waves/sim.vcd";
            
            // Generate FSDB filename from VCD filename
            fsdb_file = wave_file.substr(0, wave_file.len()-5);  // remove .vcd
            fsdb_file = {fsdb_file, ".fsdb"};
            
            // Dump VCD format
            $dumpfile(wave_file);
            $dumpvars(0, testbench);
            `uvm_info("TB", {"Waveform (VCD): ", wave_file}, UVM_LOW)
            
            // Dump FSDB format (Verdi/VCS native)
            $fsdbDumpfile(fsdb_file);
            $fsdbDumpvars(0, testbench);
            `uvm_info("TB", {"Waveform (FSDB): ", fsdb_file}, UVM_LOW)
        end
    end

    // -------------------------------------------------------------------------
    // UVM startup
    //   1. Push virtual interface handle into config_db (root scope).
    //   2. Call run_test() 
    // -------------------------------------------------------------------------
    initial begin
        // Provide the virtual interface to every component that asks for "vif"
        uvm_config_db #(virtual det_if)::set(
            uvm_root::get(), "*", "vif", dut_if);

        run_test();
    end

endmodule : testbench
