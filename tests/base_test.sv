//------------------------------------------------------------------------------
// Class : det_base_test
// Description: Base UVM test for det_1011.

class det_base_test extends uvm_test;
    `uvm_component_utils(det_base_test)

    det_env env;

    // Runtime configuration (set from plusargs)
    int    overlap_en  = 1;
    int    num_cycles  = 100;
    string test_name   = "det_base_test";
    int    seed_val    = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------------------------
    // build_phase: create env, parse plusargs, push config into config_db
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = det_env::type_id::create("env", this);

        // Parse runtime plusargs
        if (!$value$plusargs("OVERLAP_EN=%0d",  overlap_en))  overlap_en  = 1;
        if (!$value$plusargs("NUM_CYCLES=%0d",  num_cycles))  num_cycles  = 100;
        if (!$value$plusargs("UVM_TESTNAME=%s", test_name))   test_name   = get_type_name();

        `uvm_info("TEST_CFG",
            $sformatf("Test=%s OVERLAP_EN=%0d NUM_CYCLES=%0d",
                test_name, overlap_en, num_cycles),
            UVM_LOW)
    endfunction

    // -------------------------------------------------------------------------
    // end_of_elaboration_phase: print UVM hierarchy for debug
    // -------------------------------------------------------------------------
    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

    // -------------------------------------------------------------------------
    // run_phase: subclasses override to start specific sequences
    // -------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        `uvm_fatal("BASE_TEST", "run_phase must be overridden in derived test class")
    endtask

    // -------------------------------------------------------------------------
    // report_phase: print final PASS / FAIL based on scoreboard + UVM errors
    // -------------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        uvm_report_server svr = uvm_report_server::get_server();
        int err_cnt = svr.get_severity_count(UVM_ERROR)
                    + svr.get_severity_count(UVM_FATAL);

        $display("");
        $display("================================================================");
        if (err_cnt == 0)
            $display("  *** TEST PASSED: %0s ***", test_name);
        else
            $display("  *** TEST FAILED: %0s  (errors=%0d) ***", test_name, err_cnt);
        $display("================================================================");
        $display("");
    endfunction

endclass : det_base_test
