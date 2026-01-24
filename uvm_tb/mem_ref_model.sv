// ============================================================================
// Reference Transaction Class
// ============================================================================
class ref_transaction extends uvm_object;
  `uvm_object_utils(ref_transaction)
  
  bit [31:0] reg_file[32];
  bit [31:0] pc;
  bit [31:0] next_pc;
  bit        reg_write;
  bit [4:0]  reg_wr_addr;
  bit [31:0] reg_wr_data;
  bit [3:0]  mem_we;
  bit [31:0] mem_addr;
  bit [31:0] mem_data;
  
  function new(string name = "ref_transaction");
    super.new(name);
  endfunction
endclass

// ============================================================================
// RISC-V Reference Model (Golden Model)
// ============================================================================
class riscv_ref_model extends uvm_component;
  
  `uvm_component_utils(riscv_ref_model)
  
  // Register file
  bit [31:0] reg_file[32];
  
  // Memory
  bit [31:0] data_mem[bit[31:0]];
  
  // PC
  bit [31:0] pc;
  
  function new(string name = "riscv_ref_model", uvm_component parent = null);
    super.new(name, parent);
    reset_model();
  endfunction
  
  function void reset_model();
    for(int i = 0; i < 32; i++) begin
      reg_file[i] = 32'h0;
    end
    pc = 32'h0;
    data_mem.delete();
  endfunction
  
  // Execute instruction and return expected results
  function ref_transaction execute(riscv_transaction tr);
    // Declare ALL variables at the beginning of the function
    ref_transaction ref_tr;
    bit [31:0] rs1_val, rs2_val;
    bit [31:0] alu_result;
    bit [31:0] mem_addr;
    bit [31:0] next_pc;
    bit        branch_taken;
    bit [31:0] mem_data;
    bit [1:0]  byte_offset;
    bit [31:0] current_mem;
    
    ref_tr = ref_transaction::type_id::create("ref_tr");
    
    // Copy current register file state
    foreach(reg_file[i]) ref_tr.reg_file[i] = reg_file[i];
    
    ref_tr.pc = pc;
    ref_tr.reg_write = 0;
    ref_tr.mem_we = 4'b0000;
    
    // Read source registers
    rs1_val = (tr.rs1 == 0) ? 32'h0 : reg_file[tr.rs1];
    rs2_val = (tr.rs2 == 0) ? 32'h0 : reg_file[tr.rs2];
    
    // Decode and execute based on opcode
    case(tr.opcode)
      
      // ========================================
      // R-Type Instructions
      // ========================================
      OPCODE_OP: begin
        case(tr.funct3)
          FUNCT3_ADD_SUB: begin
            if(tr.funct7 == 7'b0000000) // ADD
              alu_result = rs1_val + rs2_val;
            else if(tr.funct7 == 7'b0100000) // SUB
              alu_result = rs1_val - rs2_val;
            else if(tr.funct7 == 7'b0000001) // MUL
              alu_result = rs1_val * rs2_val;
          end
          FUNCT3_SLL: alu_result = rs1_val << rs2_val[4:0];
          FUNCT3_SLT: alu_result = ($signed(rs1_val) < $signed(rs2_val)) ? 32'h1 : 32'h0;
          FUNCT3_SLTU: alu_result = (rs1_val < rs2_val) ? 32'h1 : 32'h0;
          FUNCT3_XOR: alu_result = rs1_val ^ rs2_val;
          FUNCT3_SRL_SRA: begin
            if(tr.funct7 == 7'b0000000) // SRL
              alu_result = rs1_val >> rs2_val[4:0];
            else // SRA
              alu_result = $signed(rs1_val) >>> rs2_val[4:0];
          end
          FUNCT3_OR: alu_result = rs1_val | rs2_val;
          FUNCT3_AND: alu_result = rs1_val & rs2_val;
        endcase
        
        if(tr.rd != 0) begin
          reg_file[tr.rd] = alu_result;
          ref_tr.reg_write = 1;
          ref_tr.reg_wr_addr = tr.rd;
          ref_tr.reg_wr_data = alu_result;
        end
        next_pc = pc + 4;
      end
      
      // ========================================
      // I-Type Instructions (ALU with immediate)
      // ========================================
      OPCODE_OP_IMM: begin
        case(tr.funct3)
          FUNCT3_ADD_SUB: alu_result = rs1_val + tr.imm; // ADDI
          FUNCT3_SLL: alu_result = rs1_val << tr.imm[4:0]; // SLLI
          FUNCT3_SLT: alu_result = ($signed(rs1_val) < $signed(tr.imm)) ? 32'h1 : 32'h0; // SLTI
          FUNCT3_SLTU: alu_result = (rs1_val < tr.imm) ? 32'h1 : 32'h0; // SLTIU
          FUNCT3_XOR: alu_result = rs1_val ^ tr.imm; // XORI
          FUNCT3_SRL_SRA: begin
            if(tr.funct7 == 7'b0000000) // SRLI
              alu_result = rs1_val >> tr.imm[4:0];
            else // SRAI
              alu_result = $signed(rs1_val) >>> tr.imm[4:0];
          end
          FUNCT3_OR: alu_result = rs1_val | tr.imm; // ORI
          FUNCT3_AND: alu_result = rs1_val & tr.imm; // ANDI
        endcase
        
        if(tr.rd != 0) begin
          reg_file[tr.rd] = alu_result;
          ref_tr.reg_write = 1;
          ref_tr.reg_wr_addr = tr.rd;
          ref_tr.reg_wr_data = alu_result;
        end
        next_pc = pc + 4;
      end
      
      // ========================================
      // Load Instructions
      // ========================================
      OPCODE_LOAD: begin
        mem_addr = rs1_val + tr.imm;
        mem_data = data_mem.exists(mem_addr) ? data_mem[mem_addr] : 32'h0;
        byte_offset = mem_addr[1:0];
        
        case(tr.funct3)
          FUNCT3_LB: begin // Load byte (sign-extended)
            alu_result = {{24{mem_data[7+byte_offset*8]}}, mem_data[byte_offset*8 +: 8]};
          end
          FUNCT3_LH: begin // Load halfword (sign-extended)
            alu_result = {{16{mem_data[15+byte_offset*8]}}, mem_data[byte_offset*8 +: 16]};
          end
          FUNCT3_LW: begin // Load word
            alu_result = mem_data;
          end
          FUNCT3_LBU: begin // Load byte unsigned
            alu_result = {24'h0, mem_data[byte_offset*8 +: 8]};
          end
          FUNCT3_LHU: begin // Load halfword unsigned
            alu_result = {16'h0, mem_data[byte_offset*8 +: 16]};
          end
        endcase
        
        if(tr.rd != 0) begin
          reg_file[tr.rd] = alu_result;
          ref_tr.reg_write = 1;
          ref_tr.reg_wr_addr = tr.rd;
          ref_tr.reg_wr_data = alu_result;
        end
        next_pc = pc + 4;
      end
      
      // ========================================
      // Store Instructions
      // ========================================
      OPCODE_STORE: begin
        mem_addr = rs1_val + tr.imm;
        current_mem = data_mem.exists(mem_addr) ? data_mem[mem_addr] : 32'h0;
        byte_offset = mem_addr[1:0];
        
        case(tr.funct3)
          FUNCT3_SB: begin // Store byte
            ref_tr.mem_we = 4'b0001 << byte_offset;
            current_mem[byte_offset*8 +: 8] = rs2_val[7:0];
          end
          FUNCT3_SH: begin // Store halfword
            ref_tr.mem_we = 4'b0011 << byte_offset;
            current_mem[byte_offset*8 +: 16] = rs2_val[15:0];
          end
          FUNCT3_SW: begin // Store word
            ref_tr.mem_we = 4'b1111;
            current_mem = rs2_val;
          end
        endcase
        
        data_mem[mem_addr] = current_mem;
        ref_tr.mem_addr = mem_addr;
        ref_tr.mem_data = rs2_val << (byte_offset * 8);
        next_pc = pc + 4;
      end
      
      // ========================================
      // Branch Instructions
      // ========================================
      OPCODE_BRANCH: begin
        case(tr.funct3)
          FUNCT3_BEQ: branch_taken = (rs1_val == rs2_val);
          FUNCT3_BNE: branch_taken = (rs1_val != rs2_val);
          FUNCT3_BLT: branch_taken = ($signed(rs1_val) < $signed(rs2_val));
          FUNCT3_BGE: branch_taken = ($signed(rs1_val) >= $signed(rs2_val));
          FUNCT3_BLTU: branch_taken = (rs1_val < rs2_val);
          FUNCT3_BGEU: branch_taken = (rs1_val >= rs2_val);
        endcase
        
        next_pc = branch_taken ? (pc + tr.imm) : (pc + 4);
      end
      
      // ========================================
      // JAL - Jump and Link
      // ========================================
      OPCODE_JAL: begin
        if(tr.rd != 0) begin
          reg_file[tr.rd] = pc + 4;
          ref_tr.reg_write = 1;
          ref_tr.reg_wr_addr = tr.rd;
          ref_tr.reg_wr_data = pc + 4;
        end
        next_pc = pc + tr.imm;
      end
      
      // ========================================
      // JALR - Jump and Link Register
      // ========================================
      OPCODE_JALR: begin
        if(tr.rd != 0) begin
          reg_file[tr.rd] = pc + 4;
          ref_tr.reg_write = 1;
          ref_tr.reg_wr_addr = tr.rd;
          ref_tr.reg_wr_data = pc + 4;
        end
        next_pc = (rs1_val + tr.imm) & ~32'h1; // Clear LSB
      end
      
      // ========================================
      // LUI - Load Upper Immediate
      // ========================================
      OPCODE_LUI: begin
        if(tr.rd != 0) begin
          reg_file[tr.rd] = tr.imm;
          ref_tr.reg_write = 1;
          ref_tr.reg_wr_addr = tr.rd;
          ref_tr.reg_wr_data = tr.imm;
        end
        next_pc = pc + 4;
      end
      
      // ========================================
      // AUIPC - Add Upper Immediate to PC
      // ========================================
      OPCODE_AUIPC: begin
        if(tr.rd != 0) begin
          reg_file[tr.rd] = pc + tr.imm;
          ref_tr.reg_write = 1;
          ref_tr.reg_wr_addr = tr.rd;
          ref_tr.reg_wr_data = pc + tr.imm;
        end
        next_pc = pc + 4;
      end
      
      default: begin
        `uvm_warning("REF_MODEL", $sformatf("Unknown opcode: 0x%0h", tr.opcode))
        next_pc = pc + 4;
      end
    endcase
    
    // Update PC
    pc = next_pc;
    ref_tr.next_pc = next_pc;
    
    // Keep x0 as zero
    reg_file[0] = 32'h0;
    
    return ref_tr;
  endfunction
  
  // Function to set memory for reference model
  function void set_mem(bit[31:0] addr, bit[31:0] data);
    data_mem[addr] = data;
  endfunction
  
  // Function to get memory value
  function bit[31:0] get_mem(bit[31:0] addr);
    return data_mem.exists(addr) ? data_mem[addr] : 32'h0;
  endfunction
  
endclass