// ============================================================================
// RISC-V Environment
// ============================================================================

class riscv_env extends uvm_env;
  
  `uvm_component_utils(riscv_env)
  
  riscv_agent      agent;
  riscv_scoreboard scoreboard;
  riscv_coverage   coverage_;
  
  function new(string name = "riscv_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    agent = riscv_agent::type_id::create("agent", this);
    scoreboard = riscv_scoreboard::type_id::create("scoreboard", this);
    // FIXED: Changed "coverage"_ to "coverage_" (underscore was in wrong place)
    coverage_ = riscv_coverage::type_id::create("coverage_", this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect monitor to scoreboard and coverage
    agent.monitor.analysis_port.connect(scoreboard.analysis_export);
    agent.monitor.analysis_port.connect(coverage_.analysis_export);
  endfunction
  
endclass