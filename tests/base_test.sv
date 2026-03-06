//==============================================================================
// Class : det_base_test
// Description: Base UVM test — orchestrates verification intent.
//==============================================================================
class det_base_test extends uvm_test;
    `uvm_component_utils(det_base_test)

    det_env      env;
    det_test_cfg cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------------------------
    // configure_test: subclasses override to set test-specific acceptance criteria
    // -------------------------------------------------------------------------
    virtual function void configure_test();
        // Base defaults: golden model only, no expected count check
        cfg.expected_detections = -1;
        cfg.check_exact_count   = 0;
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // 1. Create config object
        cfg = det_test_cfg::type_id::create("cfg");
        cfg.test_name = get_type_name();

        // 2. Parse runtime plusargs into cfg
        void'($value$plusargs("OVERLAP_EN=%0d",  cfg.overlap_en));
        void'($value$plusargs("NUM_CYCLES=%0d",  cfg.num_cycles));

        // 3. Let subclass set expected_detections and other scenario constraints
        configure_test();

        // 4. Push cfg into config_db so scoreboard and sequences can pull it
        uvm_config_db #(det_test_cfg)::set(this, "*", "cfg", cfg);

        // 5. Create env
        env = det_env::type_id::create("env", this);

        `uvm_info("TEST_CFG",
            $sformatf("Config: %s", cfg.convert2string()), UVM_LOW)
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

    task run_phase(uvm_phase phase);
        `uvm_fatal("BASE_TEST", "run_phase must be overridden in derived test")
    endtask

    // -------------------------------------------------------------------------
    // report_phase: PASS/FAIL based on UVM errors (scoreboard reports its own)
    // -------------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        uvm_report_server svr = uvm_report_server::get_server();
        int err_cnt = svr.get_severity_count(UVM_ERROR)
                    + svr.get_severity_count(UVM_FATAL);
        $display("");
        $display("================================================================");
        if (err_cnt == 0)
            $display("  *** TEST PASSED : %0s ***", cfg.test_name);
        else
            $display("  *** TEST FAILED : %0s  (errors=%0d) ***",
                cfg.test_name, err_cnt);
        $display("================================================================");
        $display("");
    endfunction

endclass : det_base_test
