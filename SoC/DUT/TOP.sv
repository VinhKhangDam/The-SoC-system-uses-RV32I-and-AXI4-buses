module TOP (
	input logic clk,
	input logic rstn,

	// PHYSICAL IO
	output logic uart_tx,
	input logic uart_rx,
	output logic spi_sck,
	output logic spi_mosi,
	input logic spi_miso,
	output logic spi_cs_n	
);

	// INTERNAL AXI SIGNAL
	// MASTER SLIDE
	logic [31:0] m_axi_awaddr, m_axi_wdata, m_axi_araddr, m_axi_rdata;
	logic [2:0]  m_axi_awprot, m_axi_arprot;
	logic [3:0]  m_axi_wstrb;
	logic [1:0]  m_axi_bresp, m_axi_rresp;
	logic 	     m_axi_awvalid, m_axi_awready, m_axi_wvalid, m_axi_wready;
	logic        m_axi_bvalid, m_axi_bready;
	logic 	     m_axi_arvalid, m_axi_arready, m_axi_rvalid, m_axi_rready;

	// SLAVE SLIDE
	localparam NUM_SLAVE = 5;
	logic [NUM_SLAVE-1:0][31:0] s_axi_awaddr, s_axi_wdata, s_axi_araddr, s_axi_rdata;
	logic [NUM_SLAVE-1:0][2:0]  s_axi_awprot, s_axi_arprot;
	logic [NUM_SLAVE-1:0][3:0]  s_axi_wstrb;
	logic [NUM_SLAVE-1:0][1:0]  s_axi_bresp, s_axi_rresp;
	logic [NUM_SLAVE-1:0]       s_axi_awvalid, s_axi_awready, s_axi_wvalid, s_axi_wready;
	logic [NUM_SLAVE-1:0]       s_axi_bvalid, s_axi_bready, s_axi_arvalid, s_axi_arready;
	logic [NUM_SLAVE-1:0]       s_axi_rvalid, s_axi_rready;

	// MASTER
	AXI_Master  axi_master (
		.clk(clk),
		.rstn(rstn),
		.m_axi_awaddr(m_axi_awaddr),
		.m_axi_awprot(m_axi_awprot),
		.m_axi_awvalid(m_axi_awvalid),
		.m_axi_awready(m_axi_awready),
		.m_axi_wdata(m_axi_wdata),
		.m_axi_wstrb(m_axi_wstrb),
		.m_axi_wvalid(m_axi_wvalid),
		.m_axi_wready(m_axi_wready),
		.m_axi_bresp(m_axi_bresp),
		.m_axi_bvalid(m_axi_bvalid),
		.m_axi_bready(m_axi_bready),
		.m_axi_araddr(m_axi_araddr),
		.m_axi_arprot(m_axi_arprot),
		.m_axi_arvalid(m_axi_arvalid),
		.m_axi_arready(m_axi_arready),
		.m_axi_rdata(m_axi_rdata),
		.m_axi_rresp(m_axi_rresp),
		.m_axi_rvalid(m_axi_rvalid),
		.m_axi_rready(m_axi_rready)	
	);

	// AXI4-LITE INTERCONNECT
	AXI4_Lite_Interconnect #(
		.NUM_SLAVES(NUM_SLAVE)	
	) axi4_interconnect (
		.clk(clk),
		.rstn(rstn),
		.m_axi_rready(m_axi_rready),
		.m_axi_rvalid(m_axi_rvalid),
		.m_axi_rresp(m_axi_rresp),
		.m_axi_rdata(m_axi_rdata),
		.m_axi_awaddr(m_axi_awaddr),
		.m_axi_awprot(m_axi_awprot),
		.m_axi_awvalid(m_axi_awvalid),
		.m_axi_awready(m_axi_awready),
		.m_axi_wdata(m_axi_wdata),
		.m_axi_wstrb(m_axi_wstrb),
		.m_axi_wvalid(m_axi_wvalid),
		.m_axi_wready(m_axi_wready),
		.m_axi_bresp(m_axi_bresp),
		.m_axi_bvalid(m_axi_bvalid),
		.m_axi_bready(m_axi_bready),
		.m_axi_araddr(m_axi_araddr),
		.m_axi_arprot(m_axi_arprot),
		.m_axi_arvalid(m_axi_arvalid),
		.m_axi_arready(m_axi_arready),
		.s_axi_awaddr(s_axi_awaddr),
		.s_axi_awprot(s_axi_awprot),
		.s_axi_awvalid(s_axi_awvalid),
		.s_axi_awready(s_axi_awready),
		.s_axi_wdata(s_axi_wdata),
		.s_axi_wstrb(s_axi_wstrb),
		.s_axi_wvalid(s_axi_wvalid),
		.s_axi_wready(s_axi_wready),
		.s_axi_bresp(s_axi_bresp),
		.s_axi_bvalid(s_axi_bvalid),
		.s_axi_bready(s_axi_bready),
		.s_axi_araddr(s_axi_araddr),
		.s_axi_arprot(s_axi_arprot),
		.s_axi_arvalid(s_axi_arvalid),
		.s_axi_arready(s_axi_arready),
		.s_axi_rdata(s_axi_rdata),
		.s_axi_rresp(s_axi_rresp),
		.s_axi_rvalid(s_axi_rvalid),
		.s_axi_rready(s_axi_rready)
	);

	// IRAM & DRAM
	RAM #(.INIT_FILE("instr.mem")) IRAM (
		.clk(clk),
		.rstn(rstn),
		.s_axi_awaddr(s_axi_awaddr[0]),
		.s_axi_awprot(s_axi_awprot[0]),
		.s_axi_awvalid(s_axi_awvalid[0]),
		.s_axi_awready(s_axi_awready[0]),
		.s_axi_wdata(s_axi_wdata[0]),
		.s_axi_wstrb(s_axi_wstrb[0]),
		.s_axi_wvalid(s_axi_wvalid[0]),
		.s_axi_wready(s_axi_wready[0]),
		.s_axi_bvalid(s_axi_bvalid[0]),
		.s_axi_bresp(s_axi_bresp[0]),
		.s_axi_bready(s_axi_bready[0]),
		.s_axi_araddr(s_axi_araddr[0]),
		.s_axi_arprot(s_axi_arprot[0]),
		.s_axi_arvalid(s_axi_arvalid[0]),
		.s_axi_arready(s_axi_arready[0]),
		.s_axi_rready(s_axi_rready[0]),
		.s_axi_rvalid(s_axi_rvalid[0]),
		.s_axi_rresp(s_axi_rresp[0]),
		.s_axi_rdata(s_axi_rdata[0])
	);

	RAM DRAM (
		.clk(clk),
		.rstn(rstn),
		.s_axi_awaddr(s_axi_awaddr[1]),
		.s_axi_awprot(s_axi_awprot[1]),
		.s_axi_awvalid(s_axi_awvalid[1]),
		.s_axi_awready(s_axi_awready[1]),
		.s_axi_wdata(s_axi_wdata[1]),
		.s_axi_wstrb(s_axi_wstrb[1]),
		.s_axi_wvalid(s_axi_wvalid[1]),
		.s_axi_wready(s_axi_wready[1]),
		.s_axi_bvalid(s_axi_bvalid[1]),
		.s_axi_bresp(s_axi_bresp[1]),
		.s_axi_bready(s_axi_bready[1]),
		.s_axi_araddr(s_axi_araddr[1]),
		.s_axi_arprot(s_axi_arprot[1]),
		.s_axi_arvalid(s_axi_arvalid[1]),
		.s_axi_arready(s_axi_arready[1]),
		.s_axi_rready(s_axi_rready[1]),
		.s_axi_rvalid(s_axi_rvalid[1]),
		.s_axi_rresp(s_axi_rresp[1]),
		.s_axi_rdata(s_axi_rdata[1])
	);

	// PERIPHERALS
	Timer timer (
		.clk(clk),
		.rstn(rstn),
		.s_axi_awaddr(s_axi_awaddr[2]),
		.s_axi_awprot(s_axi_awprot[2]),
		.s_axi_awvalid(s_axi_awvalid[2]),
		.s_axi_awready(s_axi_awready[2]),
		.s_axi_wdata(s_axi_wdata[2]),
		.s_axi_wstrb(s_axi_wstrb[2]),
		.s_axi_wvalid(s_axi_wvalid[2]),
		.s_axi_wready(s_axi_wready[2]),
		.s_axi_bvalid(s_axi_bvalid[2]),
		.s_axi_bresp(s_axi_bresp[2]),
		.s_axi_bready(s_axi_bready[2]),
		.s_axi_araddr(s_axi_araddr[2]),
		.s_axi_arprot(s_axi_arprot[2]),
		.s_axi_arvalid(s_axi_arvalid[2]),
		.s_axi_arready(s_axi_arready[2]),
		.s_axi_rready(s_axi_rready[2]),
		.s_axi_rvalid(s_axi_rvalid[2]),
		.s_axi_rresp(s_axi_rresp[2]),
		.s_axi_rdata(s_axi_rdata[2]),
		.irq()
	);

	UART uart (
		.clk(clk),
		.rstn(rstn),
		.s_axi_awaddr(s_axi_awaddr[3]),
		.s_axi_awprot(s_axi_awprot[3]),
		.s_axi_awvalid(s_axi_awvalid[3]),
		.s_axi_awready(s_axi_awready[3]),
		.s_axi_wdata(s_axi_wdata[3]),
		.s_axi_wstrb(s_axi_wstrb[3]),
		.s_axi_wvalid(s_axi_wvalid[3]),
		.s_axi_wready(s_axi_wready[3]),
		.s_axi_bvalid(s_axi_bvalid[3]),
		.s_axi_bresp(s_axi_bresp[3]),
		.s_axi_bready(s_axi_bready[3]),
		.s_axi_araddr(s_axi_araddr[3]),
		.s_axi_arprot(s_axi_arprot[3]),
		.s_axi_arvalid(s_axi_arvalid[3]),
		.s_axi_arready(s_axi_arready[3]),
		.s_axi_rready(s_axi_rready[3]),
		.s_axi_rvalid(s_axi_rvalid[3]),
		.s_axi_rresp(s_axi_rresp[3]),
		.s_axi_rdata(s_axi_rdata[3]),
		.uart_tx(uart_tx),
		.uart_rx(uart_rx)
	);

	SPI spi (
		.clk(clk),
		.rstn(rstn),
		.s_axi_awaddr(s_axi_awaddr[4]),
		.s_axi_awprot(s_axi_awprot[4]),
		.s_axi_awvalid(s_axi_awvalid[4]),
		.s_axi_awready(s_axi_awready[4]),
		.s_axi_wdata(s_axi_wdata[4]),
		.s_axi_wstrb(s_axi_wstrb[4]),
		.s_axi_wvalid(s_axi_wvalid[4]),
		.s_axi_wready(s_axi_wready[4]),
		.s_axi_bvalid(s_axi_bvalid[4]),
		.s_axi_bresp(s_axi_bresp[4]),
		.s_axi_bready(s_axi_bready[4]),
		.s_axi_araddr(s_axi_araddr[4]),
		.s_axi_arprot(s_axi_arprot[4]),
		.s_axi_arvalid(s_axi_arvalid[4]),
		.s_axi_arready(s_axi_arready[4]),
		.s_axi_rready(s_axi_rready[4]),
		.s_axi_rvalid(s_axi_rvalid[4]),
		.s_axi_rresp(s_axi_rresp[4]),
		.s_axi_rdata(s_axi_rdata[4]),
		.spi_sck(spi_sck),
		.spi_mosi(spi_mosi),
		.spi_miso(spi_miso),
		.spi_cs_n(spi_cs_n)
	);

endmodule
