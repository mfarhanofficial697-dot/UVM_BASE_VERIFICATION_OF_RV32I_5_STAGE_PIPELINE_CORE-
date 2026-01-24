// ============================================================================
// RISC-V CPU Driver
// ============================================================================

class riscv_driver extends uvm_driver #(riscv_transaction);
  
  `uvm_component_utils(riscv_driver)
  
  virtual riscv_if vif;
  
  // Instruction memory - loaded from test
  bit [31:0] instr_mem[bit[31:0]];
  
  // Reference data memory for providing Rdata
  bit [31:0] data_mem[bit[31:0]];
  
  int reset_cycles;
  
  function new(string name = "riscv_driver", uvm_component parent = null);
    super.new(name, parent);
    reset_cycles = 5;
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual riscv_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set for driver")
  endfunction
  
  task run_phase(uvm_phase phase);
    
    // Initialize signals
    vif.reset <= 1'b1;
    vif.I_Req <= 1'b0;
    vif.inst_data <= 32'h00000013; // NOP
    vif.Rdata <= 32'h0;
    
    // Apply reset
    repeat(reset_cycles) @(posedge vif.clk);
    vif.reset <= 1'b0;
    @(posedge vif.clk);
    
    forever begin
      seq_item_port.get_next_item(req);
      drive_transaction(req);
      seq_item_port.item_done();
    end
    
  endtask
  
  task drive_transaction(riscv_transaction tr);
    
    // Drive control signals
    @(posedge vif.clk);
    vif.reset <= tr.reset;
    vif.I_Req <= tr.I_Req;
    
    // Drive instruction data based on PC
    // The instruction memory is accessed using inst_addr from DUT
    if(instr_mem.exists(vif.inst_addr)) begin
      vif.inst_data <= instr_mem[vif.inst_addr];
    end else begin
      vif.inst_data <= 32'h00000013; // NOP if address not in memory
    end
    
    // Provide read data for load instructions
    // This is driven based on Data_addr from previous cycle
    if(data_mem.exists(vif.Data_addr)) begin
      vif.Rdata <= data_mem[vif.Data_addr];
    end else begin
      vif.Rdata <= 32'h0;
    end
    
    // Update data memory on writes
    if(vif.we != 4'b0000) begin
      bit [31:0] addr = vif.Data_addr;
      bit [31:0] current_data = data_mem.exists(addr) ? data_mem[addr] : 32'h0;
      bit [31:0] write_data = vif.Wdata;
      
      // Handle byte-level writes
      if(vif.we[0]) current_data[7:0]   = write_data[7:0];
      if(vif.we[1]) current_data[15:8]  = write_data[15:8];
      if(vif.we[2]) current_data[23:16] = write_data[23:16];
      if(vif.we[3]) current_data[31:24] = write_data[31:24];
      
      data_mem[addr] = current_data;
      
      `uvm_info("DRIVER", $sformatf("MEM Write: addr=0x%0h, data=0x%0h, we=%b", 
                addr, current_data, vif.we), UVM_HIGH)
    end
    
  endtask
  
  // Function to load instruction memory from file or array
  function void load_instr_mem(string filename = "");
    if(filename != "") begin
      $readmemh(filename, instr_mem);
      `uvm_info("DRIVER", $sformatf("Loaded instruction memory from %s", filename), UVM_LOW)
    end
  endfunction
  
  // Function to preload specific instructions
  function void set_instruction(bit[31:0] addr, bit[31:0] inst);
    instr_mem[addr] = inst;
    `uvm_info("DRIVER", $sformatf("Set MEM[0x%0h] = 0x%0h", addr, inst), UVM_HIGH)
  endfunction
  
  // Function to preload data memory
  function void set_data_mem(bit[31:0] addr, bit[31:0] data);
    data_mem[addr] = data;
    `uvm_info("DRIVER", $sformatf("Set DATA_MEM[0x%0h] = 0x%0h", addr, data), UVM_HIGH)
  endfunction
  
endclass