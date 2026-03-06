//------------------------------------------------------------------------------
// Class : test_directed_1011
// Description: Directed test — sends the exact 1011 pattern and verifies
//              that exactly one detection pulse is produced.
//   Sequence: [4 idles] 1 0 1 1 [4 idles]

class test_directed_1011 extends det_base_test;
    `uvm_component_utils(test_directed_1011)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        det_directed_1011_seq seq;

        phase.raise_objection(this, "test_directed_1011 running");

        seq = det_directed_1011_seq::type_id::create("seq");
        seq.start(env.agent.seqr);

        #100;  // drain time
        phase.drop_objection(this, "test_directed_1011 done");
    endtask

endclass : test_directed_1011
