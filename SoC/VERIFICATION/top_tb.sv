`timescale 1ns/1ps

module top_tb;
    import uvm_pkg::*;
    import soc_pkg::*;
    `include "uvm_macros.svh"

    logic clk;
    logic rstn;

    clk_rst_inf cr_if (
        .clk(clk), 
        .rstn(rstn)
    );
    soc_inf s_if (
        .clk(clk), 
        .rstn(rstn)
    );

    TOP dut (
        .clk(clk),
        .rstn(rstn),
        .uart_tx(s_if.uart_tx),
        .uart_rx(s_if.uart_rx),
        .spi_sck(s_if.spi_sck),
        .spi_mosi(s_if.spi_mosi),
        .spi_miso(s_if.spi_miso),
        .spi_cs_n(s_if.spi_cs_n)
    );

    initial begin
        // Force DUT master inputs from interface (driver -> DUT)
        force dut.m_axi_awaddr  = s_if.awaddr;
        force dut.m_axi_awvalid = s_if.awvalid;
        force dut.m_axi_wdata   = s_if.wdata;
        force dut.m_axi_wstrb   = s_if.wstrb;
        force dut.m_axi_wvalid  = s_if.wvalid;
        force dut.m_axi_araddr  = s_if.araddr;
        force dut.m_axi_arvalid = s_if.arvalid;
        force dut.m_axi_bready  = s_if.bready;
        force dut.m_axi_rready  = s_if.rready;
 
        // Force DUT outputs back into interface (DUT -> monitor/driver inputs)
        force s_if.awready = dut.m_axi_awready;
        force s_if.wready  = dut.m_axi_wready;
        force s_if.arready = dut.m_axi_arready;
        force s_if.bvalid  = dut.m_axi_bvalid;
        force s_if.bresp   = dut.m_axi_bresp;
        force s_if.rvalid  = dut.m_axi_rvalid;
        force s_if.rdata   = dut.m_axi_rdata;
        force s_if.rresp   = dut.m_axi_rresp;
    end

    initial begin
        uvm_config_db #(virtual clk_rst_inf)::set(null,"*", "vif_cr", cr_if); 
        uvm_config_db#(virtual soc_inf)::set(null, "*", "vif_soc", s_if);
        run_test();
    end

    initial begin
        $display("Da nap instr.mem vao top tb");
        $readmemh("instr.mem", dut.IRAM.mem);
    end

endmodule