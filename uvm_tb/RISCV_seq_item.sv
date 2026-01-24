class riscv_transaction extends uvm_sequence_item;
    
    // Input signals
    rand bit        reset;
    rand bit        I_Req;
    rand bit [31:0] inst_data;
     bit [31:0] Rdata;  // Data from memory for loads
    
    // Output signals (captured by monitor)
    bit [31:0] PC;
    bit [31:0] inst_addr;
    bit [31:0] Data_addr;
    bit [31:0] Wdata;
    bit [3:0]  we;
    bit [31:0] reg31;
    bit        IACK;
    
    // Instruction fields
    bit [6:0]  opcode;
    bit [4:0]  rd;
    bit [4:0]  rs1;
    bit [4:0]  rs2;
    bit [2:0]  funct3;
    bit [6:0]  funct7;
    bit [31:0] imm;
    
    // Tracking information
    bit        is_retired;
    bit [31:0] retired_pc;
    int        cycle_count;
    
    `uvm_object_utils_begin(riscv_transaction)
      `uvm_field_int(reset, UVM_ALL_ON)
      `uvm_field_int(I_Req, UVM_ALL_ON)
      `uvm_field_int(inst_data, UVM_ALL_ON)
      `uvm_field_int(Rdata, UVM_ALL_ON)
      `uvm_field_int(PC, UVM_ALL_ON)
      `uvm_field_int(inst_addr, UVM_ALL_ON)
      `uvm_field_int(Data_addr, UVM_ALL_ON)
      `uvm_field_int(Wdata, UVM_ALL_ON)
      `uvm_field_int(we, UVM_ALL_ON)
      `uvm_field_int(reg31, UVM_ALL_ON)
      `uvm_field_int(IACK, UVM_ALL_ON)
    `uvm_object_utils_end
    
    // Constraints for legal instructions
    constraint c_reset {
      reset dist {0 := 95, 1 := 5};
    }
    
    constraint c_interrupt {
      I_Req dist {0 := 90, 1 := 10};
    }
    
    constraint c_valid_opcode {
      inst_data[6:0] inside {
        OPCODE_LOAD,
        OPCODE_STORE,
        OPCODE_BRANCH,
        OPCODE_JALR,
        OPCODE_JAL,
        OPCODE_OP_IMM,
        OPCODE_OP,
        OPCODE_AUIPC,
        OPCODE_LUI
      };
    }
    
    constraint c_valid_funct3_alu {
      (inst_data[6:0] == OPCODE_OP || inst_data[6:0] == OPCODE_OP_IMM) ->
      inst_data[14:12] inside {[3'b000:3'b111]};
    }
    
    constraint c_valid_funct7 {
      (inst_data[6:0] == OPCODE_OP) ->
      inst_data[31:25] inside {7'b0000000, 7'b0100000, 7'b0000001};
    }
    
    constraint c_rd_not_zero_for_writes {
      (inst_data[6:0] inside {OPCODE_OP, OPCODE_OP_IMM, OPCODE_LOAD, 
                               OPCODE_JAL, OPCODE_JALR, OPCODE_LUI, OPCODE_AUIPC}) ->
      inst_data[11:7] inside {[1:31]};
    }
    
    constraint c_aligned_load_store {
      // Word accesses must be 4-byte aligned
      (inst_data[6:0] == OPCODE_LOAD && inst_data[14:12] == FUNCT3_LW) ->
      Rdata[1:0] == 2'b00;
      
      // Halfword accesses must be 2-byte aligned  
      (inst_data[6:0] == OPCODE_LOAD && inst_data[14:12] == FUNCT3_LH) ->
      Rdata[0] == 1'b0;
    }
    
    function new(string name = "riscv_transaction");
      super.new(name);
    endfunction
    
    function void post_randomize();
      decode_instruction();
    endfunction
    
    function void decode_instruction();
      opcode = inst_data[6:0];
      rd     = inst_data[11:7];
      funct3 = inst_data[14:12];
      rs1    = inst_data[19:15];
      rs2    = inst_data[24:20];
      funct7 = inst_data[31:25];
      
      // Decode immediate based on instruction type
      case(opcode)
        OPCODE_OP_IMM, OPCODE_LOAD, OPCODE_JALR: begin
          imm = {{20{inst_data[31]}}, inst_data[31:20]};
        end
        OPCODE_STORE: begin
          imm = {{20{inst_data[31]}}, inst_data[31:25], inst_data[11:7]};
        end
        OPCODE_BRANCH: begin
          imm = {{19{inst_data[31]}}, inst_data[31], inst_data[7], 
                 inst_data[30:25], inst_data[11:8], 1'b0};
        end
        OPCODE_JAL: begin
          imm = {{11{inst_data[31]}}, inst_data[31], inst_data[19:12], 
                 inst_data[20], inst_data[30:21], 1'b0};
        end
        OPCODE_LUI, OPCODE_AUIPC: begin
          imm = {inst_data[31:12], 12'b0};
        end
        default: imm = 32'h0;
      endcase
    endfunction
    
    // Helper function to get opcode name as string
    function string get_opcode_name();
      case(opcode)
        OPCODE_LOAD:    return "LOAD";
        OPCODE_STORE:   return "STORE";
        OPCODE_BRANCH:  return "BRANCH";
        OPCODE_JALR:    return "JALR";
        OPCODE_JAL:     return "JAL";
        OPCODE_OP_IMM:  return "OP_IMM";
        OPCODE_OP:      return "OP";
        OPCODE_AUIPC:   return "AUIPC";
        OPCODE_LUI:     return "LUI";
        default:        return "UNKNOWN";
      endcase
    endfunction
    
    function string convert2string();
      string s;
      // FIXED: Changed opcode.name() to get_opcode_name()
      s = $sformatf("PC=0x%0h, inst=0x%0h, opcode=%s, rd=%0d, rs1=%0d, rs2=%0d",
                    PC, inst_data, get_opcode_name(), rd, rs1, rs2);
      if(we != 0)
        s = {s, $sformatf(", MEM[0x%0h]=0x%0h, we=%b", Data_addr, Wdata, we)};
      return s;
    endfunction
    
endclass