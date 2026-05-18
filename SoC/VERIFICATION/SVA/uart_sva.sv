module uart_sva (
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

                 input logic        bvalid,
                 input logic        bready,
                 input logic [1:0]  bresp,

                 input logic [31:0] araddr,
                 input logic [2:0]  arprot,
                 input logic        arvalid,
                 input logic        arready,

                 input logic [31:0] rdata,
                 input logic        rvalid,
                 input logic        rready,
                 input logic [1:0]  rresp,

                 input logic        uart_tx,
                 input logic        uart_rx
);

   assert property (@(posedge clk) disable iff(!rstn)
                    bvalid |-> bresp == 2'b00
                    ) else $error ("[UART_SVA] BRESP not OKAY");

   assert property (@(posedge clk) disable iff(!rstn)
                    rvalid |-> rresp == 2'b00
                    ) else $error ("[UART_SVA] RRESP not OKAY");

   assert property (@(posedge clk) disable iff(!rstn)
                    awvalid |-> !$isunknown({awaddr, awprot})
                    ) else $error("[UART_SVA] AW has X/Z");

   assert property (@(posedge clk) disable iff(!rstn)
                    arvalid |-> !$isunknown({araddr, arprot})
                    ) else $error ("[UART_SVA] AR has X/Z");

   assert property (@(posedge clk) disable iff(!rstn)
                    wvalid |-> !$isunknown({wdata, wstrb})
                    ) else $error("[UART_SVA] W has X/Z");

   assert property (@(posedge clk) disable iff(!rstn)
                    awvalid && !awready |=> $stable({awaddr, awprot})
                    ) else $error("[UART_SVA] AW changed while waiting");

   assert property (@(posedge clk) disable iff(!rstn)
                    wvalid && !wready |=> $stable({wdata, wstrb})
                    ) else $error("[UART_SVA] W changed while waiting");

   assert property (@(posedge clk) disable iff(!rstn)
                    arvalid && !arready |=> $stable({araddr, arprot})
                    ) else $error("[UART_SVA] AR changed while waiting");

   assert property (@(posedge clk) disable iff(!rstn)
                    bvalid && !bready |=> bvalid
                    ) else $error("[UART_SVA] BVALID dropped before BREADY");

   assert property (@(posedge clk) disable iff(!rstn)
                    rvalid && !rready |=> rvalid
                    ) else $error("[UART_SVA] RVALID dropped before RREADY");

   assert property (@(posedge clk) disable iff(!rstn)
                    !$isunknown({awready, wready, bvalid, bresp, arready, rvalid, rresp, uart_tx})
                    ) else $error("[UART_SVA] Output has X/Z");

   assert property (@(posedge clk) disable iff(!rstn)
                    rvalid |-> !$isunknown(rdata)
                    ) else $error("[UART_SVA] RDATA has X/Z while RVALID");
endmodule // uart_sva
