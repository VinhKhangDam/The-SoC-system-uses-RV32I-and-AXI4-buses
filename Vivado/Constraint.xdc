# Tạo clock ảo 100MHz (Chu kỳ 10ns) để Vivado tính toán timing
create_clock -period 10.000 -name virtual_sys_clk [get_ports clk]