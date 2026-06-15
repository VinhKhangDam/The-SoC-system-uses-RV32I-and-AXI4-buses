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
SVA_DIR      = $(VERIF_DIR)/SVA

# --- Tools ---
VLOG_CMD     = vlog -sv +acc -cover bcst
VSIM_CMD     = vsim -c -coverage
VOPT_CMD     = vopt +acc +cover top_tb -o vopt_top
GUI_CMD      = vsim -i

# --- Common simulator DO strings ---
RUN_DO       = run -all; quit
COV_DO       = coverage save -onexit coverage_result.ucdb; run -all; quit
WAVE_DO      = add wave -recursive

# --- Python ---
PYTHON_CMD   = python3
GEN_SCRIPT   = gen_mem.py
SIM_SCRIPT   = sim_expected.py

# --- RISC-V assembly program flow ---
RISCV_GCC     ?= riscv64-elf-gcc
RISCV_OBJCOPY ?= riscv64-elf-objcopy
ASM_DIR       ?= PROGRAM
ASM_TEST      ?= program
ASM           ?= $(ASM_DIR)/$(ASM_TEST).S
LINKER_SCRIPT ?= link.ld
ASM_ELF       ?= asm_prog.elf
ASM_BIN       ?= asm_prog.bin
ASM_UVM_TEST  ?= cpu_test
ASM_FILE      = $(if $(findstring /,$(ASM)),$(ASM),$(if $(wildcard $(ASM)),$(ASM),$(if $(suffix $(ASM)),$(ASM_DIR)/$(ASM),$(ASM_DIR)/$(ASM).S)))

# --- Simulation config ---
test_name    ?=
seed         ?= random

# Allow shorthand commands like:
#   make sim asm_test
#   make compile asm_test
ifneq ($(filter asm_test,$(MAKECMDGOALS)),)
test_name := asm_test
endif

# Count loaded instructions from instr.mem at run time.
CPU_INSTR_COUNT = $(shell if [ -f instr.mem ]; then awk 'NF && $$1 !~ /^\/\// {count++} END {print count+0}' instr.mem; else echo 0; fi)

# --- RNG seed ---
SEED_FILE = .last_seed

ifeq ($(origin MEM_SEED), undefined)
    MEM_SEED := $(shell if [ -f $(SEED_FILE) ]; then cat $(SEED_FILE); else python3 -c "import struct,os; print(struct.unpack('I',os.urandom(4))[0])"; fi)
endif

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
SVA_FILES    = $(SVA_DIR)/*.sv
UVM_INC_DIRS = +incdir+$(VERIF_DIR)/Transaction \
               +incdir+$(VERIF_DIR)/Sequencer \
               +incdir+$(VERIF_DIR)/Monitor \
               +incdir+$(VERIF_DIR)/Driver \
               +incdir+$(VERIF_DIR)/Agent \
               +incdir+$(VERIF_DIR)/Coverage \
               +incdir+$(VERIF_DIR)/Env \
               +incdir+$(VERIF_DIR)/Scoreboard \
               +incdir+$(VERIF_DIR)/Sequence \
               +incdir+$(VERIF_DIR)/Test

#==========================================================================================
# AVAILABLE TESTS
#==========================================================================================
 
# --- UVM MASTER tests (axi_*) ---
UVM_TESTS = \
    axi_random_wr_rd_test \
    axi_multi_slaves_test
 
# --- CPU MASTER tests (cpu_*) ---
ASM_TESTS = \
    asm_test

CPU_TESTS = \
    cpu_test \
    $(ASM_TESTS)

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
UVM_TEST_FOR_SIM = $(if $(filter $(test_name),$(ASM_TESTS)),$(ASM_UVM_TEST),$(test_name))
IS_CPU_MODE = $(filter $(test_name),$(CPU_TESTS))

#==========================================================================================
# MAIN TARGET (SINGLE TEST ONLY)
#==========================================================================================

.PHONY: all compile sim gui clean gen_mem asm_mem asm_test help list list_asm \
        timer_all timer_compile timer_sim timer_gui \
        uart_all uart_compile uart_sim uart_gui \
        spi_all spi_compile spi_sim spi_gui

ifeq ($(test_name),asm_test)
all: compile
else
all: gen_mem compile
endif
ifndef test_name
	$(error ❌ Please specify test_name, e.g. make all test_name=axi_random_wr_rd_test)
endif
	@echo "======================================================="
	@echo ">>> RUN TEST: $(test_name)  [MEM_SEED=$(MEM_SEED)]"
	@echo ">>> CPU_INSTR_COUNT = $(CPU_INSTR_COUNT)"
	@echo "======================================================="

	@if [ -n "$(IS_CPU_MODE)" ]; then \
		MODE=CPU_MASTER; \
	else \
		MODE=UVM_MASTER; \
	fi; \
	echo ">>> MODE = $$MODE"; \
	$(VSIM_CMD) -sv_seed $(seed) vopt_top \
		+UVM_TESTNAME=$(UVM_TEST_FOR_SIM) +$$MODE \
		+MEM_SEED=$(MEM_SEED) \
		+CPU_INSTR_COUNT=$(CPU_INSTR_COUNT) \
		-do "$(COV_DO)"

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

asm_mem:
	@echo "--- [ASM] Build $(ASM_FILE) -> instr.mem ---"
	@test -f $(ASM_FILE) || (echo "[ERROR] ASM file not found: $(ASM_FILE)"; exit 1)
	@test -f $(LINKER_SCRIPT) || (echo "[ERROR] Linker script not found: $(LINKER_SCRIPT)"; exit 1)
	$(RISCV_GCC) -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -ffreestanding \
		-T $(LINKER_SCRIPT) -o $(ASM_ELF) $(ASM_FILE)
	$(RISCV_OBJCOPY) -O binary $(ASM_ELF) $(ASM_BIN)
	od -An -tx4 -v $(ASM_BIN) | awk '{for (i = 1; i <= NF; i++) print $$i}' > instr.mem
	$(PYTHON_CMD) $(SIM_SCRIPT) 0
	@echo "--- [ASM] Done: instr.mem ready ---"
	@echo ">>> CPU_INSTR_COUNT = $(CPU_INSTR_COUNT)"

ifneq ($(filter-out asm_test,$(MAKECMDGOALS)),)
asm_test:
	@:
else
asm_test: test_name := asm_test
asm_test: compile sim
endif

#==========================================================================================
# COMPILE
#==========================================================================================

ifeq ($(test_name),timer_test)
compile: timer_compile
else ifeq ($(test_name),uart_test)
compile: uart_compile
else ifeq ($(test_name),spi_test)
compile: spi_compile
else ifeq ($(test_name),asm_test)
compile: asm_mem soc_compile
else
compile: gen_mem soc_compile
endif

soc_compile:
	@echo "--- ROOT: $(ROOT_DIR) ---"
	rm -rf work
	vlib work
	
	@echo "--- [1/4] Compile Interfaces ---"
	$(VLOG_CMD) $(INF_FILES)
	
	@echo "--- [2/4] Compile DUT ---"
	$(VLOG_CMD) +incdir+$(DUT_DIR)/CPU $(DUT_FILES)
	
	@echo "--- [3/4] Compile UVM ---"
	$(VLOG_CMD) $(UVM_INC_DIRS) $(UVM_PKG)

	@echo "--- [SVA] Compile Assertions ---"
	$(VLOG_CMD) $(SVA_FILES)
	
	@echo "--- [4/4] Compile Top TB ---"
	$(VLOG_CMD) $(TOP_TB)
	
	@echo "--- [OPTIMIZE] ---"
	$(VOPT_CMD)

#==========================================================================================
# SIM (run only, no compile)
#==========================================================================================

ifeq ($(test_name),timer_test)
sim: timer_sim
else ifeq ($(test_name),uart_test)
sim: uart_sim
else ifeq ($(test_name),spi_test)
sim: spi_sim
else
sim:
ifndef test_name
	$(error ❌ Please specify test_name, e.g. make sim test_name=cpu_instr_test)
endif
	@echo "--- [SIM ONLY] $(test_name) ---"

	@if [ -n "$(IS_CPU_MODE)" ]; then \
		MODE=CPU_MASTER; \
	else \
		MODE=UVM_MASTER; \
	fi; \
	echo "MODE = $$MODE"; \
	echo "UVM_TESTNAME = $(UVM_TEST_FOR_SIM)"; \
	$(VSIM_CMD) -sv_seed $(seed) vopt_top \
		+UVM_TESTNAME=$(UVM_TEST_FOR_SIM) +$$MODE \
		+MEM_SEED=$(MEM_SEED) \
		+CPU_INSTR_COUNT=$(CPU_INSTR_COUNT) \
		-do "$(RUN_DO)"
endif

#==========================================================================================
# GUI
#==========================================================================================

ifeq ($(test_name),timer_test)
gui: timer_gui
else ifeq ($(test_name),uart_test)
gui: uart_gui
else ifeq ($(test_name),spi_test)
gui: spi_gui
else
gui:
ifndef test_name
	$(error ❌ Please specify test_name, e.g. make gui test_name=cpu_instr_test)
endif
	@echo "--- [GUI MODE] $(test_name) ---"

	@if [ -n "$(IS_CPU_MODE)" ]; then \
		MODE=CPU_MASTER; \
	else \
		MODE=UVM_MASTER; \
	fi; \
	echo "MODE = $$MODE"; \
	echo "UVM_TESTNAME = $(UVM_TEST_FOR_SIM)"; \
	$(GUI_CMD) -sv_seed $(seed) vopt_top \
		+UVM_TESTNAME=$(UVM_TEST_FOR_SIM) +$$MODE \
		+MEM_SEED=$(MEM_SEED) \
		+CPU_INSTR_COUNT=$(CPU_INSTR_COUNT) \
		-do "$(WAVE_DO) vopt_top/*"
endif

#==========================================================================================
# CLEAN
#==========================================================================================

clean:
	rm -rf work transcript *.wlf vopt_top timer_vopt spi_vopt *.ucdb \
	       expected.mem $(SEED_FILE) $(ASM_ELF) $(ASM_BIN)
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
	@echo "    make uart_all                          compile + run UART standalone test"
	@echo "    make uart_compile                      compile UART standalone testbench"
	@echo "    make uart_sim                          run UART standalone simulation"
	@echo "    make uart_gui                          open UART standalone waveform viewer"
	@echo "    make spi_all                           compile + run SPI standalone test"
	@echo "    make spi_compile                       compile SPI standalone testbench"
	@echo "    make spi_sim                           run SPI standalone simulation"
	@echo "    make spi_gui                           open SPI standalone waveform viewer"
	@echo "    make gen_mem                           regenerate mem + golden ref"
	@echo "    make asm_mem ASM=<file.S>              build RISC-V .S into instr.mem"
	@echo "    make asm_test ASM=<file.S>             build .S, compile, and run cpu_test"
	@echo "    make list_asm                          show PROGRAM/*.S tests"
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
	@echo "    make compile test_name=asm_test ASM_TEST=rv32i_add"
	@echo "    make sim     test_name=asm_test"
	@echo "    make asm_test ASM_TEST=rv32i_add"
	@echo "    make asm_test ASM=PROGRAM/rv32i_add.S"
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

list_asm:
	@echo ""
	@echo "======================================================"
	@echo "		ASM TEST LIST"
	@echo "======================================================"
	@find $(ASM_DIR) -maxdepth 1 -name '*.S' -printf "	%f\n" | sort
	@echo ""

#==========================================================================================
# TIMER STANDALONE TEST
#==========================================================================================

TIMER_PKG       = $(VERIF_DIR)/Package/timer_pkg.svh
TIMER_TOP_TB    = $(VERIF_DIR)/timer_top_tb.sv
TIMER_SVA       = $(SVA_DIR)/timer_sva.sv
TIMER_VOPT      = timer_vopt
TIMER_INC_DIRS  = +incdir+$(VERIF_DIR)/Transaction \
                  +incdir+$(VERIF_DIR)/Driver \
                  +incdir+$(VERIF_DIR)/Monitor \
                  +incdir+$(VERIF_DIR)/Coverage \
                  +incdir+$(VERIF_DIR)/Env \
                  +incdir+$(VERIF_DIR)/Scoreboard \
                  +incdir+$(VERIF_DIR)/Sequence \
                  +incdir+$(VERIF_DIR)/Test

timer_all: timer_compile timer_sim

timer_compile:
	@echo "--- [TIMER] Compile Interfaces ---"
	rm -rf work
	vlib work
	$(VLOG_CMD) $(INF_DIR)/*.sv

	@echo "--- [TIMER] Compile DUT ---"
	$(VLOG_CMD) $(DUT_DIR)/Slaves/Timer.sv

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
UART_PKG       = $(VERIF_DIR)/Package/uart_pkg.svh
UART_TOP_TB    = $(VERIF_DIR)/uart_top_tb.sv
UART_SVA       = $(SVA_DIR)/uart_sva.sv
UART_VOPT      = uart_vopt
UART_INC_DIRS  = +incdir+$(VERIF_DIR)/Transaction \
                  +incdir+$(VERIF_DIR)/Driver \
                  +incdir+$(VERIF_DIR)/Monitor \
                  +incdir+$(VERIF_DIR)/Coverage \
                  +incdir+$(VERIF_DIR)/Env \
                  +incdir+$(VERIF_DIR)/Scoreboard \
                  +incdir+$(VERIF_DIR)/Sequence \
                  +incdir+$(VERIF_DIR)/Test

uart_all: uart_compile uart_sim

uart_compile:
	@echo "--- [UART] Compile Interfaces ---"
	rm -rf work
	vlib work
	$(VLOG_CMD) $(INF_DIR)/*.sv

	@echo "--- [UART] Compile DUT ---"
	$(VLOG_CMD) $(DUT_DIR)/Slaves/UART.sv

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
# SPI STANDALONE TEST
#==========================================================================================
SPI_PKG       = $(VERIF_DIR)/Package/spi_pkg.svh
SPI_TOP_TB    = $(VERIF_DIR)/spi_top_tb.sv
SPI_SVA       = $(SVA_DIR)/spi_sva.sv
SPI_VOPT      = spi_vopt
SPI_INC_DIRS  = +incdir+$(VERIF_DIR)/Transaction \
                  +incdir+$(VERIF_DIR)/Driver \
                  +incdir+$(VERIF_DIR)/Monitor \
                  +incdir+$(VERIF_DIR)/Agent \
                  +incdir+$(VERIF_DIR)/Coverage \
                  +incdir+$(VERIF_DIR)/Env \
                  +incdir+$(VERIF_DIR)/Scoreboard \
                  +incdir+$(VERIF_DIR)/Sequence \
                  +incdir+$(VERIF_DIR)/Test

spi_all: spi_compile spi_sim

spi_compile:
	@echo "--- [SPI] Compile Interfaces ---"
	rm -rf work
	vlib work
	$(VLOG_CMD) $(INF_DIR)/*.sv

	@echo "--- [SPI] Compile DUT ---"
	$(VLOG_CMD) $(DUT_DIR)/Slaves/SPI.sv

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
	@echo "--- [SPI] GUI ---"
	$(GUI_CMD) $(SPI_VOPT) \
		+UVM_TESTNAME=spi_test \
		-do "add wave -recursive spi_top_tb/*"
