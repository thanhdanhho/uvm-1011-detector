//==============================================================================
// filelist.f — Ordered file list for vlog (QuestaSim) and vcs
// Usage:
//   QuestaSim : vlog -sv -f sim/filelist.f
//   VCS       : vcs -sverilog -f sim/filelist.f ...
//
// Order:
//   1. Interface (no UVM deps, referenced by pkg and testbench)
//   2. RTL DUT   (no UVM deps)
//   3. Package   (`includes all TB classes inside — must come before testbench)
//   4. Testbench top (imports pkg, instantiates DUT + interface)
//==============================================================================

// --- SystemVerilog interface ---
../tb/interface.sv

// --- RTL (Design Under Test) ---
../rtl/det_1011.sv

// --- UVM TB package (contains all classes via `include) ---
../tb/pkg.sv

// --- Top-level testbench module ---
../tb/testbench.sv
