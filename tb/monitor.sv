//------------------------------------------------------------------------------
// Class : det_monitor
// Description: UVM monitor for det_1011.
//   Sampling strategy: uses monitor_cb clocking block (input #1 = 1ns BEFORE
//   posedge). At this sample point:
//     - rstn, in : stable values the DUT will latch at the next posedge
//     - out      : combinational output reflecting cur_state from PREVIOUS posedge
//   Transactions are broadcast to connected subscribers (scoreboard) via ap.
//------------------------------------------------------------------------------
class det_monitor extends uvm_monitor;
    `uvm_component_utils(det_monitor)

    virtual det_if          vif;   // virtual interface handle
    uvm_analysis_port #(det_transaction) ap;   // broadcast to scoreboard

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------------------------
    // build_phase: create analysis port, get virtual interface
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual det_if)::get(this, "", "vif", vif))
            `uvm_fatal("CFG_ERR",
                "Monitor: virtual interface 'vif' not found in uvm_config_db")
    endfunction

    // -------------------------------------------------------------------------
    // run_phase: sample one transaction per clock cycle, forever
    // -------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        det_transaction tr;
        forever begin
            @(vif.monitor_cb);                  // wait for posedge (samples at posedge-1ns)
            tr        = det_transaction::type_id::create("tr");
            tr.rstn   = vif.monitor_cb.rstn;    // reset state for this cycle
            tr.din    = vif.monitor_cb.in;       // input that DUT will latch at posedge
            tr.dout   = vif.monitor_cb.out;      // detection from PREVIOUS state
            ap.write(tr);                        // forward to scoreboard
            `uvm_info("MON",
                $sformatf("Sample: %s", tr.convert2string()), UVM_HIGH)
        end
    endtask

endclass : det_monitor
