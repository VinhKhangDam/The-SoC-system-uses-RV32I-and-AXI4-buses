`timescale 1ns/1ps
interface clk_rst_inf (output logic clk, output logic rstn);
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    task do_reset(integer time_length);
        rstn = 1'b0;
        #(time_length);
        rstn = 1'b1;
    endtask

    initial begin
        rstn = 0;     
        #20 rstn = 1;
    end

endinterface