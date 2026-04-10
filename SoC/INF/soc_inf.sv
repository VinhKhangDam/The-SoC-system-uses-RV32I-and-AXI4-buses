`timescale 1ns/1ps
interface soc_if (input logic clk, rstn);
	// AXI-LITE SIGNALS
	// AW CHANNELS
	logic [31:0] 	awaddr;
	logic [2:0]  	awprot;
	logic 	     	awvalid;
	logic        	awready;
	// W CHANNELS
	logic [31:0] 	wdata;
	logic [3:0]  	wstrb;
	logic        	wvalid;
	logic        	wready;
	// B CHANNELS
	logic [1:0]  	bresp;
	logic        	bvalid;
	logic        	bready;
	// AR CHANNELS
	logic [31:0] 	araddr;
	logic [2:0]  	arprot;
	logic        	arvalid;
	logic        	arready;
	// R CHANNELS
	logic [31:0] 	rdata;
	logic [1:0]  	rresp;
	logic 	     	rvalid;
	logic         	rready;

	// PHYSICAL IO SIGNALS
	logic 		uart_tx;
	logic 		uart_rx;
	logic 		spi_sck;
	logic 		spi_mosi;
	logic 		spi_miso;
	logic 		spi_cs_n;

	clocking drv_cb @(posedge clk);
		default input #1 output #1;
		output awaddr, awprot, awvalid, wdata, wstrb, wvalid, bready;
		output araddr, arprot, arvalid, rready;

		input awready, wready, bresp, bvalid, arready, rdata, rvalid, rresp;
	endclocking
	
	clocking mon_cb @(posedge clk);
		default input #1 output #1;
		input awaddr, awvalid, awready;
		input wdata, wstrb, wvalid, wready;
		input bresp, bvalid, bready;
		input araddr, arvalid, arready;
		input rdata, rresp, rvalid, rready;
		input uart_tx,uart_rx, spi_sck, spi_mosi, spi_miso, spi_cs_n;
	endclocking

	modport DRV (clocking drv_cb, input clk, rstn);
	modport MON (clocking mon_cb, input clk, rstn);
endinterface
