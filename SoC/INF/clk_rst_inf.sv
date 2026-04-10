`include "../VERIFICATION/Env/uvm_tb_udf_pkg.svh"
`timescale 1ns/1ps
import uvm_tb_udf_pkg::*;
interface clk_rst_inf (output logic clk, output logic rstn);
    
    // Khởi tạo Clock chuẩn
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Tạo clock 100MHz (chu kỳ 10ns)
    end

    // Task reset để Testbench gọi khi cần
    task do_reset(integer time_length);
        rstn = 1'b0;
        #(time_length);
        rstn = 1'b1;
    endtask

    // Khởi tạo Reset ban đầu
    initial begin
        rstn = 0;     // Bắt đầu bằng 0 để reset SoC
        #20 rstn = 1; // Nhả reset sau 20ns
    end

endinterface