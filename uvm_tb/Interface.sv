// ============================================================================
// RISC-V CPU Interface
// ============================================================================

interface riscv_if(input bit clk);
  
  // Input signals to DUT
  logic        reset;
  logic        I_Req;
  logic [31:0] Rdata;
  logic [31:0] inst_data;
  
  // Output signals from DUT
  logic [31:0] inst_addr;
  logic [31:0] Data_addr;
  logic [31:0] Wdata;
  logic [3:0]  we;
  logic [31:0] reg31;
  logic [31:0] PC;
  logic        IACK;
  
  // Clocking blocks for driver and monitor
  clocking driver_cb @(posedge clk);
    output reset;
    output I_Req;
    input Rdata;
    output inst_data;
    input  inst_addr;
    input  Data_addr;
    input  Wdata;
    input  we;
    input  reg31;
    input  PC;
    input  IACK;
  endclocking
  
  clocking monitor_cb @(posedge clk);
    input reset;
    input I_Req;
    input Rdata;
    input inst_data;
    input inst_addr;
    input Data_addr;
    input Wdata;
    input we;
    input reg31;
    input PC;
    input IACK;
  endclocking
  
  modport DRIVER (clocking driver_cb, input clk);
  modport MONITOR (clocking monitor_cb, input clk);
  
endinterface