`timescale 1ns / 1ns

`include "Interface.sv"

module riscv_tb_top;
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import riscv_verif_pkg::*;
  
  // Clock and reset
  logic clk;
  logic reset;
  
  // Instantiate interface
  riscv_if vif(clk);
  
  // Instantiate DUT
  RISC_V dut (
    .clk(clk),
    .reset(vif.reset),
    .I_Req(vif.I_Req),
    .Rdata(vif.Rdata),
    .inst_data(vif.inst_data),
    .inst_addr(vif.inst_addr),
    .Data_addr(vif.Data_addr),
    .Wdata(vif.Wdata),
    .we(vif.we),
    .reg31(vif.reg31),
    .PC(vif.PC),
    .IACK(vif.IACK)
  );
  
  
  DataMem Dmem (
    .clk(clk),
    .Data_addr(vif.Data_addr),
    .Wdata(vif.Wdata),
    .we(vif.we),
    .Rdata(vif.Rdata)
  );
                                               
  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz clock (10ns period)
  end
  
  // Initial block for UVM
  initial begin
    // Set interface in config_db
    uvm_config_db#(virtual riscv_if)::set(null, "*", "vif", vif);
    
    // Set verbosity
    uvm_top.set_report_verbosity_level_hier(UVM_MEDIUM);
    
    // Enable UVM reporting
    uvm_config_db#(int)::set(null, "*", "recording_detail", UVM_FULL);
    
    // Run test
    run_test("random_test");
  end
  
  // Timeout
  initial begin 
    #4000000;
    $finish();
  end

endmodule