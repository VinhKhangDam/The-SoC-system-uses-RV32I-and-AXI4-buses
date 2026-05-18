`timescale 1ns/1ps

module axi4_lite_sva (
    input logic        clk,
    input logic        rstn,

    input logic [31:0] awaddr,
    input logic [2:0]  awprot,
    input logic        awvalid,
    input logic        awready,

    input logic [31:0] wdata,
    input logic [3:0]  wstrb,
    input logic        wvalid,
    input logic        wready,

    input logic [1:0]  bresp,
    input logic        bvalid,
    input logic        bready,

    input logic [31:0] araddr,
    input logic [2:0]  arprot,
    input logic        arvalid,
    input logic        arready,

    input logic [31:0] rdata,
    input logic [1:0]  rresp,
    input logic        rvalid,
    input logic        rready
);

    property aw_stable_until_ready;
        @(posedge clk) disable iff (!rstn)
        awvalid && !awready |=> awvalid && $stable(awaddr) && $stable(awprot);
    endproperty

    property w_stable_until_ready;
        @(posedge clk) disable iff (!rstn)
        wvalid && !wready |=> wvalid && $stable(wdata) && $stable(wstrb);
    endproperty

    property ar_stable_until_ready;
        @(posedge clk) disable iff (!rstn)
        arvalid && !arready |=> arvalid && $stable(araddr) && $stable(arprot);
    endproperty

    property r_stable_until_ready;
        @(posedge clk) disable iff (!rstn)
        rvalid && !rready |=> rvalid && $stable(rdata) && $stable(rresp);
    endproperty

    property b_stable_until_ready;
        @(posedge clk) disable iff (!rstn)
        bvalid && !bready |=> bvalid && $stable(bresp);
    endproperty

    property no_x_when_awvalid;
        @(posedge clk) disable iff (!rstn)
        awvalid |-> !$isunknown({awaddr, awprot});
    endproperty

    property no_x_when_wvalid;
        @(posedge clk) disable iff (!rstn)
        wvalid |-> !$isunknown({wdata, wstrb});
    endproperty

    property no_x_when_arvalid;
        @(posedge clk) disable iff (!rstn)
        arvalid |-> !$isunknown({araddr, arprot});
    endproperty

    property legal_bresp;
        @(posedge clk) disable iff (!rstn)
        bvalid |-> (bresp inside {2'b00, 2'b10, 2'b11});
    endproperty

    property legal_rresp;
        @(posedge clk) disable iff (!rstn)
        rvalid |-> (rresp inside {2'b00, 2'b10, 2'b11});
    endproperty

    assert property (aw_stable_until_ready) else $error("[AXI_SVA] AWADDR/AWPROT changed before AWREADY");
    assert property (w_stable_until_ready)  else $error("[AXI_SVA] WDATA/WSTRB changed before WREADY");
    assert property (ar_stable_until_ready) else $error("[AXI_SVA] ARADDR/ARPROT changed before ARREADY");
    assert property (r_stable_until_ready)  else $error("[AXI_SVA] RDATA/RRESP changed before RREADY");
    assert property (b_stable_until_ready)  else $error("[AXI_SVA] BRESP changed before BREADY");

    assert property (no_x_when_awvalid) else $error("[AXI_SVA] AWADDR/AWPROT has X when AWVALID");
    assert property (no_x_when_wvalid)  else $error("[AXI_SVA] WDATA/WSTRB has X when WVALID");
    assert property (no_x_when_arvalid) else $error("[AXI_SVA] ARADDR/ARPROT has X when ARVALID");

    assert property (legal_bresp) else $error("[AXI_SVA] Illegal BRESP");
    assert property (legal_rresp) else $error("[AXI_SVA] Illegal RRESP");

endmodule
