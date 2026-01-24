// ============================================================================
// RISC-V CPU Coverage Collector
// ============================================================================

class riscv_coverage extends uvm_subscriber #(riscv_transaction);
  
  `uvm_component_utils(riscv_coverage)
  
  riscv_transaction tr;
  
  // ========================================
  // Coverage Groups
  // ========================================
  
  // Instruction Opcode Coverage
  covergroup cg_opcode;
    cp_opcode: coverpoint tr.opcode {
      bins load    = {OPCODE_LOAD};
      bins store   = {OPCODE_STORE};
      bins branch  = {OPCODE_BRANCH};
      bins jalr    = {OPCODE_JALR};
      bins jal     = {OPCODE_JAL};
      bins op_imm  = {OPCODE_OP_IMM};
      bins op      = {OPCODE_OP};
      bins auipc   = {OPCODE_AUIPC};
      bins lui     = {OPCODE_LUI};
    }
  endgroup
  
  // ALU Operations Coverage
  covergroup cg_alu_ops;
    cp_funct3: coverpoint tr.funct3 {
      bins add_sub = {FUNCT3_ADD_SUB};
      bins sll     = {FUNCT3_SLL};
      bins slt     = {FUNCT3_SLT};
      bins sltu    = {FUNCT3_SLTU};
      bins xor_op  = {FUNCT3_XOR};
      bins srl_sra = {FUNCT3_SRL_SRA};
      bins or_op   = {FUNCT3_OR};
      bins and_op  = {FUNCT3_AND};
    }
    
    cp_funct7: coverpoint tr.funct7 {
      bins normal   = {7'b0000000};
      bins sub_sra  = {7'b0100000};
      bins mul_div  = {7'b0000001};
    }
    
    cp_alu_ops: cross cp_funct3, cp_funct7 {
      ignore_bins non_alu = binsof(cp_funct3) intersect {FUNCT3_ADD_SUB, FUNCT3_SRL_SRA} &&
                                   binsof(cp_funct7) intersect {7'b0000001};
    }
  endgroup
  
  // Branch Coverage
  covergroup cg_branch;
    cp_branch_type: coverpoint tr.funct3 {
      bins beq  = {FUNCT3_BEQ};
      bins bne  = {FUNCT3_BNE};
      bins blt  = {FUNCT3_BLT};
      bins bge  = {FUNCT3_BGE};
      bins bltu = {FUNCT3_BLTU};
      bins bgeu = {FUNCT3_BGEU};
    }
    
    // Branch taken/not taken - would need additional signal from DUT
    // For now, we track all branch instructions
  endgroup
  
  // Load/Store Width Coverage
  covergroup cg_mem_access;
    cp_load_width: coverpoint tr.funct3 {
      bins lb  = {FUNCT3_LB};
      bins lh  = {FUNCT3_LH};
      bins lw  = {FUNCT3_LW};
      bins lbu = {FUNCT3_LBU};
      bins lhu = {FUNCT3_LHU};
    }
    
    cp_store_width: coverpoint tr.funct3 {
      bins sb = {FUNCT3_SB};
      bins sh = {FUNCT3_SH};
      bins sw = {FUNCT3_SW};
    }
    
    cp_mem_alignment: coverpoint tr.Data_addr[1:0] {
      bins aligned_word = {2'b00};
      bins aligned_half = {2'b10};
      bins byte_0       = {2'b00};
      bins byte_1       = {2'b01};
      bins byte_2       = {2'b10};
      bins byte_3       = {2'b11};
    }
  endgroup
  
  // Register Usage Coverage
  covergroup cg_registers;
    cp_rd: coverpoint tr.rd {
      bins zero    = {0};
      bins reg1_7  = {[1:7]};
      bins reg8_15 = {[8:15]};
      bins reg16_23 = {[16:23]};
      bins reg24_31 = {[24:31]};
    }
    
    cp_rs1: coverpoint tr.rs1 {
      bins zero    = {0};
      bins reg1_7  = {[1:7]};
      bins reg8_15 = {[8:15]};
      bins reg16_23 = {[16:23]};
      bins reg24_31 = {[24:31]};
    }
    
    cp_rs2: coverpoint tr.rs2 {
      bins zero    = {0};
      bins reg1_7  = {[1:7]};
      bins reg8_15 = {[8:15]};
      bins reg16_23 = {[16:23]};
      bins reg24_31 = {[24:31]};
    }
  endgroup
  
  // Hazard Scenarios Coverage
  covergroup cg_hazards;
    cp_we: coverpoint tr.we {
      bins no_write    = {4'b0000};
      bins byte_write  = {4'b0001, 4'b0010, 4'b0100, 4'b1000};
      bins half_write  = {4'b0011, 4'b1100};
      bins word_write  = {4'b1111};
    }
  endgroup
  
  // Interrupt Coverage
  covergroup cg_interrupt;
    cp_i_req: coverpoint tr.I_Req {
      bins no_interrupt = {0};
      bins interrupt    = {1};
    }
    
    cp_iack: coverpoint tr.IACK {
      bins no_ack = {0};
      bins ack    = {1};
    }
    
    cp_interrupt_flow: cross cp_i_req, cp_iack;
  endgroup
  
  // PC Coverage
  covergroup cg_pc;
    cp_pc_range: coverpoint tr.PC {
      bins low     = {[32'h00000000:32'h000000FF]};
      bins mid     = {[32'h00000100:32'h00000FFF]};
      bins high    = {[32'h00001000:32'hFFFFFFFF]};
    }
  endgroup
  
  // Instruction Mix Coverage
  covergroup cg_inst_mix;
    cp_inst_type: coverpoint tr.opcode {
      bins alu       = {OPCODE_OP, OPCODE_OP_IMM};
      bins memory    = {OPCODE_LOAD, OPCODE_STORE};
      bins control   = {OPCODE_BRANCH, OPCODE_JAL, OPCODE_JALR};
      bins immediate = {OPCODE_LUI, OPCODE_AUIPC};
    }
  endgroup
  
  function new(string name = "riscv_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_opcode = new();
    cg_alu_ops = new();
    cg_branch = new();
    cg_mem_access = new();
    cg_registers = new();
    cg_hazards = new();
    cg_interrupt = new();
    cg_pc = new();
    cg_inst_mix = new();
  endfunction
  
  function void write(riscv_transaction t);
    tr = t;
    
    // Sample all coverage groups
    cg_opcode.sample();
    cg_inst_mix.sample();
    cg_registers.sample();
    cg_hazards.sample();
    cg_interrupt.sample();
    cg_pc.sample();
    
    // Sample opcode-specific coverage
    case(tr.opcode)
      OPCODE_OP, OPCODE_OP_IMM: begin
        cg_alu_ops.sample();
      end
      OPCODE_BRANCH: begin
        cg_branch.sample();
      end
      OPCODE_LOAD, OPCODE_STORE: begin
        cg_mem_access.sample();
      end
    endcase
    
  endfunction
  
  function void report_phase(uvm_phase phase);
    real coverage_percent;
    
    super.report_phase(phase);
    
    `uvm_info("COVERAGE_REPORT", "========================================", UVM_LOW)
    `uvm_info("COVERAGE_REPORT", "      COVERAGE SUMMARY", UVM_LOW)
    `uvm_info("COVERAGE_REPORT", "========================================", UVM_LOW)
    
    coverage_percent = cg_opcode.get_coverage();
    `uvm_info("COVERAGE_REPORT", $sformatf("Opcode Coverage: %0.2f%%", coverage_percent), UVM_LOW)
    
    coverage_percent = cg_alu_ops.get_coverage();
    `uvm_info("COVERAGE_REPORT", $sformatf("ALU Operations Coverage: %0.2f%%", coverage_percent), UVM_LOW)
    
    coverage_percent = cg_branch.get_coverage();
    `uvm_info("COVERAGE_REPORT", $sformatf("Branch Coverage: %0.2f%%", coverage_percent), UVM_LOW)
    
    coverage_percent = cg_mem_access.get_coverage();
    `uvm_info("COVERAGE_REPORT", $sformatf("Memory Access Coverage: %0.2f%%", coverage_percent), UVM_LOW)
    
    coverage_percent = cg_registers.get_coverage();
    `uvm_info("COVERAGE_REPORT", $sformatf("Register Usage Coverage: %0.2f%%", coverage_percent), UVM_LOW)
    
    coverage_percent = cg_hazards.get_coverage();
    `uvm_info("COVERAGE_REPORT", $sformatf("Hazard Scenarios Coverage: %0.2f%%", coverage_percent), UVM_LOW)
    
    coverage_percent = cg_interrupt.get_coverage();
    `uvm_info("COVERAGE_REPORT", $sformatf("Interrupt Coverage: %0.2f%%", coverage_percent), UVM_LOW)
    
    coverage_percent = $get_coverage();
    `uvm_info("COVERAGE_REPORT", "========================================", UVM_LOW)
    `uvm_info("COVERAGE_REPORT", $sformatf("TOTAL COVERAGE: %0.2f%%", coverage_percent), UVM_LOW)
    `uvm_info("COVERAGE_REPORT", "========================================", UVM_LOW)
  endfunction
  
endclass