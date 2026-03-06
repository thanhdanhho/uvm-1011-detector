//------------------------------------------------------------------------------
// Class : det_driver
// Description: UVM driver for det_1011.

class det_driver extends uvm_driver #(det_transaction);
    `uvm_component_utils(det_driver)

    virtual det_if vif;   // virtual handle obtained from config_db

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------------------------
    // build_phase: get virtual interface from config_db
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual det_if)::get(this, "", "vif", vif))
            `uvm_fatal("CFG_ERR",
                "Driver: virtual interface 'vif' not found in uvm_config_db")
    endfunction

    // -------------------------------------------------------------------------
    // run_phase: initial reset → main drive loop
    // -------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        det_transaction tr;

        vif.driver_cb.rstn <= 1'b0;
        vif.driver_cb.in   <= 1'b0;
        repeat (5) @(vif.driver_cb);
        vif.driver_cb.rstn <= 1'b1;
        `uvm_info("DRV", "Initial 5-cycle reset complete", UVM_LOW)
        forever begin
            seq_item_port.get_next_item(tr);
            drive_item(tr);
            seq_item_port.item_done();
        end
    endtask


    task drive_item(det_transaction tr);
        @(vif.driver_cb);                  
        vif.driver_cb.rstn <= tr.rstn;
        vif.driver_cb.in   <= tr.din;
        `uvm_info("DRV",
            $sformatf("Drive: %s", tr.convert2string()), UVM_HIGH)
    endtask

endclass : det_driver
