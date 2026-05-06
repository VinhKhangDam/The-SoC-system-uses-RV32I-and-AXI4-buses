module AXI_Master (
    input logic clk, 
    input logic rstn,

    // AXI4-Lite Master Port (to Interconnect)
    output logic [31:0] m_axi_awaddr,
    output logic [2:0]  m_axi_awprot,
    output logic        m_axi_awvalid,
    input  logic        m_axi_awready,

    output logic [31:0] m_axi_wdata,
    output logic [3:0]  m_axi_wstrb,
    output logic        m_axi_wvalid,
    input  logic        m_axi_wready,

    input  logic [1:0]  m_axi_bresp,
    input  logic        m_axi_bvalid,
    output logic        m_axi_bready,

    output logic [31:0] m_axi_araddr,
    output logic [2:0]  m_axi_arprot,
    output logic        m_axi_arvalid,
    input  logic        m_axi_arready,

    input  logic [31:0] m_axi_rdata,
    input  logic [1:0]  m_axi_rresp,
    input  logic        m_axi_rvalid,
    output logic        m_axi_rready
);

    // ----------------------------------------------------------------
    // Internal wires between CPU and LSU
    // ----------------------------------------------------------------

    // DATA channel (load/store)
    logic [31:0] cpu_addr, cpu_wdata, lsu_rdata;
    logic        cpu_we, cpu_req, lsu_stall;
    logic [2:0]  cpu_funct3;

    // IF channel (instruction fetch) -- NEW
    logic [31:0] cpu_if_pc;
    logic        cpu_if_req;
    logic [31:0] lsu_if_instr;
    logic        lsu_if_stall;

    // ----------------------------------------------------------------
    // CPU instance
    // ----------------------------------------------------------------
    CPU cpu (
        .clk         (clk),
        .rstn        (rstn),
        // DATA channel
        .mem_addr_o  (cpu_addr),
        .mem_wdata_o (cpu_wdata),
        .mem_we_o    (cpu_we),
        .mem_req_o   (cpu_req),
        .mem_funct_o (cpu_funct3),
        .mem_rdata_i (lsu_rdata),
        .mem_stall_i (lsu_stall),
        // IF channel
        .if_pc_o     (cpu_if_pc),
        .if_req_o    (cpu_if_req),
        .if_instr_i  (lsu_if_instr),
        .if_stall_i  (lsu_if_stall)
    );

    // ----------------------------------------------------------------
    // LSU instance — now handles both IF fetch and DATA load/store
    // ----------------------------------------------------------------
    LSU lsu (
        .clk          (clk),
        .rstn         (rstn),
        // IF channel
        .if_pc_i      (cpu_if_pc),
        .if_req_i     (cpu_if_req),
        .if_instr_o   (lsu_if_instr),
        .if_stall_o   (lsu_if_stall),
        // DATA channel
        .addr_i       (cpu_addr),
        .data_i       (cpu_wdata),
        .we_i         (cpu_we),
        .req_i        (cpu_req),
        .funct3       (cpu_funct3),
        .lsu_rdata_o  (lsu_rdata),
        .lsu_stall_o  (lsu_stall),
        // AXI port (shared)
        .m_axi_awaddr (m_axi_awaddr),
        .m_axi_awprot (m_axi_awprot),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),
        .m_axi_wdata  (m_axi_wdata),
        .m_axi_wstrb  (m_axi_wstrb),
        .m_axi_wvalid (m_axi_wvalid),
        .m_axi_wready (m_axi_wready),
        .m_axi_bresp  (m_axi_bresp),
        .m_axi_bvalid (m_axi_bvalid),
        .m_axi_bready (m_axi_bready),
        .m_axi_araddr (m_axi_araddr),
        .m_axi_arprot (m_axi_arprot),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),
        .m_axi_rdata  (m_axi_rdata),
        .m_axi_rresp  (m_axi_rresp),
        .m_axi_rvalid (m_axi_rvalid),
        .m_axi_rready (m_axi_rready)
    );

endmodule