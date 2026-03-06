//------------------------------------------------------------------------------
// Class : test_no_false_positive
// Description: Negative test — sends near-miss and unrelated patterns.
//              Verifies that the DUT does NOT produce a spurious detection.
//   Patterns: 1010, 1001, 0111, 1110, 0101, 00000000, 11111111, 1010101010

class test_no_false_positive extends det_base_test;
    `uvm_component_utils(test_no_false_positive)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        det_no_false_pos_seq seq;

        phase.raise_objection(this, "test_no_false_positive running");

        seq = det_no_false_pos_seq::type_id::create("seq");
        seq.start(env.agent.seqr);

        #100;
        phase.drop_objection(this, "test_no_false_positive done");
    endtask

endclass : test_no_false_positive
