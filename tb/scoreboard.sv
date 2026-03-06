//==============================================================================
// Class : det_scoreboard
// Description: Golden FSM reference model + checker + functional coverage.
// ── FSM TRANSITION COVERAGE (10 transitions) ────────────────────────────────
// idle→idle, idle→s1,
// s1→s1, s1→s10,
// s10→idle, s10→s101,
// s101→s10 (bait!), s101→s1011,
// s1011→s1, s1011→s10
//==============================================================================
class det_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(det_scoreboard)

    uvm_analysis_imp #(det_transaction, det_scoreboard) analysis_export;

    // ---- Configuration object (pulled from config_db) ----
    det_test_cfg cfg;

    // ---- Golden FSM ----
    typedef enum logic [2:0] {
        G_IDLE  = 3'd0,
        G_S1    = 3'd1,
        G_S10   = 3'd2,
        G_S101  = 3'd3,
        G_S1011 = 3'd4
    } gold_state_e;

    gold_state_e g_state;
    gold_state_e g_prev_state;   // for coverage sampling

    // ---- Statistics ----
    int num_errors;
    int num_detections;
    int cycle_cnt;

    // ---- Debug controls ----
    bit sb_fault_inject;   // 1: intentionally corrupt one transition in golden model
    int sb_fail_print_max; // number of fail points to print in check_phase
    bit sb_fail_csv_enable;
    string sb_fail_csv_file;
    string sb_test_name;
    int sb_seed;

    // ---- 8-bit din history for mismatch debug ----
    logic [7:0] history;

    // ---- Stored fail points for debug summary ----
    int         fail_cycle_q[$];
    logic [7:0] fail_hist_q[$];
    bit         fail_rstn_q[$];
    bit         fail_din_q[$];
    bit         fail_exp_q[$];
    bit         fail_act_q[$];
    string      fail_state_q[$];


    covergroup fsm_trans_cov;
        option.name    = "fsm_transition_coverage";
        option.comment = "Track all 10 required FSM transitions";

        cp_state : coverpoint g_state {
            bins idle  = {G_IDLE};
            bins s1    = {G_S1};
            bins s10   = {G_S10};
            bins s101  = {G_S101};
            bins s1011 = {G_S1011};
        }

        cp_trans : coverpoint g_state {
            // IDLE transitions
            bins idle_self      = (G_IDLE  => G_IDLE);    // din=0
            bins idle_to_s1     = (G_IDLE  => G_S1);      // din=1

            // S1 transitions
            bins s1_self        = (G_S1    => G_S1);       // din=1 (consecutive 1s)
            bins s1_to_s10      = (G_S1    => G_S10);      // din=0

            // S10 transitions
            bins s10_to_idle    = (G_S10   => G_IDLE);     // din=0
            bins s10_to_s101    = (G_S10   => G_S101);      // din=1

            // S101 transitions (s101_to_s10 is the bait path)
            bins s101_to_s10    = (G_S101  => G_S10);      // din=0 ← bait!
            bins s101_to_s1011  = (G_S101  => G_S1011);    // din=1 → DETECTION

            // S1011 overlap transitions
            bins s1011_to_s1    = (G_S1011 => G_S1);       // din=1 (overlap)
            bins s1011_to_s10   = (G_S1011 => G_S10);      // din=0 (overlap tail)
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        fsm_trans_cov = new();
    endfunction

    // -------------------------------------------------------------------------
    // build_phase: init state, try to pull test_cfg from config_db
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);

        // Initialize golden model
        g_state       = G_IDLE;
        g_prev_state  = G_IDLE;
        num_errors    = 0;
        num_detections = 0;
        cycle_cnt     = 0;
        history       = 8'b0;
        sb_fault_inject = 0;
        sb_fail_print_max = 20;
        sb_fail_csv_enable = 1;
        sb_test_name = "unknown_test";
        sb_seed = 1;

        void'($value$plusargs("SB_FAULT_INJECT=%0d", sb_fault_inject));
        void'($value$plusargs("SB_FAIL_PRINT_MAX=%0d", sb_fail_print_max));
        void'($value$plusargs("SB_FAIL_CSV=%0d", sb_fail_csv_enable));
        void'($value$plusargs("UVM_TESTNAME=%s", sb_test_name));
        void'($value$plusargs("ntb_random_seed=%0d", sb_seed));

        sb_fail_csv_file = $sformatf("../logs/%s_%0d_sb_failpoints.csv", sb_test_name, sb_seed);
        void'($value$plusargs("SB_FAIL_CSV_FILE=%s", sb_fail_csv_file));

        `uvm_info("SB_CFG", $sformatf(
            "Scoreboard debug cfg: SB_FAULT_INJECT=%0d SB_FAIL_PRINT_MAX=%0d SB_FAIL_CSV=%0d SB_FAIL_CSV_FILE=%s",
            sb_fault_inject, sb_fail_print_max, sb_fail_csv_enable, sb_fail_csv_file), UVM_LOW)

        // Pull test configuration — provides expected_detections per test
        if (!uvm_config_db #(det_test_cfg)::get(this, "", "cfg", cfg)) begin
            `uvm_info("SB", "No det_test_cfg in config_db — detection count check disabled",
                UVM_MEDIUM)
            cfg = null;
        end else begin
            `uvm_info("SB",
                $sformatf("Config loaded: %s", cfg.convert2string()), UVM_LOW)
        end
    endfunction

    // -------------------------------------------------------------------------
    // gold_next: pure FSM next-state function (always overlap, matching DUT)
    // -------------------------------------------------------------------------
    function gold_state_e gold_next(gold_state_e cs, logic din);
        case (cs)
            G_IDLE  : return din ? G_S1    : G_IDLE;
            // Optional fault injection for negative testing/demo.
            // Correct behavior for din=0 is G_S10.
            G_S1    : return din ? G_S1    : (sb_fault_inject ? G_IDLE : G_S10);
            G_S10   : return din ? G_S101  : G_IDLE;
            G_S101  : return din ? G_S1011 : G_S10;
            G_S1011 : return din ? G_S1    : G_S10;   // overlap
            default : return G_IDLE;
        endcase
    endfunction

    // -------------------------------------------------------------------------
    // write: one transaction per clock cycle from monitor
    //
    // CRITICAL ORDER: compute from current state → compare → advance state.
    // Do NOT reverse step 1 and step 3. See header comment for failure mode.
    // -------------------------------------------------------------------------
    function void write(det_transaction tr);
        logic expected_dout;

        // Ignore startup/X samples until reset and IO are stable.
        if ($isunknown({tr.rstn, tr.din, tr.dout})) begin
            `uvm_info("SB_SKIP_X", $sformatf(
                "Skip unknown sample: rstn=%0b din=%0b dout=%0b",
                tr.rstn, tr.din, tr.dout), UVM_HIGH)
            return;
        end

        cycle_cnt++;
        history = {history[6:0], tr.din};

        // ── STEP 1: expected output from CURRENT golden state ──────────────
        expected_dout = (g_state == G_S1011) ? 1'b1 : 1'b0;

        // ── STEP 2: compare ────────────────────────────────────────────────
        if (expected_dout !== tr.dout) begin
            num_errors++;

            fail_cycle_q.push_back(cycle_cnt);
            fail_hist_q.push_back(history);
            fail_rstn_q.push_back(tr.rstn);
            fail_din_q.push_back(tr.din);
            fail_exp_q.push_back(expected_dout);
            fail_act_q.push_back(tr.dout);
            fail_state_q.push_back(g_state.name());

            `uvm_error("SB_MISMATCH", $sformatf(
                "MISMATCH @ cycle=%0d | history[7:0]=%08b | rstn=%0b | din=%0b | expected=%0b | actual=%0b | golden_state=%s",
                cycle_cnt, history, tr.rstn, tr.din,
                expected_dout, tr.dout, g_state.name()))
        end else if (expected_dout === 1'b1) begin
            num_detections++;
            `uvm_info("SB_DETECT", $sformatf(
                "DETECTION #%0d @ cycle=%0d | history[7:0]=%08b | state=%s",
                num_detections, cycle_cnt, history, g_state.name()), UVM_LOW)
        end

        `uvm_info("SB", $sformatf(
            "cyc=%0d rstn=%0b din=%0b exp=%0b act=%0b st=%s",
            cycle_cnt, tr.rstn, tr.din,
            expected_dout, tr.dout, g_state.name()), UVM_HIGH)

        // ── STEP 3: advance golden state AFTER compare ─────────────────────
        g_prev_state = g_state;
        if (!tr.rstn)
            g_state = G_IDLE;
        else
            g_state = gold_next(g_state, tr.din);

        // Sample coverage after transition (records g_prev→g_state)
        fsm_trans_cov.sample();

        `uvm_info("SB", $sformatf("          → %s", g_state.name()), UVM_HIGH)
    endfunction

    // -------------------------------------------------------------------------
    // check_phase: golden model pass/fail + expected count check + coverage
    // -------------------------------------------------------------------------
    function void check_phase(uvm_phase phase);
        real cov_pct;
        int i;
        int fail_dump_n;
        integer fd;
        super.check_phase(phase);

        cov_pct = fsm_trans_cov.get_coverage();

        // ── Golden model result ─────────────────────────────────────────────
        `uvm_info("SB_SUMMARY", $sformatf(
            "\n  === SCOREBOARD SUMMARY ===\n  cycles       : %0d\n  detections   : %0d\n  mismatches   : %0d\n  FSM coverage : %.1f%%",
            cycle_cnt, num_detections, num_errors, cov_pct), UVM_LOW)

        if (num_errors > 0)
            `uvm_error("SB_FAIL_GOLDEN",
                $sformatf("GOLDEN MODEL FAIL: %0d mismatch(es)", num_errors))
        else
            `uvm_info("SB_PASS_GOLDEN",
                "GOLDEN MODEL PASS: all cycles match reference", UVM_LOW)

        // Print compact fail-point table for quick debug triage.
        fail_dump_n = (fail_cycle_q.size() < sb_fail_print_max)
                    ? fail_cycle_q.size() : sb_fail_print_max;
        for (i = 0; i < fail_dump_n; i++) begin
            `uvm_info("SB_FAILPOINT", $sformatf(
                "idx=%0d cycle=%0d hist=%08b rstn=%0b din=%0b exp=%0b act=%0b state=%s",
                i, fail_cycle_q[i], fail_hist_q[i], fail_rstn_q[i], fail_din_q[i],
                fail_exp_q[i], fail_act_q[i], fail_state_q[i]), UVM_LOW)
        end
        if (fail_cycle_q.size() > fail_dump_n) begin
            `uvm_info("SB_FAILPOINT", $sformatf(
                "... %0d additional fail points suppressed (increase +SB_FAIL_PRINT_MAX)",
                fail_cycle_q.size() - fail_dump_n), UVM_LOW)
        end

        // Export all fail points to CSV for report submission/debug archive.
        if (sb_fail_csv_enable && fail_cycle_q.size() > 0) begin
            fd = $fopen(sb_fail_csv_file, "w");
            if (fd != 0) begin
                $fwrite(fd, "index,cycle,history_bin,rstn,din,expected,actual,golden_state\n");
                for (i = 0; i < fail_cycle_q.size(); i++) begin
                    $fwrite(fd, "%0d,%0d,%08b,%0b,%0b,%0b,%0b,%s\n",
                        i, fail_cycle_q[i], fail_hist_q[i], fail_rstn_q[i], fail_din_q[i],
                        fail_exp_q[i], fail_act_q[i], fail_state_q[i]);
                end
                $fclose(fd);
                `uvm_info("SB_FAIL_CSV", $sformatf(
                    "Wrote %0d fail points to CSV: %s", fail_cycle_q.size(), sb_fail_csv_file), UVM_LOW)
            end else begin
                `uvm_warning("SB_FAIL_CSV", $sformatf(
                    "Could not open CSV file for writing: %s", sb_fail_csv_file))
            end
        end

        // ── Per-test acceptance criteria ────────────────────────────────────
        if (cfg != null && cfg.check_exact_count) begin
            if (num_detections != cfg.expected_detections) begin
                `uvm_error("SB_FAIL_COUNT", $sformatf(
                    "DETECTION COUNT FAIL: expected=%0d actual=%0d (test=%s)",
                    cfg.expected_detections, num_detections, cfg.test_name))
            end else begin
                `uvm_info("SB_PASS_COUNT", $sformatf(
                    "DETECTION COUNT PASS: expected=%0d actual=%0d",
                    cfg.expected_detections, num_detections), UVM_LOW)
            end
        end

        // ── Coverage warning ───────────────────────────────────────────────
        if (cov_pct < 100.0)
            `uvm_warning("SB_COV_INCOMPLETE", $sformatf(
                "FSM transition coverage: %.1f%% (run test_random_long for 100%%)",
                cov_pct))

    endfunction

endclass : det_scoreboard
