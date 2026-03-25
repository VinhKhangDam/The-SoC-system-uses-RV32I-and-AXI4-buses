#!/bin/bash

# 1. Khai báo đường dẫn
RTL_DIR="../CPU"
TB_FILE="./CPU_tb.sv"
TOP_MODULE="CPU_tb"

# 2. Khởi tạo thư viện work của QuestaSim
if [ ! -d "work" ]; then
    vlib work
fi

echo "--- Compile RTL modules in $RTL_DIR ---"
# Biên dịch tất cả file .sv trong thư mục CPU
# Lưu ý: Nếu Khang chia mỗi module 1 file, lệnh này sẽ gom hết.
vlog -sv $RTL_DIR/*.sv

echo "--- Đang biên dịch Testbench ---"
vlog -sv $TB_FILE

echo "--- Start Simulation ---"
# Chạy vsim ở chế độ command line
vsim -c $TOP_MODULE -do "run -a; quit -f" | tee CPU.log

echo "--- Check file log to check the result ---"