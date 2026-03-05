//------------------------------------------------------------------------------
// Class : test_random_long
// Description: Long random test — drives >= 1000 fully randomised bits.
//   The simulation seed (+ntb_random_seed) makes runs deterministic and
//   reproducible when re-running the same seed.
//   The golden FSM scoreboard checks every single cycle for correctness.
//   Minimum cycles enforced by det_random_long_seq.body() (1000 if lower).
//------------------------------------------------------------------------------
class test_random_long extends det_base_test;
    `uvm_component_utils(test_random_long)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        det_random_long_seq seq;

        phase.raise_objection(this, "test_random_long running");

        seq = det_random_long_seq::type_id::create("seq");
        seq.start(env.agent.seqr);

        #100;
        phase.drop_objection(this, "test_random_long done");
    endtask

endclass : test_random_long
