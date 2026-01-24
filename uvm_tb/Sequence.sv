// ============================================================================
// RISC-V Base Sequence
// ============================================================================

class riscv_base_sequence extends uvm_sequence #(riscv_transaction);
  
  `uvm_object_utils(riscv_base_sequence)
  
  function new(string name = "riscv_base_sequence");
    super.new(name);
  endfunction
  
endclass

// ============================================================================
// Single Instruction Sequence - For Basic Testing
// ============================================================================

class single_inst_sequence extends riscv_base_sequence;
  
  `uvm_object_utils(single_inst_sequence)
  
  bit [31:0] instruction;
  
  function new(string name = "single_inst_sequence");
    super.new(name);
    instruction = 32'h00000013; // Default to NOP (ADDI x0, x0, 0)
  endfunction
  
  task body();
    riscv_transaction tr;
    
    `uvm_info("SEQ", $sformatf("Executing single instruction: 0x%0h", instruction), UVM_LOW)
    
    // Send the transaction
    tr = riscv_transaction::type_id::create("tr");
    start_item(tr);
    tr.reset = 0;
    tr.I_Req = 0;
    tr.inst_data = instruction;
    tr.Rdata = 32'h0;
    finish_item(tr);
    
    // Wait for instruction to complete (5 cycles for pipeline)
    repeat(10) begin
      tr = riscv_transaction::type_id::create("tr");
      start_item(tr);
      tr.reset = 0;
      tr.I_Req = 0;
      finish_item(tr);
    end
  endtask
  
endclass

// ============================================================================
// Simple ADD Instruction Sequence
// Test: ADD x1, x0, x0 (should write 0 to x1)
// ============================================================================

class add_inst_sequence extends riscv_base_sequence;
  
  `uvm_object_utils(add_inst_sequence)
  
  function new(string name = "add_inst_sequence");
    super.new(name);
  endfunction
  
  task body();
    riscv_transaction tr;
    bit [31:0] add_inst;
    
    // Encode ADD x1, x0, x0
    // opcode = 0110011 (OP)
    // rd = 1, funct3 = 000, rs1 = 0, rs2 = 0, funct7 = 0000000
    add_inst = {7'b0000000, 5'd0, 5'd0, 3'b000, 5'd1, 7'b0110011};
    
    `uvm_info("SEQ", $sformatf("Executing ADD x1, x0, x0 (inst=0x%0h)", add_inst), UVM_LOW)
    
    tr = riscv_transaction::type_id::create("tr");
    start_item(tr);
    tr.reset = 0;
    tr.I_Req = 0;
    tr.inst_data = add_inst;
    tr.Rdata = 32'h0;
    finish_item(tr);
    
    // Wait for completion
    repeat(10) begin
      tr = riscv_transaction::type_id::create("tr");
      start_item(tr);
      tr.reset = 0;
      tr.I_Req = 0;
      finish_item(tr);
    end
  endtask
  
endclass

// ============================================================================
// ADDI Instruction Sequence
// Test: ADDI x5, x0, 100 (should write 100 to x5)
// ============================================================================

class addi_inst_sequence extends riscv_base_sequence;
  
  `uvm_object_utils(addi_inst_sequence)
  
  rand bit [11:0] immediate;
  rand bit [4:0]  rd;
  
  constraint c_rd { rd inside {[1:31]}; }
  constraint c_imm { immediate inside {[0:2047]}; }
  
  function new(string name = "addi_inst_sequence");
    super.new(name);
  endfunction
  
  task body();
    riscv_transaction tr;
    bit [31:0] addi_inst;
    
    // Encode ADDI rd, x0, immediate
    // opcode = 0010011 (OP-IMM)
    // rd = rd, funct3 = 000, rs1 = 0, imm[11:0]
    addi_inst = {immediate, 5'd0, 3'b000, rd, 7'b0010011};
    
    `uvm_info("SEQ", $sformatf("Executing ADDI x%0d, x0, %0d (inst=0x%0h)", 
              rd, $signed(immediate), addi_inst), UVM_LOW)
    
    tr = riscv_transaction::type_id::create("tr");
    start_item(tr);
    tr.reset = 0;
    tr.I_Req = 0;
    tr.inst_data = addi_inst;
    tr.Rdata = 32'h0;
    finish_item(tr);
    
    // Wait for completion
    repeat(10) begin
      tr = riscv_transaction::type_id::create("tr");
      start_item(tr);
      tr.reset = 0;
      tr.I_Req = 0;
      finish_item(tr);
    end
  endtask
  
endclass

// ============================================================================
// LUI Instruction Sequence
// Test: LUI x10, 0x12345 (should write 0x12345000 to x10)
// ============================================================================

class lui_inst_sequence extends riscv_base_sequence;
  
  `uvm_object_utils(lui_inst_sequence)
  
  rand bit [19:0] immediate;
  rand bit [4:0]  rd;
  
  constraint c_rd { rd inside {[1:31]}; }
  
  function new(string name = "lui_inst_sequence");
    super.new(name);
  endfunction
  
  task body();
    riscv_transaction tr;
    bit [31:0] lui_inst;
    
    // Encode LUI rd, immediate
    // opcode = 0110111 (LUI)
    lui_inst = {immediate, rd, 7'b0110111};
    
    `uvm_info("SEQ", $sformatf("Executing LUI x%0d, 0x%0h (inst=0x%0h)", 
              rd, immediate, lui_inst), UVM_LOW)
    
    tr = riscv_transaction::type_id::create("tr");
    start_item(tr);
    tr.reset = 0;
    tr.I_Req = 0;
    tr.inst_data = lui_inst;
    tr.Rdata = 32'h0;
    finish_item(tr);
    
    // Wait for completion
    repeat(10) begin
      tr = riscv_transaction::type_id::create("tr");
      start_item(tr);
      tr.reset = 0;
      tr.I_Req = 0;
      finish_item(tr);
    end
  endtask
  
endclass

// ============================================================================
// Store-Load Sequence
// Test memory operations
// ============================================================================

class store_load_sequence extends riscv_base_sequence;
  
  `uvm_object_utils(store_load_sequence)
  
  function new(string name = "store_load_sequence");
    super.new(name);
  endfunction
  
  task body();
    riscv_transaction tr;
    bit [31:0] addi_inst, sw_inst, lw_inst;
    
    `uvm_info("SEQ", "Starting Store-Load sequence", UVM_LOW)
    
    // Step 1: ADDI x1, x0, 0x100 (load base address)
    addi_inst = {12'd256, 5'd0, 3'b000, 5'd1, 7'b0010011};
    
    tr = riscv_transaction::type_id::create("tr");
    start_item(tr);
    tr.reset = 0;
    tr.I_Req = 0;
    tr.inst_data = addi_inst;
    finish_item(tr);
      #50;
    
    // Step 2: ADDI x2, x0, 0xDEADBEEF & 0xFFF (load data lower)
    addi_inst = {12'hEEF, 5'd0, 3'b000, 5'd2, 7'b0010011};
    
    tr = riscv_transaction::type_id::create("tr");
    start_item(tr);
    tr.reset = 0;
    tr.I_Req = 0;
    tr.inst_data = addi_inst;
    finish_item(tr);
     #50;
    
    // Step 3: SW x2, 0(x1) - Store word
    // opcode = 0100011 (STORE)
    // imm[11:5]=0, rs2=2, rs1=1, funct3=010 (SW), imm[4:0]=0
    sw_inst = {7'b0000000, 5'd2, 5'd1, 3'b010, 5'b00000, 7'b0100011};
    
    tr = riscv_transaction::type_id::create("tr");
    start_item(tr);
    tr.reset = 0;
    tr.I_Req = 0;
    tr.inst_data = sw_inst;
    finish_item(tr);
    #50;
    
    // Step 4: LW x3, 0(x1) - Load word
    // opcode = 0000011 (LOAD)
    // imm[11:0]=0, rs1=1, funct3=010 (LW), rd=3
    lw_inst = {12'd0, 5'd1, 3'b010, 5'd3, 7'b0000011};
    
    tr = riscv_transaction::type_id::create("tr");
    start_item(tr);
    tr.reset = 0;
    tr.I_Req = 0;
    tr.inst_data = lw_inst;
    finish_item(tr);
   #50;
    
    `uvm_info("SEQ", "Store-Load sequence completed", UVM_LOW)
  endtask
  
endclass

// ============================================================================
// Random Instruction Sequence
// ============================================================================

class random_inst_sequence extends riscv_base_sequence;
  
  `uvm_object_utils(random_inst_sequence)
  
  rand int num_instructions;
  
  constraint c_num_inst {
    num_instructions inside {[10:100]};
  }
  
  function new(string name = "random_inst_sequence");
    super.new(name);
  endfunction
  
  task body();
    riscv_transaction tr;
    
    `uvm_info("SEQ", $sformatf("Generating %0d random instructions", num_instructions), UVM_LOW)
    
    repeat(num_instructions) begin
      tr = riscv_transaction::type_id::create("tr");
      start_item(tr);
      assert(tr.randomize());
      finish_item(tr);
    end
    
    // Wait for pipeline to flush
    repeat(10) begin
      tr = riscv_transaction::type_id::create("tr");
      start_item(tr);
      tr.reset = 0;
      tr.I_Req = 0;
      tr.inst_data = 32'h00000013; // NOP
      finish_item(tr);
    end
  endtask
  
endclass