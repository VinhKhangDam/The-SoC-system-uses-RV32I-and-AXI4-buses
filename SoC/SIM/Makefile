#==========================================================================================
# SoC RISC-V Verification Makefile - SINGLE TEST FLOW
# Project: SoC-RV32I
# Author: Khang
#==========================================================================================

# --- Paths ---
ROOT_DIR     ?= $(RISCV_TB_DIR)
DUT_DIR      = $(ROOT_DIR)/DUT
INF_DIR      = $(ROOT_DIR)/INF
VERIF_DIR    = $(ROOT_DIR)/VERIFICATION
SIM_DIR      = $(ROOT_DIR)/SIM

# --- Tools ---
VLOG_CMD     = vlog -sv +acc -L uvm -cover bcst
VSIM_CMD     = vsim -c -L uvm -coverage
VOPT_CMD     = vopt +acc +cover top_tb -o vopt_top

# --- Python ---
PYTHON_CMD   = python3
GEN_SCRIPT   = gen_mem.py

# --- Simulation config ---
test_name    ?=
seed         ?= random

# --- FILE LIST ---
INF_FILES    = $(INF_DIR)/*.sv
DUT_FILES    = $(DUT_DIR)/Slaves/*.sv \
               $(DUT_DIR)/CPU/*.sv \
               $(DUT_DIR)/Master/*.sv \
               $(DUT_DIR)/AXI_Master.sv \
               $(DUT_DIR)/AXI4_Lite_Interconnect.sv \
               $(DUT_DIR)/TOP.sv

UVM_PKG      = $(VERIF_DIR)/Package/soc_pkg.svh
TOP_TB       = $(VERIF_DIR)/top_tb.sv

#==========================================================================================
# MAIN TARGET (SINGLE TEST ONLY)
#==========================================================================================

.PHONY: all compile sim gui clean gen_mem help

all: gen_mem compile
ifndef test_name
	$(error ❌ Please specify test_name, e.g. make all test_name=axi_random_wr_rd_test)
endif
	@echo "======================================================="
	@echo ">>> RUN TEST: $(test_name)"
	@echo "======================================================="

	@if echo $(test_name) | grep -q "cpu_"; then \
		MODE=CPU_MASTER; \
	else \
		MODE=UVM_MASTER; \
	fi; \
	echo ">>> MODE = $$MODE"; \
	$(VSIM_CMD) -sv_seed $(seed) vopt_top \
		+UVM_TESTNAME=$(test_name) +$$MODE \
		-do "coverage save -onexit coverage_result.ucdb; run -all; quit"

	@echo "-------------------------------------------------------"
	@echo "--- COVERAGE RESULT ---"
	@echo "-------------------------------------------------------"
	vcover report -cvg -summary coverage_result.ucdb

#==========================================================================================
# GENERATE MEMORY
#==========================================================================================

gen_mem:
	@echo "--- [GEN_MEM] Generate new instruction memory ---"
	@rm -f instr.mem cpu_instr.mem
	$(PYTHON_CMD) $(GEN_SCRIPT)

#==========================================================================================
# COMPILE
#==========================================================================================

compile: gen_mem
	@echo "--- ROOT: $(ROOT_DIR) ---"
	rm -rf work
	vlib work
	
	@echo "--- [1/4] Compile Interfaces ---"
	$(VLOG_CMD) $(INF_FILES)
	
	@echo "--- [2/4] Compile DUT ---"
	$(VLOG_CMD) +incdir+$(DUT_DIR)/CPU $(DUT_FILES)
	
	@echo "--- [3/4] Compile UVM ---"
	$(VLOG_CMD) +incdir+$(VERIF_DIR)/Transaction \
	            +incdir+$(VERIF_DIR)/Sequencer \
	            +incdir+$(VERIF_DIR)/Monitor \
	            +incdir+$(VERIF_DIR)/Driver \
	            +incdir+$(VERIF_DIR)/Agent \
	            +incdir+$(VERIF_DIR)/Coverage \
	            +incdir+$(VERIF_DIR)/Env \
	            +incdir+$(VERIF_DIR)/Scoreboard \
	            +incdir+$(VERIF_DIR)/Sequence \
	            +incdir+$(VERIF_DIR)/Test \
	            $(UVM_PKG)
	
	@echo "--- [4/4] Compile Top TB ---"
	$(VLOG_CMD) $(TOP_TB)
	
	@echo "--- [OPTIMIZE] ---"
	$(VOPT_CMD)

#==========================================================================================
# SIM (alias of all but without compile)
#==========================================================================================

sim:
ifndef test_name
	$(error ❌ Please specify test_name, e.g. make sim test_name=cpu_instr_test)
endif
	@echo "--- [SIM ONLY] $(test_name) ---"

	@if echo $(test_name) | grep -q "cpu_"; then \
		MODE=CPU_MASTER; \
	else \
		MODE=UVM_MASTER; \
	fi; \
	echo "MODE = $$MODE"; \
	$(VSIM_CMD) -sv_seed $(seed) vopt_top \
		+UVM_TESTNAME=$(test_name) +$$MODE \
		-do "run -all; quit"

#==========================================================================================
# GUI
#==========================================================================================

gui:
ifndef test_name
	$(error ❌ Please specify test_name, e.g. make gui test_name=cpu_instr_test)
endif
	@echo "--- [GUI MODE] $(test_name) ---"

	@if echo $(test_name) | grep -q "cpu_"; then \
		MODE=CPU_MASTER; \
	else \
		MODE=UVM_MASTER; \
	fi; \
	echo "MODE = $$MODE"; \
	vsim -i -L uvm vopt_top \
		+UVM_TESTNAME=$(test_name) +$$MODE \
		-do "add wave -recursive vopt_top/*; run -all"

#==========================================================================================
# CLEAN
#==========================================================================================

clean:
	rm -rf work transcript *.wlf vopt_top *.ucdb instr.mem cpu_instr.mem
	@echo "--- CLEAN DONE ---"

#==========================================================================================
# HELP
#==========================================================================================

help:
	@echo "Usage:"
	@echo "  make all test_name=<test>     : compile + run 1 test"
	@echo "  make sim test_name=<test>     : run only (no compile)"
	@echo "  make gui test_name=<test>     : open waveform"
	@echo ""
	@echo "Examples:"
	@echo "  make all test_name=axi_random_wr_rd_test"
	@echo "  make all test_name=cpu_instr_test"
	@echo ""
	@echo "Note:"
	@echo "  axi_* → UVM master"
	@echo "  cpu_* → CPU master"