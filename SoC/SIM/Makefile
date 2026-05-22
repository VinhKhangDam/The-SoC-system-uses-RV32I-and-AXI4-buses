
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

# --- Windows path conversion for WSL + Questa Windows ---
ROOT_DIR_WIN := $(shell wslpath -m $(ROOT_DIR))
DUT_DIR_WIN  := $(ROOT_DIR_WIN)/DUT
INF_DIR_WIN  := $(ROOT_DIR_WIN)/INF
VERIF_DIR_WIN:= $(ROOT_DIR_WIN)/VERIFICATION
SVA_DIR_WIN  := $(VERIF_DIR_WIN)/SVA

# --- Tools ---
VLOG_CMD     = vlog -sv +acc -cover bcst
VSIM_CMD     = vsim -c -coverage
VOPT_CMD     = vopt +acc +cover top_tb -o vopt_top

# --- Python ---
PYTHON_CMD   = python3
GEN_SCRIPT   = gen_mem.py
SIM_SCRIPT   = sim_expected.py

# --- Simulation config ---
test_name    ?=
seed         ?= random

# Count loaded instructions from instr.mem at run time.
# Use recursive '=' so this is evaluated after gen_mem creates instr.mem.
CPU_INSTR_COUNT = $(shell if [ -f instr.mem ]; then awk 'NF && $$1 !~ /^\/\// {count++} END {print count+0}' instr.mem; else echo 0; fi)

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
INF_FILES    = $(INF_DIR_WIN)/*.sv
DUT_FILES    = $(DUT_DIR_WIN)/Slaves/*.sv \
               $(DUT_DIR_WIN)/CPU/*.sv \
               $(DUT_DIR_WIN)/Master/*.sv \
               $(DUT_DIR_WIN)/AXI_Master.sv \
               $(DUT_DIR_WIN)/AXI4_Lite_Interconnect.sv \
               $(DUT_DIR_WIN)/TOP.sv

UVM_PKG      = $(VERIF_DIR_WIN)/Package/soc_pkg.svh
TOP_TB       = $(VERIF_DIR_WIN)/top_tb.sv
SVA_FILES    = $(SVA_DIR_WIN)/*.sv

#==========================================================================================
# AVAILABLE TESTS
#==========================================================================================
 
# --- UVM MASTER tests (axi_*) ---
UVM_TESTS = \
    axi_random_wr_rd_test \
    axi_multi_slaves_test
 
# --- CPU MASTER tests (cpu_*) ---
CPU_TESTS = \
    cpu_test

# --- TIMER standalone tests ---
TIMER_TESTS = \
    timer_test

# --- UART standalone tests ---
UART_TESTS = \
	uart_test

# --- SPI standalone tests ---
SPI_TESTS = \
  spi_test

# --- ALL TEST ---
ALL_TESTS := $(UVM_TESTS) $(CPU_TESTS) $(TIMER_TESTS) $(UART_TESTS) $(SPI_TESTS)

#==========================================================================================
# MAIN TARGET (SINGLE TEST ONLY)
#==========================================================================================

.PHONY: all compile sim gui clean gen_mem help list timer_all timer_compile timer_sim timer_gui uart_all uart_compile uart_sim uart_gui spi_all spi_compile spi_sim spi_gui

all: gen_mem compile
ifndef test_name
	$(error ❌ Please specify test_name, e.g. make all test_name=axi_random_wr_rd_test)
endif
	@echo "======================================================="
	@echo ">>> RUN TEST: $(test_name)  [MEM_SEED=$(MEM_SEED)]"
	@echo ">>> CPU_INSTR_COUNT = $(CPU_INSTR_COUNT)"
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
		+CPU_INSTR_COUNT=$(CPU_INSTR_COUNT) \
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

ifeq ($(test_name),timer_test)
compile: timer_compile
else ifeq ($(test_name),uart_test)
compile: uart_compile
else ifeq ($(test_name), spi_test)
compile: spi_compile
else
compile: gen_mem
	@echo "--- ROOT: $(ROOT_DIR) ---"
	rm -rf work
	vlib work
	
	@echo "--- [1/4] Compile Interfaces ---"
	$(VLOG_CMD) $(INF_FILES)
	
	@echo "--- [2/4] Compile DUT ---"
	$(VLOG_CMD) +incdir+$(DUT_DIR_WIN)/CPU $(DUT_FILES)
	
	@echo "--- [3/4] Compile UVM ---"
	$(VLOG_CMD) +incdir+$(VERIF_DIR_WIN)/Transaction \
	            +incdir+$(VERIF_DIR_WIN)/Sequencer \
	            +incdir+$(VERIF_DIR_WIN)/Monitor \
	            +incdir+$(VERIF_DIR_WIN)/Driver \
	            +incdir+$(VERIF_DIR_WIN)/Agent \
	            +incdir+$(VERIF_DIR_WIN)/Coverage \
	            +incdir+$(VERIF_DIR_WIN)/Env \
	            +incdir+$(VERIF_DIR_WIN)/Scoreboard \
	            +incdir+$(VERIF_DIR_WIN)/Sequence \
	            +incdir+$(VERIF_DIR_WIN)/Test \
	            $(UVM_PKG)

	@echo "--- [SVA] Compile Assertions ---"
	$(VLOG_CMD) $(SVA_FILES)
	
	@echo "--- [4/4] Compile Top TB ---"
	$(VLOG_CMD) $(TOP_TB)
	
	@echo "--- [OPTIMIZE] ---"
	$(VOPT_CMD)
endif

#==========================================================================================
# SIM (run only, no compile)
#==========================================================================================

ifeq ($(test_name),timer_test)
sim: timer_sim
else ifeq ($(test_name),uart_test)
sim: uart_sim
else ifeq ($(test_name), spi_test)
sim: spi_sim
else
sim:
ifndef test_name
	$(error ❌ Please specify test_name, e.g. make sim test_name=cpu_instr_test)
endif
	@echo "--- [SIM ONLY] $(test_name) ---"

	@if echo $(test_name) | grep -q "cpu_"; then \
		MODE=CPU_MASTER; \
		echo "MODE = $$MODE"; \
		$(VSIM_CMD) -sv_seed $(seed) vopt_top \
			+UVM_TESTNAME=$(test_name) +$$MODE \
			+MEM_SEED=$(MEM_SEED) \
			+CPU_INSTR_COUNT=$(CPU_INSTR_COUNT) \
			-do "run -all; quit"; \
	else \
		MODE=UVM_MASTER; \
		echo "MODE = $$MODE"; \
		$(VSIM_CMD) -sv_seed $(seed) vopt_top \
			+UVM_TESTNAME=$(test_name) +$$MODE \
			+MEM_SEED=$(MEM_SEED) \
			+CPU_INSTR_COUNT=$(CPU_INSTR_COUNT) \
			-do "run -all; quit"; \
	fi
endif

#==========================================================================================
# GUI
#==========================================================================================

ifeq ($(test_name),timer_test)
gui: timer_gui
else ifeq ($(test_name),uart_test)
gui: uart_gui
else ifeq ($(test_name), spi_test)
gui: spi_gui
else
gui:
ifndef test_name
	$(error ❌ Please specify test_name, e.g. make gui test_name=cpu_instr_test)
endif
	@echo "--- [GUI MODE] $(test_name) ---"

	@if echo $(test_name) | grep -q "cpu_"; then \
		MODE=CPU_MASTER; \
		echo "MODE = $$MODE"; \
		vsim -i -sv_seed $(seed) vopt_top \
			+UVM_TESTNAME=$(test_name) +$$MODE \
			+MEM_SEED=$(MEM_SEED) \
			+CPU_INSTR_COUNT=$(CPU_INSTR_COUNT) \
			-do "add wave -recursive vopt_top/*"; \
	else \
		MODE=UVM_MASTER; \
		echo "MODE = $$MODE"; \
		vsim -i -sv_seed $(seed) vopt_top \
			+UVM_TESTNAME=$(test_name) +$$MODE \
			+MEM_SEED=$(MEM_SEED) \
			+CPU_INSTR_COUNT=$(CPU_INSTR_COUNT) \
			-do "add wave -recursive vopt_top/*"; \
	fi
endif

#==========================================================================================
# CLEAN
#==========================================================================================

clean:
	rm -rf work transcript *.wlf vopt_top timer_vopt spi_vopt *.ucdb \
		 expected.mem $(SEED_FILE)
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
	@echo "    make timer_all                         compile + run Timer standalone test"
	@echo "    make timer_compile                     compile Timer standalone testbench"
	@echo "    make timer_sim                         run Timer standalone simulation"
	@echo "    make timer_gui                         open Timer standalone waveform viewer"
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
	@echo "    make timer_all"
	@echo "    make sim  test_name=axi_read_test"
	@echo "    make gui  test_name=cpu_test MEM_SEED=42"
	@echo ""
	@echo "  Test naming convention:"
	@echo "    axi_*  →  UVM MASTER  (driver controls AXI bus)"
	@echo "    cpu_*  →  CPU MASTER  (CPU runs, UVM observes pipeline)"
	@echo ""
	@echo "  Run 'make list' to see all available test names."
	@echo ""

#==========================================================================================
# TEST LIST
#==========================================================================================

list: 
	@echo ""
	@echo "======================================================"
	@echo "		TEST LIST				     "
	@echo "======================================================"
	@for t in $(ALL_TESTS); do \
		echo "	$$t"; \
		done
	@echo ""

#==========================================================================================
# TIMER STANDALONE TEST
#==========================================================================================

TIMER_PKG       = $(VERIF_DIR_WIN)/Package/timer_pkg.svh
TIMER_TOP_TB    = $(VERIF_DIR_WIN)/timer_top_tb.sv
TIMER_SVA       = $(SVA_DIR_WIN)/timer_sva.sv
TIMER_VOPT      = timer_vopt
TIMER_INC_DIRS  = +incdir+$(VERIF_DIR_WIN)/Transaction \
                  +incdir+$(VERIF_DIR_WIN)/Driver \
                  +incdir+$(VERIF_DIR_WIN)/Monitor \
                  +incdir+$(VERIF_DIR_WIN)/Coverage \
                  +incdir+$(VERIF_DIR_WIN)/Env \
                  +incdir+$(VERIF_DIR_WIN)/Scoreboard \
                  +incdir+$(VERIF_DIR_WIN)/Sequence \
                  +incdir+$(VERIF_DIR_WIN)/Test

timer_all: timer_compile timer_sim

timer_compile:
	@echo "--- [TIMER] Compile Interfaces ---"
	rm -rf work
	vlib work
	$(VLOG_CMD) $(INF_DIR_WIN)/*.sv

	@echo "--- [TIMER] Compile DUT ---"
	$(VLOG_CMD) $(DUT_DIR_WIN)/Slaves/Timer.sv

	@echo "--- [TIMER] Compile SVA ---"
	$(VLOG_CMD) $(TIMER_SVA)

	@echo "--- [TIMER] Compile UVM Package ---"
	$(VLOG_CMD) $(TIMER_INC_DIRS) $(TIMER_PKG)

	@echo "--- [TIMER] Compile Top TB ---"
	$(VLOG_CMD) $(TIMER_TOP_TB)

	@echo "--- [TIMER] Optimize ---"
	vopt +acc +cover timer_top_tb -o $(TIMER_VOPT)

timer_sim:
	@echo "--- [TIMER] Sim ---"
	$(VSIM_CMD) $(TIMER_VOPT) \
		+UVM_TESTNAME=timer_test \
		-do "coverage save -onexit timer_coverage.ucdb; run -all; quit"

timer_gui:
	@echo "--- [TIMER] GUI ---"
	vsim -i $(TIMER_VOPT) \
		+UVM_TESTNAME=timer_test \
		-do "add wave -recursive timer_top_tb/*"

#==========================================================================================
# UART STANDALONE TEST
#==========================================================================================
UART_PKG       = $(VERIF_DIR_WIN)/Package/uart_pkg.svh
UART_TOP_TB    = $(VERIF_DIR_WIN)/uart_top_tb.sv
UART_SVA       = $(SVA_DIR_WIN)/uart_sva.sv
UART_VOPT      = uart_vopt
UART_INC_DIRS  = +incdir+$(VERIF_DIR_WIN)/Transaction \
                  +incdir+$(VERIF_DIR_WIN)/Driver \
                  +incdir+$(VERIF_DIR_WIN)/Monitor \
                  +incdir+$(VERIF_DIR_WIN)/Coverage \
                  +incdir+$(VERIF_DIR_WIN)/Env \
                  +incdir+$(VERIF_DIR_WIN)/Scoreboard \
                  +incdir+$(VERIF_DIR_WIN)/Sequence \
                  +incdir+$(VERIF_DIR_WIN)/Test

uart_all: uart_compile uart_sim

uart_compile:
	@echo "--- [UART] Compile Interfaces ---"
	rm -rf work
	vlib work
	$(VLOG_CMD) $(INF_DIR_WIN)/*.sv

	@echo "--- [UART] Compile DUT ---"
	$(VLOG_CMD) $(DUT_DIR_WIN)/Slaves/UART.sv

	@echo "--- [UART] Compile SVA ---"
	$(VLOG_CMD) $(UART_SVA)

	@echo "--- [UART] Compile UVM Package ---"
	$(VLOG_CMD) $(UART_INC_DIRS) $(UART_PKG)

	@echo "--- [UART] Compile Top TB ---"
	$(VLOG_CMD) $(UART_TOP_TB)

	@echo "--- [UART] Optimize ---"
	vopt +acc +cover uart_top_tb -o $(UART_VOPT)

uart_sim:
	@echo "--- [UART] Sim ---"
	$(VSIM_CMD) $(UART_VOPT) \
		+UVM_TESTNAME=uart_test \
		-do "coverage save -onexit uart_coverage.ucdb; run -all; quit"

uart_gui:
	@echo "--- [UART] GUI ---"
	vsim -i $(UART_VOPT) \
		+UVM_TESTNAME=uart_test \
		-do "add wave -recursive uart_top_tb/*"

#==========================================================================================
# SIM STANDALONE TEST
#==========================================================================================
SPI_PKG       = $(VERIF_DIR_WIN)/Package/spi_pkg.svh
SPI_TOP_TB    = $(VERIF_DIR_WIN)/spi_top_tb.sv
SPI_SVA       = $(SVA_DIR_WIN)/spi_sva.sv
SPI_VOPT      = spi_vopt
SPI_INC_DIRS  = +incdir+$(VERIF_DIR_WIN)/Transaction \
                  +incdir+$(VERIF_DIR_WIN)/Driver \
                  +incdir+$(VERIF_DIR_WIN)/Monitor \
									+incdir+$(VERIF_DIR_WIN)/Agent \
                  +incdir+$(VERIF_DIR_WIN)/Coverage \
                  +incdir+$(VERIF_DIR_WIN)/Env \
                  +incdir+$(VERIF_DIR_WIN)/Scoreboard \
                  +incdir+$(VERIF_DIR_WIN)/Sequence \
                  +incdir+$(VERIF_DIR_WIN)/Test

spi_all: spi_compile spi_sim

spi_compile:
	@echo "--- [SPI] Compile Interfaces ---"
	rm -rf work
	vlib work
	$(VLOG_CMD) $(INF_DIR_WIN)/*.sv

	@echo "--- [SPI] Compile DUT ---"
	$(VLOG_CMD) $(DUT_DIR_WIN)/Slaves/SPI.sv

	@echo "--- [SPI] Compile SVA ---"
	$(VLOG_CMD) $(SPI_SVA)

	@echo "--- [SPI] Compile UVM Package ---"
	$(VLOG_CMD) $(SPI_INC_DIRS) $(SPI_PKG)

	@echo "--- [SPI] Compile Top TB ---"
	$(VLOG_CMD) $(SPI_TOP_TB)

	@echo "--- [SPI] Optimize ---"
	vopt +acc +cover spi_top_tb -o $(SPI_VOPT)

spi_sim:
	@echo "--- [SPI] Sim ---"
	$(VSIM_CMD) $(SPI_VOPT) \
		+UVM_TESTNAME=spi_test \
		-do "coverage save -onexit spi_coverage.ucdb; run -all; quit"

spi_gui:
	@echo "--- [CPI] GUI ---"
	vsim -i $(SPI_VOPT) \
		+UVM_TESTNAME=spi_test \
		-do "add wave -recursive spi_top_tb/*"


