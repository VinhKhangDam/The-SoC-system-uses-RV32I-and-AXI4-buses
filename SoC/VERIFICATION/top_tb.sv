`timescale 1ns/1ps

module top_tb;
    // 1. Import thu vien UVM
    import uvm_pkg::*;
    import soc_pkg::*;
    `include "uvm_macros.svh"

    // 2. Khai bao cac tin hieu ket noi co ban
    logic clk;
    logic rst;

    // 3. Khoi tao Interface tao xung (Clock & Reset)
    // Gia su HALF_CLK = 5 (chu ky 10ns = 100MHz)
    clk_rst_inf cr_if (
        .clk(clk),
        .rstn(rstn)
    );

    // 4. Khoi tao Interface giam sat SoC
    soc_if s_if (
        .clk(clk),
        .rstn(rstn)
    );

    // 5. KET NOI SoC (DUT)
    // Nối các chân vật lý vào interface s_if
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

    // 6. KET NOI TIN HIEU NOI BO (Internal AXI)
    // Vi cac tin hieu m_axi_... nam ben trong module TOP, 
    // ta dung phep gan de Monitor co the soi thay.
    assign s_if.awaddr  = dut.m_axi_awaddr;
    assign s_if.awvalid = dut.m_axi_awvalid;
    assign s_if.awready = dut.m_axi_awready;
    assign s_if.wdata   = dut.m_axi_wdata;
    assign s_if.wstrb   = dut.m_axi_wstrb;
    assign s_if.wvalid  = dut.m_axi_wvalid;
    assign s_if.wready  = dut.m_axi_wready;
    assign s_if.bresp   = dut.m_axi_bresp;
    assign s_if.bvalid  = dut.m_axi_bvalid;
    assign s_if.bready  = dut.m_axi_bready;
    assign s_if.araddr  = dut.m_axi_araddr;
    assign s_if.arvalid = dut.m_axi_arvalid;
    assign s_if.arready = dut.m_axi_arready;
    assign s_if.rdata   = dut.m_axi_rdata;
    assign s_if.rresp   = dut.m_axi_rresp;
    assign s_if.rvalid  = dut.m_axi_rvalid;
    assign s_if.rready  = dut.m_axi_rready;

    // 7. KHOI CHAY UVM
    initial begin
        // Dua interface vao kho du lieu UVM Config DB
        // Driver va Monitor se "lay" vif_soc nay ra de xai
        uvm_config_db#(virtual soc_if)::set(null, "*", "vif_soc", s_if);
        
        // Tuy chon: Bat log chi tiet
        uvm_top.set_report_verbosity_level(UVM_HIGH);

        // Goi ten test tu dong qua command line (+UVM_TESTNAME)
        run_test();
    end

    // 8. (Tuy chon) Nap file mem vao IRAM bang Backdoor
    // Giúp CPU có code để chạy ngay khi vừa reset xong
    initial begin
        $readmemh("/home/khang/Documents/SystemVerilog/SoC-RV32I/SoC/SIM/instr.mem", dut.IRAM.mem);
    end

endmodule
