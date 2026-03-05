//==============================================================================
// File  : sequence.sv
// Description: All UVM sequences for det_1011 verification.
//   1. det_base_seq         - base class with helpers; reads plusargs
//   2. det_reset_seq        - asserts rstn=0 for N cycles then idles
//   3. det_directed_1011_seq- sends exact 1011 pattern with preamble/postamble
//   4. det_no_false_pos_seq - sends patterns that must NOT trigger detection
//   5. det_overlap_seq      - sends 1011011 (overlap) or two separate 1011 (no-overlap)
//   6. det_random_long_seq  - fully random bits for num_cycles cycles
//==============================================================================


// -----------------------------------------------------------------------------
// 1. Base sequence — shared helpers and plusarg parsing
// -----------------------------------------------------------------------------
class det_base_seq extends uvm_sequence #(det_transaction);
    `uvm_object_utils(det_base_seq)

    int unsigned num_cycles = 100;   // used by random sequence
    int          overlap_en = 1;     // 1 = overlap mode, 0 = non-overlap mode

    function new(string name = "det_base_seq");
        super.new(name);
    endfunction

    // Read runtime plusargs before body() executes
    task pre_start();
        if (!$value$plusargs("NUM_CYCLES=%0d", num_cycles)) num_cycles = 100;
        if (!$value$plusargs("OVERLAP_EN=%0d",  overlap_en)) overlap_en  = 1;
    endtask

    // -------------------------------------------------------------------------
    // Helper: drive a single bit with rstn=1
    // -------------------------------------------------------------------------
    task send_bit(logic b);
        det_transaction tr = det_transaction::type_id::create("tr");
        start_item(tr);
        tr.rstn = 1'b1;
        tr.din  = b;
        finish_item(tr);
    endtask

    // -------------------------------------------------------------------------
    // Helper: drive N idle (zero) bits
    // -------------------------------------------------------------------------
    task send_idle(int n);
        repeat (n) send_bit(1'b0);
    endtask

    task body(); endtask   // subclasses override

endclass : det_base_seq


// -----------------------------------------------------------------------------
// 2. Reset sequence — asserts reset for n_reset cycles, then n_idle idle cycles
// -----------------------------------------------------------------------------
class det_reset_seq extends det_base_seq;
    `uvm_object_utils(det_reset_seq)

    int n_reset = 5;   // cycles with rstn=0
    int n_idle  = 3;   // idle cycles after reset de-assertion

    function new(string name = "det_reset_seq");
        super.new(name);
    endfunction

    task body();
        det_transaction tr;

        // Assert reset
        repeat (n_reset) begin
            tr = det_transaction::type_id::create("tr");
            start_item(tr);
            tr.rstn = 1'b0;
            tr.din  = 1'b0;
            finish_item(tr);
        end

        // De-assert reset and run idle bits to let DUT settle
        send_idle(n_idle);

        `uvm_info("RST_SEQ",
            $sformatf("Reset complete: %0d reset cycles + %0d idle", n_reset, n_idle),
            UVM_MEDIUM)
    endtask

endclass : det_reset_seq


// -----------------------------------------------------------------------------
// 3. Directed 1011 sequence
//    Sends: [preamble zeros] 1 0 1 1 [postamble zeros]
//    Expected: one detection pulse after the final '1'
// -----------------------------------------------------------------------------
class det_directed_1011_seq extends det_base_seq;
    `uvm_object_utils(det_directed_1011_seq)

    int preamble  = 4;   // idle bits before pattern
    int postamble = 4;   // idle bits after  pattern

    function new(string name = "det_directed_1011_seq");
        super.new(name);
    endfunction

    task body();
        send_idle(preamble);

        // Target pattern: 1 0 1 1
        send_bit(1'b1);
        send_bit(1'b0);
        send_bit(1'b1);
        send_bit(1'b1);

        send_idle(postamble);  // postamble lets monitor capture the dout=1 cycle

        `uvm_info("DIR_SEQ", "Directed 1011 pattern sent", UVM_MEDIUM)
    endtask

endclass : det_directed_1011_seq


// -----------------------------------------------------------------------------
// 4. No-false-positive sequence
//    Sends near-miss patterns that must NOT produce a detection.
//    Any scoreboard mismatch here means the DUT has a false-positive bug.
// -----------------------------------------------------------------------------
class det_no_false_pos_seq extends det_base_seq;
    `uvm_object_utils(det_no_false_pos_seq)

    function new(string name = "det_no_false_pos_seq");
        super.new(name);
    endfunction

    task body();
        // Helper local task to send a 4-bit pattern + gap
        // (cannot call external task inside; inline the sends)

        send_idle(2);

        // 1010 — last bit is 0, not 1
        send_bit(1); send_bit(0); send_bit(1); send_bit(0);
        send_idle(3);

        // 1001 — middle bits wrong
        send_bit(1); send_bit(0); send_bit(0); send_bit(1);
        send_idle(3);

        // 0111 — starts with 0
        send_bit(0); send_bit(1); send_bit(1); send_bit(1);
        send_idle(3);

        // 1110 — last bit 0, pattern ends wrong
        send_bit(1); send_bit(1); send_bit(1); send_bit(0);
        send_idle(3);

        // 0101 — alternating, no 1011
        send_bit(0); send_bit(1); send_bit(0); send_bit(1);
        send_idle(3);

        // All zeros
        send_idle(8);

        // All ones — 11111111 (DUT stays in S1 the whole time, no detection)
        repeat(8) send_bit(1);
        send_idle(4);

        // 1010101010 — no 1011 anywhere
        repeat(5) begin send_bit(1); send_bit(0); end
        send_idle(4);

        `uvm_info("NFP_SEQ", "No-false-positive patterns sent", UVM_MEDIUM)
    endtask

endclass : det_no_false_pos_seq


// -----------------------------------------------------------------------------
// 5. Overlap sequence
//    OVERLAP_EN=1: sends 1011011 → expects TWO detections (at bit4 and bit7)
//    OVERLAP_EN=0: sends 1011 [gap] 1011 → expects TWO separate detections
// -----------------------------------------------------------------------------
class det_overlap_seq extends det_base_seq;
    `uvm_object_utils(det_overlap_seq)

    function new(string name = "det_overlap_seq");
        super.new(name);
    endfunction

    task body();
        send_idle(2);  // preamble

        if (overlap_en) begin
            // Overlapping: 1011011
            // First  detection after bit4 (second '1')
            // Second detection after bit7 (second group's '1')
            send_bit(1); send_bit(0); send_bit(1); send_bit(1);  // 1011
            send_bit(0); send_bit(1); send_bit(1);               // 011 → completes second 1011
            send_idle(3);  // postamble (captures second detection)
            `uvm_info("OVL_SEQ", "Overlap mode: 1011011 sent (expect 2 detections)", UVM_MEDIUM)
        end else begin
            // Non-overlap: two separate 1011 patterns with a 4-cycle gap
            send_bit(1); send_bit(0); send_bit(1); send_bit(1);  // first  1011
            send_idle(6);                                          // gap (resets FSM state)
            send_bit(1); send_bit(0); send_bit(1); send_bit(1);  // second 1011
            send_idle(3);  // postamble
            `uvm_info("OVL_SEQ", "Non-overlap mode: two 1011 patterns sent (expect 2 detections)", UVM_MEDIUM)
        end
    endtask

endclass : det_overlap_seq


// -----------------------------------------------------------------------------
// 6. Random long sequence — fully randomized bits for num_cycles cycles
//    Seed is controlled by +ntb_random_seed=<N> at simulation runtime.
//    The scoreboard verifies every cycle via the golden FSM model.
// -----------------------------------------------------------------------------
class det_random_long_seq extends det_base_seq;
    `uvm_object_utils(det_random_long_seq)

    function new(string name = "det_random_long_seq");
        super.new(name);
    endfunction

    task body();
        det_transaction tr;

        if (num_cycles < 1000) num_cycles = 1000;  // enforce minimum per spec

        repeat (num_cycles) begin
            tr = det_transaction::type_id::create("tr");
            start_item(tr);
            if (!tr.randomize() with { rstn == 1'b1; })
                `uvm_error("RAND_SEQ", "Randomization failed")
            finish_item(tr);
        end

        send_idle(4);  // flush pipeline so last detection is captured

        `uvm_info("RND_SEQ",
            $sformatf("Random long sequence done: %0d cycles", num_cycles), UVM_LOW)
    endtask

endclass : det_random_long_seq
