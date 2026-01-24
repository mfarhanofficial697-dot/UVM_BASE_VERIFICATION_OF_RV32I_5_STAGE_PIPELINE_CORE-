// FIXED: Changed RISCV_seq_item to riscv_transaction
class riscv_sequencer extends uvm_sequencer #(riscv_transaction);

  `uvm_component_utils(riscv_sequencer)
  
  function new(string name = "riscv_sequencer", uvm_component parent);
    super.new(name, parent);
    `uvm_info(get_type_name(), "Inside constructor of Sequencer Class", UVM_LOW)
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), "Inside build phase of Sequencer Class", UVM_LOW)
  endfunction : build_phase 
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(get_type_name(), "Inside connect phase of Sequencer Class", UVM_LOW)
  endfunction : connect_phase
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info(get_type_name(), "Inside run phase of Sequencer Class", UVM_LOW)
  endtask : run_phase
  
endclass : riscv_sequencer