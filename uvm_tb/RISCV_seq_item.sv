class RISCV_seq_item extends uvm_sequence_item;

  `uvm_object_utils(RISCV_seq_item)
  
  // Randomized inputs
  rand logic reset;
  rand logic I_Req;    
  randc logic[31:0] inst_data;
  
  // DUT outputs
  logic[31:0] Rdata;
  logic[31:0] inst_addr; 
  logic[31:0] Data_addr;
  logic[31:0] Wdata;
  logic [31:0] PC; 
  logic [31:0] reg31;
  
  
  constraint c_opcode { 
    inst_data[6:0] inside {
      7'b0110111,  // LUI    - Load Upper Immediate
      7'b0010111,  // AUIPC  - Add Upper Immediate to PC
      7'b1101111,  // JAL    - Jump and Link
      7'b1100111,  // JALR   - Jump and Link Register
      7'b1100011,  // BRANCH - BEQ, BNE, BLT, BGE, BLTU, BGEU
      7'b0000011,  // LOAD   - LB, LH, LW, LBU, LHU
      7'b0100011,  // STORE  - SB, SH, SW
      7'b0010011,  // I-TYPE - ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
      7'b0110011   // R-TYPE - ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
    };
  }
  

  constraint funct { 
    
    // R-TYPE INSTRUCTIONS (opcode = 0110011)
 
    (inst_data[6:0] == 7'b0110011) -> 
      (inst_data[31:25] inside {7'b0000000, 7'b0100000});  // ✓ RV32I function 7
    
    // When funct7 = 0100000, only SUB (000) and SRA (101) are valid
    (inst_data[6:0] == 7'b0110011 && inst_data[31:25] == 7'b0100000) -> 
      (inst_data[14:12] inside {3'b000, 3'b101});
    
 
    // LOAD INSTRUCTIONS (opcode = 0000011)
  
    // LB(000), LH(001), LW(010), LBU(100), LHU(101)

    (inst_data[6:0] == 7'b0000011) -> 
      ((inst_data[14:12] inside {3'b000, 3'b001, 3'b010, 3'b100, 3'b101}) && 
       (inst_data[31] == 0));  // Sign bit = 0 for valid immediates
    
    
    // BRANCH INSTRUCTIONS (opcode = 1100011)
    
    // BEQ(000), BNE(001), BLT(100), BGE(101), BLTU(110), BGEU(111)
    (inst_data[6:0] == 7'b1100011) -> 
      (inst_data[14:12] inside {3'b000, 3'b001, 3'b100, 3'b101, 3'b110, 3'b111});
    
    // JALR INSTRUCTION (opcode = 1100111)
    // Only funct3 = 000 is valid
  
    (inst_data[6:0] == 7'b1100111) -> 
      (inst_data[14:12] == 3'b000);
    
    // STORE INSTRUCTIONS (opcode = 0100011)
    
    // SB(000), SH(001), SW(010)
    (inst_data[6:0] == 7'b0100011) -> 
      (inst_data[14:12] inside {3'b000, 3'b001, 3'b010});
    
    // I-TYPE ALU INSTRUCTIONS (opcode = 0010011)
    // For shift instructions (SLLI, SRLI, SRAI), restrict funct7
    ((inst_data[6:0] == 7'b0010011) && (inst_data[13:12] == 2'b01)) -> 
      (inst_data[31:25] inside {7'b0000000, 7'b0100000});
  }
  
  
  // CONSTRAINT 3: Memory Alignment for Load Instructions
  constraint load_into_memory {
    // Halfword loads (LH, LHU) must be 2-byte aligned
    (inst_data[6:0] == 7'b0000011 && inst_data[14:12] inside {3'b001, 3'b101}) -> 
      (inst_data[8:7] inside {2'b00, 2'b10});
    
    // Word loads (LW) must be 4-byte aligned
    (inst_data[6:0] == 7'b0000011 && inst_data[14:12] == 3'b010) -> 
      (inst_data[8:7] == 2'b00);
  }
  
  function new(string name = "RISCV_seq_item");
    super.new(name);
    `uvm_info(get_type_name(), "Inside constructor of RISCV seq item Class", UVM_HIGH)
  endfunction : new
  
endclass : RISCV_seq_item