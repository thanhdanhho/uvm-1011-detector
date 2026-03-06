//------------------------------------------------------------------------------
// Class : det_monitor
// Description: UVM monitor for det_1011.
//------------------------------------------------------------------------------
class det_monitor extends uvm_monitor;
    `uvm_component_utils(det_monitor)

    virtual det_if          vif;
    uvm_analysis_port #(det_transaction) ap;

    int x_skipped;   // number of X cycles skipped (for debug summary)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap        = new("ap", this);
        x_skipped = 0;
        if (!uvm_config_db #(virtual det_if)::get(this, "", "vif", vif))
            `uvm_fatal("CFG_ERR",
                "Monitor: virtual interface 'vif' not found in uvm_config_db")
    endfunction

    task run_phase(uvm_phase phase);
        det_transaction tr;
        forever begin
            @(vif.monitor_cb);

            tr       = det_transaction::type_id::create("tr");
            tr.rstn  = vif.monitor_cb.rstn;
            tr.din   = vif.monitor_cb.in;
            tr.dout  = vif.monitor_cb.out;

            // X-guard: skip until driven signals and DUT output are known
            if (tr.has_x() || (^tr.dout === 1'bx)) begin
                x_skipped++;
                `uvm_info("MON",
                    $sformatf("Skip X cycle #%0d: %s", x_skipped, tr.convert2string()),
                    UVM_HIGH)
                continue;
            end

            ap.write(tr);
            `uvm_info("MON",
                $sformatf("Sample: %s", tr.convert2string()), UVM_HIGH)
        end
    endtask

endclass : det_monitor
