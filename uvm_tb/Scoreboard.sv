// ============================================================================
// RISC-V CPU Scoreboard
// ============================================================================

class riscv_scoreboard extends uvm_scoreboard;
  
  `uvm_component_utils(riscv_scoreboard)
  
  uvm_analysis_imp #(riscv_transaction, riscv_scoreboard) analysis_export;
  
  riscv_ref_model ref_model;
  
  // Queues for tracking instructions through pipeline
  riscv_transaction inst_queue[$];
  riscv_transaction retired_queue[$];
  
  // Statistics
  int total_instructions;
  int retired_instructions;
  int passed_instructions;
  int failed_instructions;
  int mem_write_count;
  int mem_read_count;
  int branch_count;
  int jump_count;
  
  // Error tracking
  int reg_mismatches;
  int mem_mismatches;
  int pc_mismatches;
  
  function new(string name = "riscv_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_export = new("analysis_export", this);
    ref_model = riscv_ref_model::type_id::create("ref_model", this);
  endfunction
  
  function void write(riscv_transaction tr);
    ref_transaction ref_tr;
    bit check_passed;
    
    total_instructions++;
    
    // Only check retired instructions
    if(!tr.is_retired) return;
    
    retired_instructions++;
    
    `uvm_info("SCOREBOARD", $sformatf("Checking retired instruction #%0d at cycle %0d", 
              retired_instructions, tr.cycle_count), UVM_MEDIUM)
    
    // Execute instruction in reference model
    ref_tr = ref_model.execute(tr);
    
    check_passed = 1'b1;
    
    // ========================================
    // Check Register Writes
    // ========================================
    if(ref_tr.reg_write) begin
      bit [31:0] expected_val = ref_tr.reg_wr_data;
      bit [31:0] actual_val;
      
      // For register 31, we can check directly from DUT output
      if(ref_tr.reg_wr_addr == 31) begin
        actual_val = tr.reg31;
        
        if(actual_val !== expected_val) begin
          `uvm_error("REG_MISMATCH", 
            $sformatf("Register x%0d mismatch at cycle %0d\n  Instruction: 0x%0h at PC=0x%0h\n  Expected: 0x%0h\n  Got: 0x%0h",
            ref_tr.reg_wr_addr, tr.cycle_count, tr.inst_data, tr.PC, expected_val, actual_val))
          reg_mismatches++;
          check_passed = 1'b0;
        end else begin
          `uvm_info("REG_CHECK", 
            $sformatf("Register x%0d write OK: 0x%0h", ref_tr.reg_wr_addr, actual_val), UVM_HIGH)
        end
      end
    end
    
    // ========================================
    // Check Memory Writes
    // ========================================
    if(ref_tr.mem_we != 4'b0000) begin
      mem_write_count++;
      
      // Check write enable signals
      if(tr.we !== ref_tr.mem_we) begin
        `uvm_error("MEM_WE_MISMATCH",
          $sformatf("Memory write enable mismatch at cycle %0d\n  Expected: %b\n  Got: %b",
          tr.cycle_count, ref_tr.mem_we, tr.we))
        mem_mismatches++;
        check_passed = 1'b0;
      end
      
      // Check memory address
      if(tr.Data_addr !== ref_tr.mem_addr) begin
        `uvm_error("MEM_ADDR_MISMATCH",
          $sformatf("Memory address mismatch at cycle %0d\n  Expected: 0x%0h\n  Got: 0x%0h",
          tr.cycle_count, ref_tr.mem_addr, tr.Data_addr))
        mem_mismatches++;
        check_passed = 1'b0;
      end
      
      // Check memory data written
      if(tr.Wdata !== ref_tr.mem_data) begin
        `uvm_error("MEM_DATA_MISMATCH",
          $sformatf("Memory data mismatch at cycle %0d\n  Address: 0x%0h\n  Expected: 0x%0h\n  Got: 0x%0h",
          tr.cycle_count, tr.Data_addr, ref_tr.mem_data, tr.Wdata))
        mem_mismatches++;
        check_passed = 1'b0;
      end else begin
        `uvm_info("MEM_CHECK",
          $sformatf("Memory write OK: MEM[0x%0h] = 0x%0h, we=%b",
          tr.Data_addr, tr.Wdata, tr.we), UVM_HIGH)
      end
    end
    
    // ========================================
    // Check PC for Control Flow Instructions
    // ========================================
    if(tr.opcode inside {OPCODE_BRANCH, OPCODE_JAL, OPCODE_JALR}) begin
      if(tr.opcode == OPCODE_BRANCH) branch_count++;
      else jump_count++;
      
      // PC check will happen on next cycle when monitor captures new PC
      // For now, just log the control transfer
      `uvm_info("CONTROL_FLOW",
        $sformatf("Control transfer: opcode=%s, next_pc=0x%0h",
        tr.opcode, ref_tr.next_pc), UVM_MEDIUM)
    end
    
    // ========================================
    // Track Load Instructions
    // ========================================
    if(tr.opcode == OPCODE_LOAD) begin
      mem_read_count++;
      `uvm_info("LOAD_CHECK",
        $sformatf("Load from MEM[0x%0h]", tr.Data_addr), UVM_MEDIUM)
    end
    
    // Update statistics
    if(check_passed) begin
      passed_instructions++;
      `uvm_info("CHECK_PASS",
        $sformatf("Instruction PASSED: %s", tr.convert2string()), UVM_MEDIUM)
    end else begin
      failed_instructions++;
      `uvm_error("CHECK_FAIL",
        $sformatf("Instruction FAILED: %s", tr.convert2string()))
    end
    
    retired_queue.push_back(tr);
  endfunction
  
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info("SCOREBOARD_REPORT", "========================================", UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", "      VERIFICATION SUMMARY", UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", "========================================", UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", $sformatf("Total Instructions Monitored: %0d", total_instructions), UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", $sformatf("Retired Instructions: %0d", retired_instructions), UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", $sformatf("Passed Checks: %0d", passed_instructions), UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", $sformatf("Failed Checks: %0d", failed_instructions), UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", "----------------------------------------", UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", $sformatf("Memory Writes: %0d", mem_write_count), UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", $sformatf("Memory Reads (Loads): %0d", mem_read_count), UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", $sformatf("Branches: %0d", branch_count), UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", $sformatf("Jumps (JAL/JALR): %0d", jump_count), UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", "----------------------------------------", UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", $sformatf("Register Mismatches: %0d", reg_mismatches), UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", $sformatf("Memory Mismatches: %0d", mem_mismatches), UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", $sformatf("PC Mismatches: %0d", pc_mismatches), UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", "========================================", UVM_LOW)
    
    if(failed_instructions == 0 && reg_mismatches == 0 && 
       mem_mismatches == 0 && pc_mismatches == 0) begin
      `uvm_info("SCOREBOARD_REPORT", "*** TEST PASSED ***", UVM_LOW)
    end else begin
      `uvm_error("SCOREBOARD_REPORT", "*** TEST FAILED ***")
    end
  endfunction
  
endclass