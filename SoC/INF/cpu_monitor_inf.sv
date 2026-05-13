`timescale 1ns/1ps
interface cpu_monitor_inf (input clk, input rstn);
    // ---- Fetch Stage ----
    logic [31:0] PcF;
    logic [31:0] InstrF;

    // ---- Decode Stage ----
    logic [31:0] InstrD;
    logic [31:0] PcD;
    logic [4:0] Rs1D;
    logic [4:0] Rs2D;
    logic [4:0] RdD;

    // ---- Execution Stage ----
    logic [31:0] ALUResultE;
    logic [4:0] RdE;
    logic [1:0] ForwardA;
    logic [1:0] ForwardB;
    logic PCSrc;

    // ---- Memory Stage ----
    logic [31:0] ALUResultM;
    logic [31:0] WriteDataM;
    logic        MemWriteM;
    logic [4:0] RdM;

    // ---- Write Stage ----
    logic RegWriteW;
    logic [4:0] RdW;
    logic [31:0] ResultW;

    // ---- Hazard / Stall ----
    logic StallF;
    logic FlushE;
    logic mem_stall_i;

    clocking mon_cb @(posedge clk);
        default input #1;
        input PcF, InstrF;
        input InstrD, PcD, Rs1D, Rs2D, RdD;
        input ALUResultE, RdE, ForwardA, ForwardB, PCSrc;
        input ALUResultM, WriteDataM, MemWriteM, RdM;
        input RegWriteW, RdW, ResultW;
        input StallF, FlushE, mem_stall_i; 
    endclocking
endinterface //cpu_inf