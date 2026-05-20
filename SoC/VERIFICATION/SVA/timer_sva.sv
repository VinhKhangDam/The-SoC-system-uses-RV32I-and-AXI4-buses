module timer_sva (
    input logic clk,
    input logic rstn,

    input logic [31:0] awaddr,
    input logic [ 2:0] awprot,
    input logic        awready,
    input logic        awvalid,

    input logic [31:0] wdata,
    input logic [ 3:0] wstrb,
    input logic        wvalid,
    input logic        wready,

    input logic       bvalid,
    input logic       bready,
    input logic [1:0] bresp,

    input logic [31:0] araddr,
    input logic [ 2:0] arprot,
    input logic        arready,
    input logic        arvalid,

    input logic [31:0] rdata,
    input logic [ 1:0] rresp,
    input logic        rvalid,
    input logic        rready,

    input logic irq
);

  // AXI response must be OKAY
  assert property (@(posedge clk) disable iff (!rstn) bvalid |-> (bresp == 2'b00))
  else $error("[TIMER_SVA] BRESP not OKAY");

  assert property (@(posedge clk) disable iff (!rstn) rvalid |-> (rresp == 2'b00))
  else $error("[TIMER_SVA] RRESP not OKAY");


  // VALID must hold until READY
  assert property (@(posedge clk) disable iff (!rstn) awvalid && !awready |=> awvalid)
  else $error("[TIMER_SVA] AWVALID dropped before AWREADY");

  assert property (@(posedge clk) disable iff (!rstn) wvalid && !wready |=> wvalid)
  else $error("[TIMER_SVA] WVALID dropped before WREADY");

  assert property (@(posedge clk) disable iff (!rstn) bvalid && !bready |=> bvalid)
  else $error("[TIMER_SVA] BVALID dropped before BREADY");

  assert property (@(posedge clk) disable iff (!rstn) arvalid && !arready |=> arvalid)
  else $error("[TIMER_SVA] ARVALID dropped before ARREADY");

  assert property (@(posedge clk) disable iff (!rstn) rvalid && !rready |=> rvalid)
  else $error("[TIMER_SVA] RVALID dropped before RREADY");

  // No X on output channels
  assert property (@(posedge clk) disable iff (!rstn) !$isunknown(
      {awready, wready, bvalid, bresp, arready, rvalid, rresp, rdata, irq}
  ))
  else $error("[TIMER_SVA] Output has X/Z");

  // Invalid registers reaed return DEADBEEF
  assert property (@(posedge clk) disable iff (!rstn)
                    (arvalid && arready && araddr[3:0] inside {4'hc, 4'hf}) |=> rvalid && rdata == 32'hDEADBEEF
                    )
  else $error("[TIMER_SVA] Invalid read dit not return DEAD_BEEF");

  // Prot
  assert property (@(posedge clk) disable iff (!rstn) awvalid |-> !$isunknown(awprot))
  else $error("[TIMER_SVA] AWPROT has X/Z");

  assert property (@(posedge clk) disable iff (!rstn) arvalid |-> !$isunknown(arprot))
  else $error("[TIMER_SVA] ARPROT has X/Z");

  // PROT must stable after READY
  assert property (@(posedge clk) disable iff (!rstn) awvalid && !awready |=> $stable(awprot))
  else $error("[TIMER_SVA] AWPROT changing while waiting");

  assert property (@(posedge clk) disable iff (!rstn) arvalid && !arready |=> $stable(arprot))
  else $error("[TIMER_SVA] ARPROT changing while waiting");

endmodule
