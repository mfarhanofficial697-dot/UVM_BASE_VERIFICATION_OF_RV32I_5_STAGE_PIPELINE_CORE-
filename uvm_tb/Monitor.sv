// ============================================================================
// RISC-V CPU Monitor
// ============================================================================

class riscv_monitor extends uvm_monitor;
  
  `uvm_component_utils(riscv_monitor)
  
  virtual riscv_if vif;
  
  uvm_analysis_port #(riscv_transaction) analysis_port;
  
  // Pipeline tracking
  bit [31:0] pipeline_pc[5];      // PC of instruction in each stage
  bit [31:0] pipeline_inst[5];    // Instruction in each stage
  bit        pipeline_valid[5];   // Valid bit for each stage
  
  // Instruction tracking for retirement
  bit [31:0] if_pc, id_pc, ex_pc, mem_pc, wb_pc;
  bit [31:0] if_inst, id_inst, ex_inst, mem_inst, wb_inst;
  bit        if_valid, id_valid, ex_valid, mem_valid, wb_valid;
  
  int cycle_count;
  
  function new(string name = "riscv_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_port = new("analysis_port", this);
    if(!uvm_config_db#(virtual riscv_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set for monitor")
  endfunction
  
  task run_phase(uvm_phase phase);
    cycle_count = 0;
    
    // Wait for reset to deassert
    @(negedge vif.reset);
    @(posedge vif.clk);
    
    fork
      monitor_pipeline();
      monitor_retirement();
    join_none
    
  endtask
  
  // Monitor pipeline progression
  task monitor_pipeline();
    forever begin
      @(posedge vif.clk);
      cycle_count++;
      
      // Track instruction fetch
      if(!vif.reset) begin
        if_pc = vif.PC;
        if_inst = vif.inst_data;
        if_valid = 1'b1;
        
        `uvm_info("MONITOR_IF", $sformatf("Cycle %0d: IF stage - PC=0x%0h, inst=0x%0h", 
                  cycle_count, if_pc, if_inst), UVM_HIGH)
      end else begin
        if_valid = 1'b0;
      end
    end
  endtask
  
  // Monitor instruction retirement at WB stage
  // Instructions retire when they complete the WB stage
  task monitor_retirement();
    // DECLARE ALL VARIABLES AT THE TOP OF THE TASK
    riscv_transaction tr;
    bit [31:0] prev_pc;
    bit [31:0] prev_inst;
    int wb_delay;
    bit retired;  // MOVED HERE FROM LINE 118
    
    wb_delay = 5; // 5 cycles for instruction to reach WB
    
    forever begin
      @(posedge vif.clk);
      
      if(vif.reset) begin
        prev_pc = 32'h0;
        prev_inst = 32'h0;
        continue;
      end
      
      // After pipeline fills (5 cycles), start checking for retirement
      if(cycle_count >= wb_delay) begin
        
        tr = riscv_transaction::type_id::create("tr");
        
        // Capture current state
        tr.PC = vif.PC;
        tr.inst_addr = vif.inst_addr;
        tr.inst_data = vif.inst_data;
        tr.Data_addr = vif.Data_addr;
        tr.Wdata = vif.Wdata;
        tr.we = vif.we;
        tr.reg31 = vif.reg31;
        tr.IACK = vif.IACK;
        tr.Rdata = vif.Rdata;
        tr.I_Req = vif.I_Req;
        tr.reset = vif.reset;
        tr.cycle_count = cycle_count;
        
        // Decode instruction
        tr.decode_instruction();
        
        // Check for instruction retirement
        // An instruction retires when:
        // 1. Register write occurs (regwrite signal would be high in WB)
        // 2. Memory write occurs (we != 0)
        // 3. Branch/Jump completes
        // 4. Or simply pipeline advances without stall
        
        retired = 1'b0;  // NOW THIS IS JUST AN ASSIGNMENT
        
        // Check for register writes (most instructions)
        if(tr.opcode inside {OPCODE_OP, OPCODE_OP_IMM, OPCODE_LOAD, 
                              OPCODE_JAL, OPCODE_JALR, OPCODE_LUI, OPCODE_AUIPC}) begin
          if(tr.rd != 0) begin // Writing to non-zero register
            retired = 1'b1;
            `uvm_info("RETIRE", $sformatf("Cycle %0d: Instruction retired - %s", 
                      cycle_count, tr.convert2string()), UVM_MEDIUM)
          end
        end
        
        // Check for memory writes (stores)
        if(tr.we != 4'b0000) begin
          retired = 1'b1;
          `uvm_info("RETIRE", $sformatf("Cycle %0d: Store retired - %s", 
                    cycle_count, tr.convert2string()), UVM_MEDIUM)
        end
        
        // Check for branches (they don't write registers but still retire)
        if(tr.opcode == OPCODE_BRANCH) begin
          retired = 1'b1;
          `uvm_info("RETIRE", $sformatf("Cycle %0d: Branch retired - %s", 
                    cycle_count, tr.convert2string()), UVM_MEDIUM)
        end
        
        tr.is_retired = retired;
        
        // Send transaction to scoreboard regardless of retirement
        // Scoreboard will filter based on is_retired flag
        analysis_port.write(tr);
        
        // Track memory operations
        if(tr.we != 4'b0000) begin
          `uvm_info("MEM_WRITE", $sformatf("Cycle %0d: MEM[0x%0h] = 0x%0h, we=%b", 
                    cycle_count, tr.Data_addr, tr.Wdata, tr.we), UVM_MEDIUM)
        end
        
        prev_pc = tr.PC;
        prev_inst = tr.inst_data;
      end
    end
  endtask
  
endclass