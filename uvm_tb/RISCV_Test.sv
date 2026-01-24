// ============================================================================
// RISC-V Base Test
// ============================================================================

class riscv_base_test extends uvm_test;
  
  `uvm_component_utils(riscv_base_test)
  
  riscv_env env;
  
  function new(string name = "riscv_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = riscv_env::type_id::create("env", this);
  endfunction
  
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction
  
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    #1000ns; // Run for 1000ns by default
    
    phase.drop_objection(this);
  endtask
  
endclass

// ============================================================================
// Single ADD Instruction Test
// ============================================================================

class single_add_test extends riscv_base_test;
  
  `uvm_component_utils(single_add_test)
  
  function new(string name = "single_add_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    add_inst_sequence seq;
    
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting Single ADD Instruction Test", UVM_LOW)
    
    // Configure driver with the instruction
    env.agent.driver.set_instruction(32'h00000000, 32'h00100033); // ADD x1, x0, x0 at PC=0
    
    seq = add_inst_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    #500ns;
    
    `uvm_info("TEST", "Single ADD Instruction Test Completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
endclass

// ============================================================================
// Single ADDI Instruction Test
// ============================================================================

class single_addi_test extends riscv_base_test;
  
  `uvm_component_utils(single_addi_test)
  
  function new(string name = "single_addi_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    addi_inst_sequence seq;
    
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting Single ADDI Instruction Test", UVM_LOW)
    
    // ADDI x5, x0, 100
    // Encoding: imm[11:0]=100, rs1=0, funct3=000, rd=5, opcode=0010011
    env.agent.driver.set_instruction(32'h00000000, 32'h06400293);
    
    seq = addi_inst_sequence::type_id::create("seq");
    seq.rd = 5;
    seq.immediate = 100;
    seq.start(env.agent.sequencer);
    
    #500ns;
    
    `uvm_info("TEST", "Single ADDI Instruction Test Completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
endclass

// ============================================================================
// Single LUI Instruction Test
// ============================================================================

class single_lui_test extends riscv_base_test;
  
  `uvm_component_utils(single_lui_test)
  
  function new(string name = "single_lui_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    lui_inst_sequence seq;
    
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting Single LUI Instruction Test", UVM_LOW)
    
    // LUI x10, 0x12345
    // Encoding: imm[31:12]=0x12345, rd=10, opcode=0110111
    env.agent.driver.set_instruction(32'h00000000, 32'h12345537);
    
    seq = lui_inst_sequence::type_id::create("seq");
    seq.rd = 10;
    seq.immediate = 20'h12345;
    seq.start(env.agent.sequencer);
    
    #500ns;
    
    `uvm_info("TEST", "Single LUI Instruction Test Completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
endclass

// ============================================================================
// Store-Load Test
// ============================================================================

class store_load_test extends riscv_base_test;
  
  `uvm_component_utils(store_load_test)
  
  function new(string name = "store_load_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    store_load_sequence seq;
    
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting Store-Load Test", UVM_LOW)
    
    // Program sequence of instructions
    // PC=0x00: ADDI x1, x0, 0x100
    env.agent.driver.set_instruction(32'h00000000, 32'h10000093);
    
    // PC=0x04: ADDI x2, x0, 0xEEF
    env.agent.driver.set_instruction(32'h00000004, 32'hEEF00113);
    
    // PC=0x08: SW x2, 0(x1)
    env.agent.driver.set_instruction(32'h00000008, 32'h0020A023);
    
    // PC=0x0C: LW x3, 0(x1)
    env.agent.driver.set_instruction(32'h0000000C, 32'h0000A183);
    
    seq = store_load_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    #1000ns;
    
    `uvm_info("TEST", "Store-Load Test Completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
endclass

// ============================================================================
// Random Instructions Test
// ============================================================================

class random_test extends riscv_base_test;
  
  `uvm_component_utils(random_test)
  
  function new(string name = "random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    random_inst_sequence seq;
    
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting Random Instructions Test", UVM_LOW)
    
    seq = random_inst_sequence::type_id::create("seq");
    seq.num_instructions = 5000;
    seq.start(env.agent.sequencer);
    
    #5000ns;
    
    `uvm_info("TEST", "Random Instructions Test Completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
endclass

// ============================================================================
// Comprehensive Test - All Instruction Types
// ============================================================================

class comprehensive_test extends riscv_base_test;
  
  `uvm_component_utils(comprehensive_test)
  
  function new(string name = "comprehensive_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    add_inst_sequence add_seq;
    addi_inst_sequence addi_seq;
    lui_inst_sequence lui_seq;
    store_load_sequence mem_seq;
    
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting Comprehensive Test", UVM_LOW)
    
    // Test ADD
    `uvm_info("TEST", "Testing ADD instruction", UVM_LOW)
    add_seq = add_inst_sequence::type_id::create("add_seq");
    add_seq.start(env.agent.sequencer);
    #200ns;
    
    // Test ADDI
    `uvm_info("TEST", "Testing ADDI instruction", UVM_LOW)
    addi_seq = addi_inst_sequence::type_id::create("addi_seq");
    assert(addi_seq.randomize());
    addi_seq.start(env.agent.sequencer);
    #200ns;
    
    // Test LUI
    `uvm_info("TEST", "Testing LUI instruction", UVM_LOW)
    lui_seq = lui_inst_sequence::type_id::create("lui_seq");
    assert(lui_seq.randomize());
    lui_seq.start(env.agent.sequencer);
    #200ns;
    
    // Test Store/Load
    `uvm_info("TEST", "Testing Store/Load instructions", UVM_LOW)
    mem_seq = store_load_sequence::type_id::create("mem_seq");
    mem_seq.start(env.agent.sequencer);
    #500ns;
    
    `uvm_info("TEST", "Comprehensive Test Completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
endclass