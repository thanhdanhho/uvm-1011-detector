//==============================================================================
// File  : sequence.sv
// Author: Danh H. 
// Sequences:
//   det_base_seq              - base class, config pull, helpers
//   det_reset_seq             - N cycles rstn=0 then idle
//   det_directed_1011_seq     - exact [0000]1011[0000]
//   det_no_false_pos_seq      - near-miss + S101→S10 bait + degenerate
//   det_overlap_seq           - 1011011 (overlap) or two 1011 (non-overlap)
//   det_random_long_seq       - >= 1000 random bits
//   det_reset_mid_match_seq   - reset injected at S101 (partial match kill)
//   det_back_to_back_seq      - immediate 1011 after 1011 (no gap)
//==============================================================================


//------------------------------------------------------------------------------
// 1. Base sequence — pulls config, provides drive helpers
//------------------------------------------------------------------------------
class det_base_seq extends uvm_sequence #(det_transaction);
    `uvm_object_utils(det_base_seq)

    det_test_cfg cfg;              // pulled from config_db in pre_start
    int unsigned num_cycles = 100;
    int          overlap_en = 1;

    function new(string name = "det_base_seq");
        super.new(name);
    endfunction

    // Pull config from config_db; fall back to plusargs for CLI convenience
    task pre_start();
        if (uvm_config_db #(det_test_cfg)::get(null,
                get_full_name(), "cfg", cfg)) begin
            num_cycles = cfg.num_cycles;
            overlap_en = cfg.overlap_en;
        end else begin
            if (!$value$plusargs("NUM_CYCLES=%0d", num_cycles)) num_cycles = 100;
            if (!$value$plusargs("OVERLAP_EN=%0d",  overlap_en)) overlap_en = 1;
        end
    endtask

    // Drive one bit, rstn=1
    task send_bit(logic b);
        det_transaction tr;
        tr = det_transaction::type_id::create("tr");
        start_item(tr);
        tr.rstn = 1'b1;
        tr.din  = b;
        finish_item(tr);
    endtask

    // Drive N zeros (idle / gap)
    task send_idle(int n);
        repeat (n) send_bit(1'b0);
    endtask

    // Drive a 4-bit nibble MSB first
    task send_nibble(logic [3:0] bits);
        for (int i = 3; i >= 0; i--)
            send_bit(bits[i]);
    endtask

    task body(); endtask

endclass : det_base_seq


//------------------------------------------------------------------------------
// 2. Reset sequence
//------------------------------------------------------------------------------
class det_reset_seq extends det_base_seq;
    `uvm_object_utils(det_reset_seq)

    int n_reset = 5;
    int n_idle  = 3;

    function new(string name = "det_reset_seq");
        super.new(name);
    endfunction

    task body();
        det_transaction tr;
        repeat (n_reset) begin
            tr = det_transaction::type_id::create("tr");
            start_item(tr);
            tr.rstn = 1'b0;
            tr.din  = 1'b0;
            finish_item(tr);
        end
        send_idle(n_idle);
        `uvm_info("RST_SEQ",
            $sformatf("Reset: %0d cycles rstn=0, %0d idle", n_reset, n_idle),
            UVM_MEDIUM)
    endtask

endclass : det_reset_seq


//------------------------------------------------------------------------------
// 3. Directed 1011
//------------------------------------------------------------------------------
class det_directed_1011_seq extends det_base_seq;
    `uvm_object_utils(det_directed_1011_seq)

    int preamble  = 4;
    int postamble = 4;

    function new(string name = "det_directed_1011_seq");
        super.new(name);
    endfunction

    task body();
        send_idle(preamble);
        // Exact pattern
        send_bit(1'b1);
        send_bit(1'b0);
        send_bit(1'b1);
        send_bit(1'b1);
        send_idle(postamble);
        `uvm_info("DIR_SEQ", "Directed 1011 sent", UVM_MEDIUM)
    endtask

endclass : det_directed_1011_seq


//------------------------------------------------------------------------------
// 4. No-false-positive sequence
//------------------------------------------------------------------------------
class det_no_false_pos_seq extends det_base_seq;
    `uvm_object_utils(det_no_false_pos_seq)

    function new(string name = "det_no_false_pos_seq");
        super.new(name);
    endfunction

    task body();
        send_idle(2);

        // --- Group A: 4-bit near-miss ---
        // 1010: FSM path IDLE→S1→S10→S101→S10, no detect
        send_bit(1); send_bit(0); send_bit(1); send_bit(0);
        send_idle(4);

        // 1001: IDLE→S1→S10→IDLE→S1, no detect
        send_bit(1); send_bit(0); send_bit(0); send_bit(1);
        send_idle(4);

        // 0111: IDLE→IDLE→S1→S1→S1, no detect
        send_bit(0); send_bit(1); send_bit(1); send_bit(1);
        send_idle(4);

        // 1110: IDLE→S1→S1→S1→S10, no detect
        send_bit(1); send_bit(1); send_bit(1); send_bit(0);
        send_idle(4);

        // 0101: IDLE→IDLE→S1→S10→S101, no detect
        send_bit(0); send_bit(1); send_bit(0); send_bit(1);
        send_idle(4);

        // --- Group B: degenerate patterns ---
        send_idle(8);                       // all zeros

        repeat(8) send_bit(1'b1);           // all ones: FSM loops S1→S1
        send_idle(4);

        repeat(5) begin                     // 1010101010: no 1011 substring
            send_bit(1'b1); send_bit(1'b0);
        end
        send_idle(4);

        repeat(3) begin                     // 110011001100: no 1011
            send_bit(1); send_bit(1);
            send_bit(0); send_bit(0);
        end
        send_idle(4);

        // --- Group C: S101→S10 bait (critical path, produces 1 detection) ---
        // "10101011": FSM with correct S101→S10 on din=0:
        //   IDLE→S1→S10→S101→S10→S101→S1011  ← 1 detection
        // FSM with bug (S101→IDLE on din=0):
        //   IDLE→S1→S10→S101→IDLE→S1→S10→S101 → at this cycle we need one more bit
        //   BUT scoreboard already mismatched at cycle 4 (expected out from S101
        //   transitions to S10 state, bug gives IDLE state) — caught before detection.
        send_bit(1); send_bit(0); send_bit(1); send_bit(0);   // "1010" → reach S101 then S10
        send_bit(1); send_bit(0); send_bit(1); send_bit(1);   // "1011" → S10→S101→S1011
        send_idle(4);
        `uvm_info("NFP_SEQ", "Group C (S101→S10 bait): 10101011 sent — expect 1 detection", UVM_MEDIUM)

        // --- Group D: longer no-match sequences ---
        // 100100100: repetitive, never forms 1011
        repeat(4) begin
            send_bit(1); send_bit(0); send_bit(0);
        end
        send_idle(4);

        `uvm_info("NFP_SEQ", "All no-false-positive patterns sent", UVM_MEDIUM)
    endtask

endclass : det_no_false_pos_seq


//------------------------------------------------------------------------------
// 5. Overlap sequence
//------------------------------------------------------------------------------
class det_overlap_seq extends det_base_seq;
    `uvm_object_utils(det_overlap_seq)

    function new(string name = "det_overlap_seq");
        super.new(name);
    endfunction

    task body();
        send_idle(2);

        if (overlap_en) begin
            // "1011011": S1011→S10→S101→S1011 → 2 detections
            send_bit(1); send_bit(0); send_bit(1); send_bit(1);  // 1011 → detect#1
            send_bit(0); send_bit(1); send_bit(1);               // 011  → detect#2
            send_idle(4);
            `uvm_info("OVL_SEQ", "Overlap=1: 1011011 sent (expect 2 detections)", UVM_LOW)
        end else begin
            // Two separate 1011 with 6-cycle gap (FSM fully resets to IDLE)
            send_bit(1); send_bit(0); send_bit(1); send_bit(1);
            send_idle(6);
            send_bit(1); send_bit(0); send_bit(1); send_bit(1);
            send_idle(4);
            `uvm_info("OVL_SEQ", "Overlap=0: 1011 gap 1011 sent (expect 2 detections)", UVM_LOW)
        end
    endtask

endclass : det_overlap_seq


//------------------------------------------------------------------------------
// 6. Random long sequence (>= 1000 cycles)
//------------------------------------------------------------------------------
class det_random_long_seq extends det_base_seq;
    `uvm_object_utils(det_random_long_seq)

    function new(string name = "det_random_long_seq");
        super.new(name);
    endfunction

    task body();
        det_transaction tr;
        if (num_cycles < 1000) num_cycles = 1000;

        repeat (num_cycles) begin
            tr = det_transaction::type_id::create("tr");
            start_item(tr);
            if (!tr.randomize() with { rstn == 1'b1; })
                `uvm_error("RAND_SEQ", "Randomization failed")
            finish_item(tr);
        end
        send_idle(4);  // flush: capture last detection

        `uvm_info("RND_SEQ",
            $sformatf("Random sequence done: %0d cycles", num_cycles), UVM_LOW)
    endtask

endclass : det_random_long_seq


//------------------------------------------------------------------------------
// 7. Reset mid-match sequence (NEW)
// Drives 1, 0, 1 to reach S101 (partial match), then injects reset.
// After reset, drives 1011 to confirm clean recovery.
// Scoreboard: 0 detections from partial match (reset clears it),
//             1 detection from the recovery 1011.
//------------------------------------------------------------------------------
class det_reset_mid_match_seq extends det_base_seq;
    `uvm_object_utils(det_reset_mid_match_seq)

    function new(string name = "det_reset_mid_match_seq");
        super.new(name);
    endfunction

    task body();
        det_transaction tr;

        send_idle(2);

        // Drive 1, 0, 1 → FSM at S101 (one bit away from detection)
        send_bit(1'b1);
        send_bit(1'b0);
        send_bit(1'b1);
        `uvm_info("MID_RST_SEQ", "FSM at S101 — injecting reset now", UVM_MEDIUM)

        // Inject reset for 3 cycles (kills partial match)
        repeat (3) begin
            tr = det_transaction::type_id::create("tr");
            start_item(tr);
            tr.rstn = 1'b0;
            tr.din  = 1'b0;
            finish_item(tr);
        end

        // Settle
        send_idle(2);

        // Now drive clean 1011 — should produce exactly 1 detection
        send_bit(1'b1);
        send_bit(1'b0);
        send_bit(1'b1);
        send_bit(1'b1);
        send_idle(4);

        `uvm_info("MID_RST_SEQ", "Post-reset 1011 sent (expect 1 detection)", UVM_LOW)
    endtask

endclass : det_reset_mid_match_seq


//------------------------------------------------------------------------------
// 8. Back-to-back sequence (NEW)
// Sends 1011 immediately followed by another 1011 with no gap.
// The DUT overlap logic (S1011→S1 or S1011→S10) determines whether
// the second 1011 is detected — scoreboard verifies based on golden model.
// Expected: 2 detections (overlap: 1011 + continuation 011 → detect#2).
//------------------------------------------------------------------------------
class det_back_to_back_seq extends det_base_seq;
    `uvm_object_utils(det_back_to_back_seq)

    function new(string name = "det_back_to_back_seq");
        super.new(name);
    endfunction

    task body();
        send_idle(2);

        // First 1011
        send_bit(1'b1); send_bit(1'b0); send_bit(1'b1); send_bit(1'b1);
        // Immediately: second 1011 (no gap — tests S1011 transition logic)
        send_bit(1'b1); send_bit(1'b0); send_bit(1'b1); send_bit(1'b1);
        send_idle(4);

        `uvm_info("B2B_SEQ",
            "Back-to-back 1011+1011 sent", UVM_LOW)
    endtask

endclass : det_back_to_back_seq
