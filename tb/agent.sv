//------------------------------------------------------------------------------
// Class : det_agent
// Description: UVM agent for det_1011.
//   Active mode  (UVM_ACTIVE)  : creates sequencer + driver + monitor.
//   Passive mode (UVM_PASSIVE) : creates monitor only (no stimulus).
//   connect_phase wires driver seq_item_port → sequencer seq_item_export.
//------------------------------------------------------------------------------
class det_agent extends uvm_agent;
    `uvm_component_utils(det_agent)

    det_sequencer  seqr;   // arbitrates between sequences
    det_driver     drv;    // drives DUT pins via clocking block
    det_monitor    mon;    // samples DUT pins and broadcasts transactions

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------------------------
    // build_phase: instantiate sub-components based on active/passive mode
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = det_monitor::type_id::create("mon", this);
        if (get_is_active() == UVM_ACTIVE) begin
            seqr = det_sequencer::type_id::create("seqr", this);
            drv  = det_driver::type_id::create("drv",  this);
        end
    endfunction

    // -------------------------------------------------------------------------
    // connect_phase: connect driver request port to sequencer response export
    // -------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        if (get_is_active() == UVM_ACTIVE)
            drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction

endclass : det_agent
