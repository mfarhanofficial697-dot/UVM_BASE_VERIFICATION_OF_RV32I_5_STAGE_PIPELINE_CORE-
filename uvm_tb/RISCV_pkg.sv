package riscv_verif_pkg;
  
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  
  // ============================================================================
  // Typedefs and Enums
  // ============================================================================
  
  typedef enum bit [6:0] {
    OPCODE_LOAD    = 7'b0000011,
    OPCODE_STORE   = 7'b0100011,
    OPCODE_BRANCH  = 7'b1100011,
    OPCODE_JALR    = 7'b1100111,
    OPCODE_JAL     = 7'b1101111,
    OPCODE_OP_IMM  = 7'b0010011,
    OPCODE_OP      = 7'b0110011,
    OPCODE_AUIPC   = 7'b0010111,
    OPCODE_LUI     = 7'b0110111
  } opcode_e;
  
  typedef enum bit [2:0] {
    FUNCT3_ADD_SUB = 3'b000,
    FUNCT3_SLL     = 3'b001,
    FUNCT3_SLT     = 3'b010,
    FUNCT3_SLTU    = 3'b011,
    FUNCT3_XOR     = 3'b100,
    FUNCT3_SRL_SRA = 3'b101,
    FUNCT3_OR      = 3'b110,
    FUNCT3_AND     = 3'b111
  } funct3_e;
  
  typedef enum bit [2:0] {
    FUNCT3_BEQ  = 3'b000,
    FUNCT3_BNE  = 3'b001,
    FUNCT3_BLT  = 3'b100,
    FUNCT3_BGE  = 3'b101,
    FUNCT3_BLTU = 3'b110,
    FUNCT3_BGEU = 3'b111
  } branch_funct3_e;
  
  typedef enum bit [2:0] {
    FUNCT3_LB  = 3'b000,
    FUNCT3_LH  = 3'b001,
    FUNCT3_LW  = 3'b010,
    FUNCT3_LBU = 3'b100,
    FUNCT3_LHU = 3'b101
  } load_funct3_e;
  
  typedef enum bit [2:0] {
    FUNCT3_SB = 3'b000,
    FUNCT3_SH = 3'b001,
    FUNCT3_SW = 3'b010
  } store_funct3_e;
  
  // ============================================================================
  // Include files in proper order
  // ============================================================================
  
  // 1. FIRST: Transaction class (sequence item) - needed by everything
  `include "RISCV_seq_item.sv"
  
  // 2. SECOND: Reference models - they use riscv_transaction
  `include "mem_ref_model.sv" 

  
  // 3. THIRD: Sequence and sequencer
  `include "Sequence.sv"
  `include "Sequencer.sv"   
  
  // 4. FOURTH: Driver and Monitor - they use riscv_transaction
  `include "Driver.sv"  
  `include "Monitor.sv"
  
  // 5. FIFTH: Coverage and Scoreboard - they use riscv_transaction
  `include "Coverage_collector.sv"
  `include "Scoreboard.sv"   
  
  // 6. SIXTH: Agent - uses driver, monitor, sequencer
  `include "Agent.sv" 
  
  // 7. SEVENTH: Environment - uses agent, scoreboard, coverage
  `include "Environment.sv"  
  
  // 8. LAST: Test - uses environment
  `include "RISCV_Test.sv"

endpackage : riscv_verif_pkg