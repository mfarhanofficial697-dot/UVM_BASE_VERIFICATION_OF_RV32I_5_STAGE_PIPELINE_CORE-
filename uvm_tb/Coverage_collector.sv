// Coverage collector extends uvm_subscriber so it can receive transactions
class Coverage_collector extends uvm_subscriber #(RISCV_seq_item);

  // Register this component with the factory
  `uvm_component_utils(Coverage_collector)
  
  // Local copy of the incoming transaction
  RISCV_seq_item item;

  // Covergroup to record instruction coverage
  covergroup instructions_cover;
        option.per_instance = 1; // Each instance keeps separate coverage

        // -----------------------------
        // R-Type Instruction Coverage
        // opcode = 0110011
        // funct3 identifies instruction group
        // funct7 further differentiates ADD/SUB, SRL/SRA
        // -----------------------------
        R_Type: coverpoint item.inst_data[14:12] 
        iff( !item.reset & item.inst_data[6:0]==7'b0110011 )
        {
          bins ADD = {3'b000} iff(item.inst_data[31:25]==7'b0000000);  // ADD
          bins SUB = {3'b000} iff(item.inst_data[31:25]==7'b0100000);  // SUB
          bins SLL = {3'b001};
          bins SLT = {3'b010};
          bins SLTU = {3'b011};
          bins XOR = {3'b100};
          bins SRL = {3'b101} iff(item.inst_data[31:25]==7'b0000000);  // SRL
          bins SRA = {3'b101} iff(item.inst_data[31:25]==7'b0100000);  // SRA
          bins OR  = {3'b110};
          bins AND = {3'b111};
        }

        // -----------------------------
        // I-Type Instruction Coverage
        // Includes: Load, Immediate ALU, and JALR
        // -----------------------------
        I_Type: coverpoint item.inst_data[14:12] 
        iff( !item.reset & 
             (item.inst_data[6:0]==7'b0000011 || 
              item.inst_data[6:0]==7'b0010011 || 
              item.inst_data[6:0]==7'b1100111))
        {
          // Load instructions
          bins LB  = {3'b000} iff(item.inst_data[31:25]==7'b0000000);
          bins LH  = {3'b001} iff(item.inst_data[31:25]==7'b0100000);
          bins LW  = {3'b010};
          bins LBU = {3'b100};
          bins LHU = {3'b101};

          // Immediate ALU instructions
          bins ADDI  = {3'b000} iff(item.inst_data[6:0]==7'b0010011);
          bins SLLI  = {3'b001} iff(item.inst_data[31:25]==7'b0000000 && item.inst_data[6:0]==7'b0010011);
          bins SLTI  = {3'b010} iff(item.inst_data[6:0]==7'b0010011);
          bins SLTIU = {3'b011} iff(item.inst_data[6:0]==7'b0010011);
          bins XORI  = {3'b100} iff(item.inst_data[6:0]==7'b0010011);
          bins SRLI  = {3'b101} iff(item.inst_data[31:25]==7'b0000000 && item.inst_data[6:0]==7'b0010011);
          bins SRAI  = {3'b101} iff(item.inst_data[31:25]==7'b0100000 && item.inst_data[6:0]==7'b0010011);
          bins ORI   = {3'b110} iff(item.inst_data[6:0]==7'b0010011);
          bins ANDI  = {3'b111} iff(item.inst_data[6:0]==7'b0010011);

          // JALR instruction
          bins jalr = {3'b000} iff(item.inst_data[6:0]==7'b1100111);
        }

        // -----------------------------
        // S-Type: Store Instructions
        // opcode = 0100011
        // -----------------------------
        S_Type: coverpoint item.inst_data[14:12] 
        iff( !item.reset & (item.inst_data[6:0]==7'b0100011))
        {
          bins SB = {3'b000}; // store byte
          bins SH = {3'b001}; // store halfword
          bins SW = {3'b010}; // store word
        }

        // -----------------------------
        // B-Type: Branch instructions
        // opcode = 1100011
        // funct3 decides branch type
        // -----------------------------
        B_Type: coverpoint item.inst_data[14:12]
        iff( !item.reset & (item.inst_data[6:0]==7'b1100011))
        {
          bins BEQ  = {3'b000};
          bins BNQ  = {3'b001};
          bins BLT  = {3'b100};
          bins BGE  = {3'b101};
          bins BLTU = {3'b110};
          bins BGEU = {3'b111};
        }

        // -----------------------------
        // J-Type: Jump (JAL)
        // opcode = 1101111
        // funct3 is unused, so wildcard bins
        // -----------------------------
        J_Type: coverpoint item.inst_data[14:12]
        iff( !item.reset & (item.inst_data[6:0]==7'b1101111))
        {
          wildcard bins JAL = {3'b???};
        }

        // -----------------------------
        // U-Type: LUI & AUIPC
        // funct3 unused → wildcard bins
        // -----------------------------
        U_Type: coverpoint item.inst_data[14:12]
        iff( !item.reset & 
             (item.inst_data[6:0]==7'b0110111 || item.inst_data[6:0]==7'b0010111))
        {
          wildcard bins AUIPC = {3'b???} iff(item.inst_data[6:0]==7'b0010111);
          wildcard bins LUI   = {3'b???} iff(item.inst_data[6:0]==7'b0110111);
        }
  endgroup : instructions_cover

  // Constructor: create the covergroup
  function new(string name = "Coverage_collector", uvm_component parent);
    super.new(name,parent);
    instructions_cover = new();  // initialize covergroup
  endfunction : new

  // build phase: normally components would be created here
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction : build_phase

  // connect phase: normally used to connect ports
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction : connect_phase

  // run phase: not needed for coverage, just included for completeness
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
  endtask : run_phase

  // write() is called whenever monitor publishes a transaction
  function void write(RISCV_seq_item t);
      item = RISCV_seq_item::type_id::create("item"); // create local item
      $cast(item, t);                                 // copy transaction
      instructions_cover.sample();                    // update coverage
  endfunction : write
  
endclass : Coverage_collector
