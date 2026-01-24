# =============================
# UVM + Multi-UVC (Router DUT)
# =============================

-timescale 1ns/1ps

# ---------------------------------------------------------
# UVM HOME
# ---------------------------------------------------------
// -uvmhome /home/cc/mnt/XCELIUM2309/tools/methodology/UVM/CDNS-1.1d

-uvmhome /home/cc/mnt/XCELIUM2309/tools/methodology/UVM/CDNS-1.2

################################################################################
# TOOL OPTIONS
################################################################################
# Enable SystemVerilog + UVM
+incdir+./RTL
+incdir+./TB
// +incdir+./uvc/iram
// +incdir+./uvc/mem
// +incdir+./uvc/retire

# UVM
+UVM_NO_RELNOTES
+define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR

// uvc/retire/retire_if.sv

################################################################################
# RTL FILES (Single-cycle RISC-V core)
################################################################################
RTL/ALU_Control.sv   
RTL/EX_MEM.sv           
RTL/ImmGen.sv         
RTL/PC.sv
RTL/ALU.sv           
RTL/Forwarding_Unit.sv  
RTL/InstrMem.sv       
RTL/RegFile.sv
RTL/Control_Unit.sv  
RTL/ID_EX.sv            
RTL/MEM_WB.sv         
RTL/RISC_V.sv
RTL/DataMem.sv       
RTL/IF_ID.sv            
RTL/Mult_Div_Unit.sv  
RTL/Staller.sv

################################################################################
# IRAM UVC FILES
################################################################################
TB/Interface.sv
TB/RISCV_pkg.sv

################################################################################
# TB + TEST FILES
################################################################################
TB/Top.sv

################################################################################
# SCOREBOARD & COVERAGE
################################################################################
// uvc/iram/scoreboard.sv
// uvc/iram/coverage.sv

+cover=all
