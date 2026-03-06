//==============================================================================
// Class : det_test_cfg
// Description: Central configuration object for det_1011 verification.

class det_test_cfg extends uvm_object;
    int    expected_detections = -1;  // -1 = don't check count (just check golden)
    int    overlap_en          = 1;
    int    num_cycles          = 1000;
    bit    check_exact_count   = 0;   // set to 1 in directed tests
    string test_name           = "unknown";

    `uvm_object_utils_begin(det_test_cfg)
        `uvm_field_int(expected_detections, UVM_ALL_ON)
        `uvm_field_int(overlap_en,          UVM_ALL_ON)
        `uvm_field_int(num_cycles,          UVM_ALL_ON)
        `uvm_field_int(check_exact_count,   UVM_ALL_ON)
        `uvm_field_string(test_name,        UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "det_test_cfg");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf(
            "test=%s overlap_en=%0d num_cycles=%0d expected_detections=%0d check_exact=%0b",
            test_name, overlap_en, num_cycles, expected_detections, check_exact_count);
    endfunction

endclass : det_test_cfg
