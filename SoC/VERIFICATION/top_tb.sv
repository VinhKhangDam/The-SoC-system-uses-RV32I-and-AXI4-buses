`timescale 1ns/1ps

module top_tb;
    import uvm_pkg::*;
    import soc_pkg::*;
    `include "uvm_macros.svh"

    logic clk;
    logic rstn;
    bit   en_cpu_mode = 0; // FLAG: 0 = UVM Test Slaves, 1 = CPU chạy App

    clk_rst_inf cr_if (.clk(clk), .rstn(rstn));
    soc_if s_if (.clk(clk), .rstn(rstn));

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
        forever begin
            @(en_cpu_mode);
            if (en_cpu_mode == 0) begin
                `uvm_info("MODE", "UVM MASTER ACTIVE", UVM_LOW)
                force dut.axi_master.rstn = 1'b0; 

                force dut.m_axi_awaddr  = s_if.awaddr;
                force dut.m_axi_awvalid = s_if.awvalid;
                force dut.m_axi_wdata   = s_if.wdata;
                force dut.m_axi_wvalid  = s_if.wvalid;
                force dut.m_axi_araddr  = s_if.araddr;
                force dut.m_axi_arvalid = s_if.arvalid;
                force dut.m_axi_bready  = s_if.bready;
                force dut.m_axi_rready  = s_if.rready;
            end else begin
                `uvm_info("MODE", "CPU MASTER ACTIVE", UVM_LOW)
                release dut.axi_master.rstn;
                release dut.m_axi_awaddr;
                release dut.m_axi_awvalid;
                release dut.m_axi_wdata;
                release dut.m_axi_wvalid;
                release dut.m_axi_araddr;
                release dut.m_axi_arvalid;
                release dut.m_axi_bready;
                release dut.m_axi_rready;
            end
        end
    end

    assign s_if.awready = (en_cpu_mode == 0) ? dut.m_axi_awready : 1'bz;
    assign s_if.wready  = (en_cpu_mode == 0) ? dut.m_axi_wready  : 1'bz;
    assign s_if.arready = (en_cpu_mode == 0) ? dut.m_axi_arready : 1'bz;
    assign s_if.bvalid  = (en_cpu_mode == 0) ? dut.m_axi_bvalid  : 1'bz;
    assign s_if.rvalid  = (en_cpu_mode == 0) ? dut.m_axi_rvalid  : 1'bz;
    assign s_if.rdata   = (en_cpu_mode == 0) ? dut.m_axi_rdata   : 32'hz;

    initial begin
        en_cpu_mode = 0;
        uvm_config_db#(virtual soc_if)::set(null, "*", "vif_soc", s_if);
        run_test();
    end

    initial begin
        $readmemh("/home/khang/Documents/SystemVerilog/SoC-RV32I/SoC/SIM/instr.mem", dut.IRAM.mem);
    end

endmodule