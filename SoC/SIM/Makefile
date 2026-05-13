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
SIM_SCRIPT   = sim_expected.py

# --- Simulation config ---
test_name    ?=
seed         ?= random

# --- RNG seed ---
# := evaluates ONCE at parse time → gen_mem.py and sim_expected.py always share the same seed.
# Override from CLI: make gen_mem MEM_SEED=1234
# 1. Định nghĩa file lưu seed tạm thời
SEED_FILE = .last_seed

# 2. Logic xác định MEM_SEED:
#    Ưu tiên 1: Lấy từ dòng lệnh nếu ông gõ 'make all MEM_SEED=123'
#    Ưu tiên 2: Nếu không có dòng lệnh, thử đọc từ file .last_seed (dùng cho make gui, make sim)
#    Ưu tiên 3: Nếu vẫn không có (lần đầu chạy), sinh số ngẫu nhiên mới.
ifeq ($(origin MEM_SEED), undefined)
    MEM_SEED := $(shell if [ -f $(SEED_FILE) ]; then cat $(SEED_FILE); else python3 -c "import struct,os; print(struct.unpack('I',os.urandom(4))[0])"; fi)
endif

# 3. Ép biến 'seed' của Questasim chạy theo MEM_SEED để đồng bộ 100%
seed = $(MEM_SEED)

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
# AVAILABLE TESTS
#==========================================================================================
 
# --- UVM MASTER tests (axi_*) ---
UVM_TESTS = \
    axi_write_test \
    axi_read_test \
    axi_random_wr_rd_test \
    axi_multi_slaves_test
 
# --- CPU MASTER tests (cpu_*) ---
CPU_TESTS = \
    cpu_test

#==========================================================================================
# MAIN TARGET (SINGLE TEST ONLY)
#==========================================================================================

.PHONY: all compile sim gui clean gen_mem help

all: gen_mem compile
ifndef test_name
	$(error ❌ Please specify test_name, e.g. make all test_name=axi_random_wr_rd_test)
endif
	@echo "======================================================="
	@echo ">>> RUN TEST: $(test_name)  [MEM_SEED=$(MEM_SEED)]"
	@echo "======================================================="

	@if echo $(test_name) | grep -q "cpu_"; then \
		MODE=CPU_MASTER; \
	else \
		MODE=UVM_MASTER; \
	fi; \
	echo ">>> MODE = $$MODE"; \
	$(VSIM_CMD) -sv_seed $(seed) vopt_top \
		+UVM_TESTNAME=$(test_name) +$$MODE \
		+MEM_SEED=$(MEM_SEED) \
		-do "coverage save -onexit coverage_result.ucdb; run -all; quit"

#==========================================================================================
# GENERATE MEMORY + EXPECTED RESULTS
#==========================================================================================

gen_mem:
	@echo "--- [GEN_MEM] Generate memory + golden reference ---"
	@echo $(MEM_SEED) > $(SEED_FILE)
	@echo ">>> Using SEED: $(MEM_SEED) (Saved to $(SEED_FILE))"
	@rm -f instr.mem expected.mem
	$(PYTHON_CMD) $(GEN_SCRIPT) $(MEM_SEED)
	$(PYTHON_CMD) $(SIM_SCRIPT) $(MEM_SEED)
	@echo "--- Done: instr.mem + expected.mem ready ---"

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
# SIM (run only, no compile)
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
		+MEM_SEED=$(MEM_SEED) \
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
	vsim -i -sv_seed $(seed) -L uvm vopt_top \
		+UVM_TESTNAME=$(test_name) +$$MODE \
		+MEM_SEED=$(MEM_SEED) \
		-do "add wave -recursive vopt_top/*; run -all"

#==========================================================================================
# CLEAN
#==========================================================================================

clean:
	rm -rf work transcript *.wlf vopt_top *.ucdb \
		   instr.mem expected.mem $(SEED_FILE)
	@echo "--- CLEAN DONE ---"

#==========================================================================================
# HELP
#==========================================================================================
 
help:
	@echo ""
	@echo "======================================================="
	@echo "         SoC-RV32I Verification — HELP"
	@echo "======================================================="
	@echo ""
	@echo "  Targets:"
	@echo "    make all  test_name=<test>             compile + run 1 test"
	@echo "    make sim  test_name=<test>             run only (no recompile)"
	@echo "    make gui  test_name=<test>             open waveform viewer"
	@echo "    make compile                           compile only"
	@echo "    make gen_mem                           regenerate mem + golden ref"
	@echo "    make list                              show all available tests"
	@echo "    make clean                             remove all build artifacts"
	@echo "    make help                              show this message"
	@echo ""
	@echo "  Options:"
	@echo "    MEM_SEED=<N>   fix the RNG seed for reproducible runs (default: random)"
	@echo ""
	@echo "  Examples:"
	@echo "    make all  test_name=axi_write_test"
	@echo "    make all  test_name=axi_random_wr_rd_test MEM_SEED=1234"
	@echo "    make all  test_name=cpu_test"
	@echo "    make sim  test_name=axi_read_test"
	@echo "    make gui  test_name=cpu_test MEM_SEED=42"
	@echo ""
	@echo "  Test naming convention:"
	@echo "    axi_*  →  UVM MASTER  (driver controls AXI bus)"
	@echo "    cpu_*  →  CPU MASTER  (CPU runs, UVM observes pipeline)"
	@echo ""
	@echo "  Run 'make list' to see all available test names."
	@echo ""