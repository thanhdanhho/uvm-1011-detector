//------------------------------------------------------------------------------
// Class : det_transaction
// Description: UVM sequence item — one clock cycle of stimulus + observation.
//------------------------------------------------------------------------------
class det_transaction extends uvm_sequence_item;

    rand logic din;    // serial input bit (randomized by sequences)
    rand logic rstn;   // reset control   (default constrained to 1)
    logic      dout;   // sampled output  (set by monitor, NOT randomized)

    `uvm_object_utils_begin(det_transaction)
        `uvm_field_int(din,  UVM_ALL_ON)
        `uvm_field_int(rstn, UVM_ALL_ON)
        `uvm_field_int(dout, UVM_ALL_ON)
    `uvm_object_utils_end

    // Default: rstn=1 (no reset); sequences override for reset injection
    constraint c_default_rstn { rstn == 1'b1; }

    function new(string name = "det_transaction");
        super.new(name);
        dout = 1'b0;   // safe default — prevents X at construction time
    endfunction

    function string convert2string();
        return $sformatf("rstn=%0b din=%0b dout=%0b", rstn, din, dout);
    endfunction

    function bit has_x();
        return (^{rstn, din} === 1'bx);
    endfunction

endclass : det_transaction
