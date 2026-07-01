`timescale 1ns / 1ps

module top_tb;
  import uvm_pkg::*;
  import soc_pkg::*;
  `include "uvm_macros.svh"

  // ----------------------------------------------------------------
  // Clock & reset come from clk_rst_inf — it drives clk and rstn
  // internally via its own initial blocks. No standalone drivers here.
  // FIX: removed duplicate clk/rstn logic — would cause multi-driver
  // ----------------------------------------------------------------
  logic clk_wire, rstn_wire;
  clk_rst_inf cr_if (
      .clk (clk_wire),
      .rstn(rstn_wire)
  );
  soc_inf s_if (
      .clk (cr_if.clk),
      .rstn(cr_if.rstn)
  );
  cpu_monitor_inf cpu_if (
      .clk (cr_if.clk),
      .rstn(cr_if.rstn)
  );

  // ----------------------------------------------------------------
  // DUT
  // ----------------------------------------------------------------
  TOP dut (
      .clk     (cr_if.clk),
      .rstn    (cr_if.rstn),
      .uart_tx (s_if.uart_tx),
      .uart_rx (s_if.uart_rx),
      .spi_sck (s_if.spi_sck),
      .spi_mosi(s_if.spi_mosi),
      .spi_miso(s_if.spi_miso),
      .spi_cs_n(s_if.spi_cs_n)
  );

  axi4_lite_sva axi_sva (
      .clk    (cr_if.clk),
      .rstn   (cr_if.rstn),
      .awaddr (s_if.awaddr),
      .awprot (s_if.awprot),
      .awvalid(s_if.awvalid),
      .awready(s_if.awready),
      .wdata  (s_if.wdata),
      .wstrb  (s_if.wstrb),
      .wvalid (s_if.wvalid),
      .wready (s_if.wready),
      .bresp  (s_if.bresp),
      .bvalid (s_if.bvalid),
      .bready (s_if.bready),
      .araddr (s_if.araddr),
      .arprot (s_if.arprot),
      .arvalid(s_if.arvalid),
      .arready(s_if.arready),
      .rdata  (s_if.rdata),
      .rresp  (s_if.rresp),
      .rvalid (s_if.rvalid),
      .rready (s_if.rready)
  );

  logic cpu_sva_global_en = 1'b0;
  logic cpu_sva_en_instrF, cpu_sva_en_instrD;
  logic [31:0] cpu_sva_last_pc;
  int unsigned cpu_instr_count;
  logic [31:0] cpu_end_pc;
  assign cpu_sva_last_pc = (cpu_end_pc >= 32'd4) ? (cpu_end_pc - 32'd4) : 32'd0;
  initial begin
    cpu_sva_global_en = !$test$plusargs("UVM_MASTER");

    if (!$value$plusargs("CPU_INSTR_COUNT=%d", cpu_instr_count)) cpu_instr_count = 0;

    cpu_end_pc = cpu_instr_count * 4;
  end

  assign cpu_sva_en_instrF = cpu_sva_global_en &&
                              ((cpu_instr_count == 0) ? 1'b1 : (cpu_if.PcF <= cpu_sva_last_pc));
  assign cpu_sva_en_instrD = cpu_sva_global_en &&
                              ((cpu_instr_count == 0) ? 1'b1 : (cpu_if.PcD <= cpu_sva_last_pc));


  cpu_sva cpu_sva (
      .clk (cr_if.clk),
      .rstn(cr_if.rstn),

      .PcF(cpu_if.PcF),
      .InstrF(cpu_if.InstrF),
      .InstrD(cpu_if.InstrD),
      .PcD(cpu_if.PcD),

      .StallF(cpu_if.StallF),
      .FlushE(cpu_if.FlushE),
      .mem_stall_i(cpu_if.mem_stall_i),

      .ForwardA(cpu_if.ForwardA),
      .ForwardB(cpu_if.ForwardB),

      .sva_en_InstrF(cpu_sva_en_instrF),
      .sva_en_InstrD(cpu_sva_en_instrD)
  );

  // ---- Fetch ----
  assign cpu_if.PcF         = dut.axi_master.cpu.PcF;
  assign cpu_if.InstrF      = dut.axi_master.cpu.InstrF;
  // ---- Decode ----
  assign cpu_if.InstrD      = dut.axi_master.cpu.InstrD;
  assign cpu_if.PcD         = dut.axi_master.cpu.PcD;
  assign cpu_if.Rs1D        = dut.axi_master.cpu.Rs1D;
  assign cpu_if.Rs2D        = dut.axi_master.cpu.Rs2D;
  assign cpu_if.RdD         = dut.axi_master.cpu.RdD;
  // ---- Execute ----
  assign cpu_if.ALUResultE  = dut.axi_master.cpu.ALUResultE;
  assign cpu_if.RdE         = dut.axi_master.cpu.RdE;
  assign cpu_if.ForwardA    = dut.axi_master.cpu.ForwardA;
  assign cpu_if.ForwardB    = dut.axi_master.cpu.ForwardB;
  assign cpu_if.PCSrc       = dut.axi_master.cpu.PCSrc;
  // ---- Memory ----
  assign cpu_if.ALUResultM  = dut.axi_master.cpu.ALUResultM;
  assign cpu_if.WriteDataM  = dut.axi_master.cpu.WriteDataM;
  assign cpu_if.MemWriteM   = dut.axi_master.cpu.MemWriteM;
  assign cpu_if.RdM         = dut.axi_master.cpu.RdM;
  // ---- Writeback ----
  assign cpu_if.RegWriteW   = dut.axi_master.cpu.RegWriteW;
  assign cpu_if.RdW         = dut.axi_master.cpu.RdW;
  assign cpu_if.ResultW     = dut.axi_master.cpu.ResultW;
  // ---- Hazard ----
  assign cpu_if.StallF      = dut.axi_master.cpu.StallF;
  assign cpu_if.FlushE      = dut.axi_master.cpu.FlushE;
  assign cpu_if.mem_stall_i = dut.axi_master.cpu.mem_stall_i;

  // ----------------------------------------------------------------
  // SINGLE initial block — fixes the race condition
  // ----------------------------------------------------------------
  bit use_uvm_master;

  initial begin
    use_uvm_master = $test$plusargs("UVM_MASTER") ? 1 : 0;

    if (use_uvm_master) $display("[TB] Mode: UVM MASTER => driver controls AXI bus");
    else $display("[TB] Mode: CPU MASTER => CPU drives AXI, UVM observes");

    if (use_uvm_master) begin
      force dut.m_axi_awaddr = s_if.awaddr;
      force dut.m_axi_awprot = s_if.awprot;
      force dut.m_axi_awvalid = s_if.awvalid;
      force dut.m_axi_wdata = s_if.wdata;
      force dut.m_axi_wstrb = s_if.wstrb;
      force dut.m_axi_wvalid = s_if.wvalid;
      force dut.m_axi_araddr = s_if.araddr;
      force dut.m_axi_arprot = s_if.arprot;
      force dut.m_axi_arvalid = s_if.arvalid;
      force dut.m_axi_bready = s_if.bready;
      force dut.m_axi_rready = s_if.rready;
      force s_if.awready = dut.m_axi_awready;
      force s_if.wready = dut.m_axi_wready;
      force s_if.arready = dut.m_axi_arready;
      force s_if.bvalid = dut.m_axi_bvalid;
      force s_if.bresp = dut.m_axi_bresp;
      force s_if.rvalid = dut.m_axi_rvalid;
      force s_if.rdata = dut.m_axi_rdata;
      force s_if.rresp = dut.m_axi_rresp;
    end else begin
      force s_if.awaddr = dut.m_axi_awaddr;
      force s_if.awprot = dut.m_axi_awprot;
      force s_if.awvalid = dut.m_axi_awvalid;
      force s_if.awready = dut.m_axi_awready;
      force s_if.wdata = dut.m_axi_wdata;
      force s_if.wstrb = dut.m_axi_wstrb;
      force s_if.wvalid = dut.m_axi_wvalid;
      force s_if.wready = dut.m_axi_wready;
      force s_if.bresp = dut.m_axi_bresp;
      force s_if.bvalid = dut.m_axi_bvalid;
      force s_if.bready = dut.m_axi_bready;
      force s_if.araddr = dut.m_axi_araddr;
      force s_if.arprot = dut.m_axi_arprot;
      force s_if.arvalid = dut.m_axi_arvalid;
      force s_if.arready = dut.m_axi_arready;
      force s_if.rdata = dut.m_axi_rdata;
      force s_if.rvalid = dut.m_axi_rvalid;
      force s_if.rready = dut.m_axi_rready;
      force s_if.rresp = dut.m_axi_rresp;
    end

    uvm_config_db#(virtual clk_rst_inf)::set(null, "*", "vif_cr", cr_if);
    uvm_config_db#(virtual soc_inf)::set(null, "*", "vif_soc", s_if);
    uvm_config_db#(virtual cpu_monitor_inf)::set(null, "*", "cpu_vif", cpu_if);

    run_test();
  end

endmodule
