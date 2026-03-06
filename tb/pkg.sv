//==============================================================================
// Package : det_pkg
// Description: Aggregates all UVM testbench source files in strict
//              compilation order. Any file that references a class must
//              appear AFTER the file defining that class.

package det_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // ---- UVM components ----
    `include "transaction.sv"
    `include "sequencer.sv"
    `include "sequence.sv"
    `include "driver.sv"
    `include "monitor.sv"
    `include "scoreboard.sv"
    `include "agent.sv"
    `include "environment.sv"

    // ---- Test library ----
    `include "../tests/base_test.sv"
    `include "../tests/test_reset_basic.sv"
    `include "../tests/test_directed_1011.sv"
    `include "../tests/test_no_false_positive.sv"
    `include "../tests/test_overlap.sv"
    `include "../tests/test_random_long.sv"

endpackage : det_pkg
