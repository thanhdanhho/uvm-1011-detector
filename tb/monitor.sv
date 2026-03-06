//------------------------------------------------------------------------------
// Class : det_monitor
// Description: UVM monitor for det_1011.

class det_monitor extends uvm_monitor;
    `uvm_component_utils(det_monitor)

    virtual det_if          vif;   // virtual interface handle
    uvm_analysis_port #(det_transaction) ap;   // broadcast to scoreboard

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual det_if)::get(this, "", "vif", vif))
            `uvm_fatal("CFG_ERR",
                "Monitor: virtual interface 'vif' not found in uvm_config_db")
    endfunction


    task run_phase(uvm_phase phase);
        det_transaction tr;
        forever begin
            @(vif.monitor_cb);                 
            tr        = det_transaction::type_id::create("tr");
            tr.rstn   = vif.monitor_cb.rstn;   
            tr.din    = vif.monitor_cb.in;       
            tr.dout   = vif.monitor_cb.out;     
            ap.write(tr);                       
            `uvm_info("MON",
                $sformatf("Sample: %s", tr.convert2string()), UVM_HIGH)
        end
    endtask

endclass : det_monitor
