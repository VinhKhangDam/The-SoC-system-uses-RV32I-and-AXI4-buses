module Timer (
	input logic clk,
	input logic rstn,

	// AXI-Slaves signals
	// Write address signals
	input logic [31:0] 	s_axi_awaddr,
	input logic [2:0]  	s_axi_awprot,
	input logic 	   	s_axi_awvalid,
	output logic 	   	s_axi_awready,
	// Write Data signals
	input logic [31:0] 	s_axi_wdata,
	input logic [3:0]  	s_axi_wstrb,
	input logic 	   	s_axi_wvalid,
	output logic 	   	s_axi_wready,
	// Response signals
	output logic 	   	s_axi_bvalid,
	output logic [1:0] 	s_axi_bresp,
	input logic 		s_axi_bready,
	// Read address signals
	input logic [31:0] 	s_axi_araddr,
	input logic [2:0]	s_axi_arprot,
	input logic 		s_axi_arvalid,
	output logic 		s_axi_arready,
	// Read data signals
	input logic 		s_axi_rready,
	output logic 		s_axi_rvalid,
	output logic [1:0] 	s_axi_rresp,
	output logic [31:0] 	s_axi_rdata,

	// Other signals
	output logic irq
);
	// Internal register
	// Offset 0x0 : CONTROL (CTRL) (bit 0 : ENABLE, bit 1 : InitEN)
	// Offset 0x4 : PERIOD 
	// Offset 0x8 : COUNT
	logic [31:0] 	timer_control;
	logic [31:0] 	timer_period;
	logic [31:0] 	timer_count;
	logic 		write_allowed;

	// Write address hanshake logic 
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			s_axi_awready <= '0;
			write_allowed <= '0;
		end else begin
			if (!s_axi_awready && s_axi_awvalid ) begin
				if (s_axi_awprot[0] == 1) begin
					s_axi_awready <= 1'b1;
					write_allowed <= 1'b1;
				end else begin
					s_axi_awready <= 1'b1;
					write_allowed <= 1'b0;
				end
			end else begin
				s_axi_awready <= 1'b0;
			end
		end
	end

	// Write data hanshake logic
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			s_axi_wready	<= '0;
			timer_control 	<= '0;
			timer_period	<= '0;
		end else begin
			if (!s_axi_wready && s_axi_wvalid && s_axi_awvalid) begin
				s_axi_wready <= 1'b1;
				if (write_allowed) begin
					case (s_axi_awaddr[3:0]) 
						4'd0: timer_control <= s_axi_wdata;
						4'd4: timer_period  <= s_axi_wdata;
						default: ;
					endcase
				end
			end else begin
				s_axi_wready <= '0;
			end
		end
	end

	// Write response handshake logic
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			s_axi_bvalid <= '0;
			s_axi_bresp  <= '0;
		end else begin
			if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
				s_axi_bvalid <= '1;
				s_axi_bresp <= (write_allowed) ? 2'b00 : 2'b10; // SLVERR
			end else if (s_axi_bready && s_axi_bvalid) begin
				s_axi_bvalid <= '0;
			end
		end
	end

	// Read address hanshake logic
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			s_axi_arready <= '0;
			s_axi_rdata   <= '0;
		end else begin
			if (!s_axi_arready && s_axi_arvalid) begin
				s_axi_arready <= 1'b1;
				case (s_axi_araddr[3:0])
					4'd0: s_axi_rdata <= timer_control;
					4'd4: s_axi_rdata <= timer_period;
					4'd8: s_axi_rdata <= timer_count;
					default: s_axi_rdata <= 32'hDEAD_BEEF;
				endcase
			end else begin
				s_axi_arready <= '0;
			end
		end
	end

	// Read data hanshake logic
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			s_axi_rvalid <= '0;
			s_axi_rresp  <= '0;
		end else begin
			if (s_axi_arready && s_axi_arvalid) begin
				s_axi_rvalid <= '1;
				s_axi_rresp <= '0;
			end else if (s_axi_rready && s_axi_rvalid) begin
				s_axi_rvalid <= '0;
			end
		end
	end

	// Counter logic
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			timer_count <= '0;
			irq	      <= '0;
		end else begin
			if (timer_control[0] == 0) begin // ENABLE
				if (timer_count >= timer_period && timer_period != '0) begin
					timer_count <= '0;
					irq	    <= 1'b1;
				end else begin
					timer_count <= timer_count + 1;
					irq	    <= 1'b0;
				end
			end else begin
				timer_count <= '0;
				irq 	    <= '0;
			end
		end
	end
endmodule
