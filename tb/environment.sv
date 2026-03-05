//------------------------------------------------------------------------------
// Class : det_env
// Description: UVM environment for det_1011.
//   Contains one active agent and one scoreboard.
//   connect_phase wires monitor's analysis_port → scoreboard's analysis_export.
//------------------------------------------------------------------------------
class det_env extends uvm_env;
    `uvm_component_utils(det_env)

    det_agent      agent;       // stimulus + observation path
    det_scoreboard scoreboard;  // golden model + checker

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------------------------
    // build_phase: create agent and scoreboard
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = det_agent::type_id::create("agent",      this);
        scoreboard = det_scoreboard::type_id::create("scoreboard", this);
    endfunction

    // -------------------------------------------------------------------------
    // connect_phase: wire monitor → scoreboard
    //   monitor.ap  (uvm_analysis_port)  → scoreboard.analysis_export (uvm_analysis_imp)
    // -------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        agent.mon.ap.connect(scoreboard.analysis_export);
    endfunction

endclass : det_env
