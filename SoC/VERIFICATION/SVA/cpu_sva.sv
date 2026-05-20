`timescale 1ns / 1ps

module cpu_sva (
    input clk,
    input rstn,

    input logic [31:0] PcF,
    input logic [31:0] InstrF,
    input logic [31:0] InstrD,
    input logic [31:0] PcD,

    input logic StallF,
    input logic FlushE,
    input logic mem_stall_i,

    input logic [1:0] ForwardA,
    input logic [1:0] ForwardB,

    input logic        RegWriteW,
    input logic [ 4:0] RdW,
    input logic [31:0] ResultW,

    input logic sva_en_InstrF,
    input logic sva_en_InstrD
);

  // PC must always be word aligned
  assert property (@(posedge clk) disable iff (!rstn) PcF[1:0] == 2'b00)
  else $error("[CPU_SVA] PcF is not word aligned : %h", PcF);

  assert property (@(posedge clk) disable iff (!rstn) PcD[1:0] == 2'b00)
  else $error("[CPU_SVA] PcD is not word aligned : %h", PcD);

  // No unknow instruction/PC after reset
  assert property (@(posedge clk) disable iff (!rstn) !$isunknown(PcF))
  else $error("[CPU_SVA] PcF has X/Z");

  assert property (@(posedge clk) disable iff (!rstn || !sva_en_InstrF) !$isunknown(InstrF))
  else $error("[CPU_SVA] InstrF has X/Z");

  assert property (@(posedge clk) disable iff (!rstn || !sva_en_InstrD) !$isunknown(InstrD))
  else $error("[CPU_SVA] InstrD has X/Z");
  // Fetch stall must hold PC Stable
  assert property (@(posedge clk) disable iff (!rstn || !sva_en_InstrF) StallF |=> $stable(PcF))
  else $error("[CPU_SVA] Pc changed while StallF = 1");

  // Memory stall should stall fetch
  assert property (@(posedge clk) disable iff (!rstn || !sva_en_InstrF) mem_stall_i |-> StallF)
  else $error("[CPU_SVA] mem_stall_i asserted but StallF not asserted");

  // Forwarding select must be egal
  assert property (@(posedge clk) disable iff(!rstn || !sva_en_InstrD)
                    ForwardA inside {2'b00, 2'b01, 2'b10}
                    )
  else $error("[CPU_SVA] Illegal ForwardA=%b", ForwardA);

  assert property (@(posedge clk) disable iff(!rstn || !sva_en_InstrD)
                    ForwardB inside {2'b00, 2'b01, 2'b10}
                    )
  else $error("[CPU_SVA] Illegal ForwardB=%b", ForwardB);

  // Flush E should not be X
  assert property (@(posedge clk) disable iff (!rstn || !sva_en_InstrD) !$isunknown(FlushE))
  else $error("[CPU_SVA] FlushE has X/Z");
endmodule
