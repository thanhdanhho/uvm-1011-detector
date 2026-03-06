//------------------------------------------------------------------------------
// Class : test_overlap
// Description: Overlap mode test, controlled by OVERLAP_EN plusarg.
//   OVERLAP_EN=1 (default): sends 1011011 → expects 2 detections (overlap).
//   OVERLAP_EN=0          : sends 1011 [gap] 1011 → expects 2 detections
//                           (non-overlap, gap prevents reuse of trailing bits).

class test_overlap extends det_base_test;
    `uvm_component_utils(test_overlap)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        det_overlap_seq seq;

        phase.raise_objection(this, "test_overlap running");

        seq = det_overlap_seq::type_id::create("seq");
        // Note: seq reads OVERLAP_EN from plusargs in pre_start()
        seq.start(env.agent.seqr);

        #100;
        phase.drop_objection(this, "test_overlap done");
    endtask

endclass : test_overlap
