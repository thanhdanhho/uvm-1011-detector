//------------------------------------------------------------------------------
// Class : det_transaction
// Description: UVM sequence item representing one clock cycle of stimulus.
//   din  - serial bit driven to DUT.in
//   rstn - reset signal driven to DUT.rstn (default 1 = no reset)
//   dout - detection output sampled from DUT.out (filled by monitor, not rand)
//------------------------------------------------------------------------------
class det_transaction extends uvm_sequence_item;

    rand logic din;   // serial input bit (randomized by sequences)
    rand logic rstn;  // reset control   (default constrained to 1)
    logic      dout;  // sampled output  (set by monitor, not randomized)

    // UVM factory registration + field automation
    `uvm_object_utils_begin(det_transaction)
        `uvm_field_int(din,  UVM_ALL_ON)
        `uvm_field_int(rstn, UVM_ALL_ON)
        `uvm_field_int(dout, UVM_ALL_ON)
    `uvm_object_utils_end

    // Default constraint: keep rstn active-high (no reset) unless overridden
    constraint c_default_rstn { rstn == 1'b1; }

    function new(string name = "det_transaction");
        super.new(name);
    endfunction

    // Human-readable string for log messages
    function string convert2string();
        return $sformatf("rstn=%0b din=%0b dout=%0b", rstn, din, dout);
    endfunction

endclass : det_transaction
