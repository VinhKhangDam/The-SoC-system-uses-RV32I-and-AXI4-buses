#==========================================================================================
# SoC RISC-V Verification Makefile - Pro Version (Using Package)
# Project: SoC-RV32I
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

# --- Thông số mô phỏng ---
test_name    ?= ALL_TESTS
seed         ?= random

# --- DANH SÁCH FILE COMPILE ---

# 1. Interfaces
INF_FILES    = $(INF_DIR)/*.sv

# 2. DUT Files
DUT_FILES    = $(DUT_DIR)/Slaves/*.sv \
               $(DUT_DIR)/CPU/*.sv \
               $(DUT_DIR)/Master/*.sv \
               $(DUT_DIR)/AXI_Master.sv \
               $(DUT_DIR)/AXI4_Lite_Interconnect.sv \
               $(DUT_DIR)/TOP.sv

# 3. UVM Package (Chỉ cần 1 file Package chứa tất cả Transaction, Driver, Monitor, Agent, Env...)
UVM_PKG      = $(VERIF_DIR)/Package/soc_pkg.svh

# 4. Top Testbench
TOP_TB       = $(VERIF_DIR)/top_tb.sv

# --- Targets chính ---

.PHONY: all compile sim gui clean help

TEST_LIST = axi_random_wr_rd_test 

all: compile
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

# Target biên dịch: Xóa cũ làm mới hoàn toàn để tránh lỗi "Error loading design"
compile:
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

# Target chạy mô phỏng (Console mode)
sim:
	@echo "--- Dang chay simulation: $(test_name) ---"
	$(VSIM_CMD) -sv_seed $(seed) vopt_top +UVM_TESTNAME=$(test_name) -do "coverage save -onexit coverage_result.ucdb; run -all; quit"
	@echo "-------------------------------------------------------"
	@echo "--- RESULT OF COVERAGE FOR SOC RISC-V ---"
	@echo "-------------------------------------------------------"
	vcover report -cvg -summary coverage_result.ucdb
	@echo "-------------------------------------------------------"

# Target chạy GUI để xem sóng
gui:
	@echo "--- Mo GUI Questasim ---"
	vsim -i -L uvm vopt_top +UVM_TESTNAME=$(test_name) -do "add wave -recursive vopt_top/*; run -all"

# Target dọn dẹp
clean:
	rm -rf work transcript *.wlf vopt_top
	@echo "--- Da don dep sach se ---"

help:
	@echo "Cach dung: make compile | make sim | make gui | make clean"
