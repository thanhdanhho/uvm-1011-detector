//==============================================================================
// Class : det_scoreboard
// Description: UVM scoreboard with a golden reference FSM model for det_1011.
//
// Timing model (matches monitor_cb with input #1):
//   Each transaction {rstn, din, dout} represents one clock cycle where:
//     - dout  = DUT output based on the state from the PREVIOUS posedge
//     - din   = the bit the DUT will latch AT the current posedge
//     - rstn  = the reset level the DUT will see AT the current posedge
//
//   Scoreboard algorithm per transaction:
//     1. Compute expected_dout = (g_state == G_S1011)  [current state → output]
//     2. Compare expected_dout vs tr.dout
//     3. Advance g_state:
//          if rstn==0  → g_state = G_IDLE  (DUT resets at this posedge)
//          else        → g_state = gold_next(g_state, din)
//
//   The golden FSM always uses OVERLAP transitions (matching the DUT).
//   OVERLAP_EN only controls test sequence generation, not the golden model.
//
// Debug log fields (per mismatch):
//   cycle_cnt, history[7:0] (last 8 din bits), din, expected, actual
//==============================================================================
class det_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(det_scoreboard)

    // Analysis export to receive transactions from monitor
    uvm_analysis_imp #(det_transaction, det_scoreboard) analysis_export;

    // -------------------------------------------------------------------------
    // Golden FSM state encoding (mirrors DUT's parameter names)
    // -------------------------------------------------------------------------
    typedef enum logic [2:0] {
        G_IDLE  = 3'd0,
        G_S1    = 3'd1,
        G_S10   = 3'd2,
        G_S101  = 3'd3,
        G_S1011 = 3'd4
    } gold_state_e;

    // Golden model state
    gold_state_e g_state;

    // Statistics
    int num_errors;
    int num_detections;
    int cycle_cnt;
    int init_cycles;  // cycles to skip during initialization

    // Debug: last 8 bits of din history (shift register)
    logic [7:0] history;

    // Runtime config (read from plusargs)
    int overlap_en;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------------------------
    // build_phase: create port, initialise golden model
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
        g_state        = G_IDLE;
        num_errors     = 0;
        num_detections = 0;
        cycle_cnt      = 0;
        init_cycles    = 2;  // skip first 2 cycles (initialization)
        history        = 8'b0;
        overlap_en     = 1;
        if (!$value$plusargs("OVERLAP_EN=%0d", overlap_en)) overlap_en = 1;
    endfunction

    // -------------------------------------------------------------------------
    // gold_next: golden FSM next-state function (always overlap mode, like DUT)
    // -------------------------------------------------------------------------
    function gold_state_e gold_next(gold_state_e cs, logic din);
        case (cs)
            G_IDLE  : return din ? G_S1    : G_IDLE;
            G_S1    : return din ? G_S1    : G_S10;
            G_S10   : return din ? G_S101  : G_IDLE;
            G_S101  : return din ? G_S1011 : G_S10;
            G_S1011 : return din ? G_S1    : G_S10;  // overlap transitions
            default : return G_IDLE;
        endcase
    endfunction

    // -------------------------------------------------------------------------
    // write: called by analysis port on every monitor transaction
    // -------------------------------------------------------------------------
    function void write(det_transaction tr);
        logic expected_dout;
        logic skip_check;

        cycle_cnt++;
        history = {history[6:0], tr.din};  // shift in new bit
        
        // Skip first init_cycles cycles (initialization phase with undefined values)
        skip_check = (cycle_cnt <= init_cycles);

        // Step 1: expected output based on CURRENT golden state
        expected_dout = (g_state == G_S1011) ? 1'b1 : 1'b0;

        // Step 2: compare expected vs actual (skip during initialization)
        if (!skip_check && expected_dout !== tr.dout) begin
            num_errors++;
            `uvm_error("SB_MISMATCH",
                $sformatf(
                    "MISMATCH @ cycle=%0d | history[7:0]=%08b | rstn=%0b | din=%0b | expected_dout=%0b | actual_dout=%0b | golden_state=%s",
                    cycle_cnt, history, tr.rstn, tr.din,
                    expected_dout, tr.dout, g_state.name()))
        end else if (!skip_check && expected_dout === 1'b1) begin
            num_detections++;
            `uvm_info("SB_DETECT",
                $sformatf(
                    "DETECTION #%0d @ cycle=%0d | history[7:0]=%08b | din=%0b",
                    num_detections, cycle_cnt, history, tr.din),
                UVM_LOW)
        end

        `uvm_info("SB",
            $sformatf(
                "cycle=%0d rstn=%0b din=%0b exp=%0b act=%0b state=%s→",
                cycle_cnt, tr.rstn, tr.din,
                expected_dout, tr.dout, g_state.name()),
            UVM_HIGH)

        // Step 3: advance golden state for next cycle
        if (!tr.rstn)
            g_state = G_IDLE;           // DUT resets at this posedge
        else
            g_state = gold_next(g_state, tr.din);

        `uvm_info("SB",
            $sformatf("        → next_state=%s", g_state.name()), UVM_HIGH)
    endfunction

    // -------------------------------------------------------------------------
    // check_phase: final pass/fail report
    // -------------------------------------------------------------------------
    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        `uvm_info("SB_SUMMARY",
            $sformatf(
                "=== SCOREBOARD SUMMARY: cycles=%0d (init_skip=%0d, check=%0d) detections=%0d mismatches=%0d ===",
                cycle_cnt, init_cycles, cycle_cnt - init_cycles, num_detections, num_errors),
            UVM_LOW)
        if (num_errors > 0)
            `uvm_error("SB_FAIL",
                $sformatf("SCOREBOARD FAIL: %0d mismatch(es) detected", num_errors))
        else
            `uvm_info("SB_PASS", "SCOREBOARD PASS: All cycles match golden model", UVM_LOW)
    endfunction

endclass : det_scoreboard
