module timer_top_tb;
   import uvm_pkg::*;
   import timer_pkg::*;

   `include "uvm_macros.svh"

   logic clk_wire;
   logic rstn_wire;
   logic irq;

   clk_rst_inf cr_vif(.clk(clk_wire), .rstn(rstn_wire));
   soc_inf vif(.clk(cr_vif.clk), .rstn(cr_vif.rstn));

   Timer dut (
              .clk(cr_vif.clk),
              .rstn(cr_vif.rstn),
              .s_axi_awaddr (vif.awaddr),
              .s_axi_awprot (vif.awprot),
              .s_axi_awvalid(vif.awvalid),
              .s_axi_awready(vif.awready),

              .s_axi_wdata  (vif.wdata),
              .s_axi_wstrb  (vif.wstrb),
              .s_axi_wvalid (vif.wvalid),
              .s_axi_wready (vif.wready),

              .s_axi_bvalid (vif.bvalid),
              .s_axi_bresp  (vif.bresp),
              .s_axi_bready (vif.bready),

              .s_axi_araddr (vif.araddr),
              .s_axi_arprot (vif.arprot),
              .s_axi_arvalid(vif.arvalid),
              .s_axi_arready(vif.arready),

              .s_axi_rready (vif.rready),
              .s_axi_rvalid (vif.rvalid),
              .s_axi_rresp  (vif.rresp),
              .s_axi_rdata  (vif.rdata),

              .irq(irq)
              );

   timer_sva timer_sva (
                        .clk(cr_vif.clk),
                        .rstn(cr_vif.rstn),

                        .awaddr (vif.awaddr),
                        .awprot (vif.awprot),
                        .awvalid(vif.awvalid),
                        .awready(vif.awready),

                        .wdata (vif.wdata),
                        .wstrb (vif.wstrb),
                        .wvalid(vif.wvalid),
                        .wready(vif.wready),

                        .bvalid(vif.bvalid),
                        .bready(vif.bready),
                        .bresp (vif.bresp),

                        .araddr (vif.araddr),
                        .arprot (vif.arprot),
                        .arvalid(vif.arvalid),
                        .arready(vif.arready),

                        .rdata (vif.rdata),
                        .rvalid(vif.rvalid),
                        .rready(vif.rready),
                        .rresp (vif.rresp),

                        .irq(irq)
                        );

   initial begin
      uvm_config_db #(virtual clk_rst_inf)::set(null, "*", "vif_cr", cr_vif);
      uvm_config_db #(virtual soc_inf)::set(null, "*", "vif", vif);
      run_test("timer_test");
   end
endmodule // timer_top_tb
