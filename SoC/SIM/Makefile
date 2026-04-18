#==========================================================================================
# SoC RISC-V Verification Makefile - Pro Version (Auto Gen Memory)
# Project: SoC-RV32I
# Author: Khang
#==========================================================================================

# --- Khai báo các đường dẫn thư mục ---
ROOT_DIR     ?= $(RISCV_TB_DIR)
DUT_DIR      = $(ROOT_DIR)/DUT
INF_DIR      = $(ROOT_DIR)/INF
VERIF_DIR    = $(ROOT_DIR)/VERIFICATION
SIM_DIR      = $(ROOT_DIR)/SIM

# --- Cấu hình Tool ---
VLOG_CMD     = vlog -sv +acc -L uvm -cover bcst
VSIM_CMD     = vsim -c -L uvm -coverage
VOPT_CMD     = vopt +acc +cover top_tb -o vopt_top

# --- Cấu hình Python ---
PYTHON_CMD   = python3
GEN_SCRIPT   = gen_mem.py

# --- Thông số mô phỏng ---
test_name    ?= ALL_TESTS
seed         ?= random

# --- DANH SÁCH FILE COMPILE ---
INF_FILES    = $(INF_DIR)/*.sv
DUT_FILES    = $(DUT_DIR)/Slaves/*.sv \
               $(DUT_DIR)/CPU/*.sv \
               $(DUT_DIR)/Master/*.sv \
               $(DUT_DIR)/AXI_Master.sv \
               $(DUT_DIR)/AXI4_Lite_Interconnect.sv \
               $(DUT_DIR)/TOP.sv

UVM_PKG      = $(VERIF_DIR)/Package/soc_pkg.svh
TOP_TB       = $(VERIF_DIR)/top_tb.sv

# --- Targets chính ---
.PHONY: all compile sim gui clean help gen_mem

TEST_LIST = axi_random_wr_rd_test 

# Chạy toàn bộ luồng: Tạo mem -> Biên dịch -> Chạy sim
all: gen_mem compile
	@if [ "$(test_name)" = "ALL_TESTS" ]; then \
		echo "--- [RUN ALL MODE] Dang chay toan bo danh sach test ---"; \
		rm -f *.ucdb; \
		for test in $(TEST_LIST); do \
			echo "Running test: $$test"; \
			$(VSIM_CMD) -sv_seed $(seed) vopt_top +UVM_TESTNAME=$$test -do "coverage save -onexit $$test.ucdb; run -all; quit"; \
		done; \
		vcover merge final_coverage.ucdb *.ucdb; \
		vcover report -cvg -summary final_coverage.ucdb; \
	else \
		echo "--- [SINGLE TEST MODE] Dang chay test: $(test_name) ---"; \
		$(VSIM_CMD) -sv_seed $(seed) vopt_top +UVM_TESTNAME=$(test_name) -do "coverage save -onexit coverage_result.ucdb; run -all; quit"; \
		vcover report -cvg -summary coverage_result.ucdb; \
	fi

# Target 0: Tự động xóa file mem cũ và tạo tập lệnh mới (100 câu lệnh)
gen_mem:
	@echo "--- [0/4] Dang xoa file .mem cu va chay script Python tao 100 testcase moi ---"
	@rm -f instr.mem cpu_instr.mem
	$(PYTHON_CMD) $(GEN_SCRIPT)

# Target 1: Biên dịch (Phụ thuộc vào gen_mem để đảm bảo file mem luôn mới)
compile: gen_mem
	@echo "--- Dang dung ROOT: $(ROOT_DIR) ---"
	rm -rf work
	vlib work
	
	@echo "--- [1/4] Bien dich Interfaces ---"
	$(VLOG_CMD) $(INF_FILES)
	
	@echo "--- [2/4] Bien dich DUT (SoC Logic) ---"
	$(VLOG_CMD) +incdir+$(DUT_DIR)/CPU $(DUT_FILES)
	
	@echo "--- [3/4] Bien dich UVM Package ---"
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
	
	@echo "--- [4/4] Bien dich Top Testbench ---"
	$(VLOG_CMD) $(TOP_TB)
	
	@echo "--- [Optimize] Chay vopt ---"
	$(VOPT_CMD)

# Target 2: Chạy mô phỏng (Console mode)
sim: gen_mem
	@echo "--- Dang chay simulation: $(test_name) ---"
	$(VSIM_CMD) -sv_seed $(seed) vopt_top +UVM_TESTNAME=$(test_name) -do "coverage save -onexit coverage_result.ucdb; run -all; quit"
	@echo "-------------------------------------------------------"
	@echo "--- RESULT OF COVERAGE FOR SOC RISC-V ---"
	@echo "-------------------------------------------------------"
	vcover report -cvg -summary coverage_result.ucdb

# Target 3: Chạy GUI để xem waveform
gui: gen_mem
	@echo "--- Mo GUI Questasim ---"
	vsim -i -L uvm vopt_top +UVM_TESTNAME=$(test_name) -do "add wave -recursive vopt_top/*; run -all"

# Target 4: Dọn dẹp
clean:
	rm -rf work transcript *.wlf vopt_top *.ucdb instr.mem cpu_instr.mem
	@echo "--- Da don dep sach se (bao gom ca file .mem) ---"

help:
	@echo "Cach dung:"
	@echo "  make all          : Tu dong tao mem, compile va chay tat ca test"
	@echo "  make compile      : Chi tao mem va bien dich"
	@echo "  make sim          : Chạy simulation (mac dinh: ALL_TESTS)"
	@echo "  make gui          : Mo Questasim GUI kem waveform"
	@echo "  make gen_mem      : Chỉ chạy script Python tạo file instruction"
	@echo "  make clean        : Xoa sach file tam"