//------------------------------------------------------------------------------
// Class : test_reset_basic
// Description: Verifies correct reset behavior.

class test_reset_basic extends det_base_test;
    `uvm_component_utils(test_reset_basic)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        det_directed_1011_seq dir_seq1, dir_seq2;
        det_reset_seq         mid_reset;

        phase.raise_objection(this, "test_reset_basic running");

        // --- Phase 1: verify detection works after initial power-on reset ---
        dir_seq1 = det_directed_1011_seq::type_id::create("dir_seq1");
        dir_seq1.start(env.agent.seqr);

        // --- Phase 2: inject mid-simulation reset ---
        mid_reset         = det_reset_seq::type_id::create("mid_reset");
        mid_reset.n_reset = 3;   // 3 cycles of rstn=0
        mid_reset.n_idle  = 4;   // settle time after de-assert
        mid_reset.start(env.agent.seqr);
        `uvm_info("TEST", "Mid-simulation reset injected", UVM_LOW)

        // --- Phase 3: verify detection works after mid-sim reset ---
        dir_seq2 = det_directed_1011_seq::type_id::create("dir_seq2");
        dir_seq2.start(env.agent.seqr);

        #100;  // drain: let monitor capture the last detection cycle
        phase.drop_objection(this, "test_reset_basic done");
    endtask

endclass : test_reset_basic
