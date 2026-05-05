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
	logic [31:0] 	timer_control;
	logic [31:0] 	timer_period;
	logic [31:0] 	timer_count;
	logic [31:0]    latched_awaddr;
	logic           aw_received;  // Flag indicating address has been received
	
	// Write address handshake - latch address until write data completes
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			s_axi_awready  <= 1'b0;
			latched_awaddr <= '0;
			aw_received    <= 1'b0;
		end else begin
			if (s_axi_awvalid && !aw_received) begin
				// Accept address immediately
				s_axi_awready  <= 1'b1;
				latched_awaddr <= s_axi_awaddr;
				aw_received    <= 1'b1;
			end else begin
				s_axi_awready <= 1'b0;
				// Clear flag when write completes
				if (s_axi_wvalid && s_axi_wready) begin
					aw_received <= 1'b0;
				end
			end
		end
	end
	
	// Write data handshake - wait for address to be received first
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			s_axi_wready   <= '0;
			timer_control  <= '0;
			timer_period   <= '0;
		end else begin
			if (s_axi_wvalid && aw_received && !s_axi_wready) begin
				// Accept data and write to register
				s_axi_wready <= 1'b1;
				case (latched_awaddr[3:0]) 
					4'd0: timer_control <= s_axi_wdata;
					4'd4: timer_period  <= s_axi_wdata;
					default: ;
				endcase
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
			if (s_axi_wready && s_axi_wvalid && !s_axi_bvalid) begin
				s_axi_bvalid <= '1;
				s_axi_bresp  <= 2'b00;
			end else if (s_axi_bready && s_axi_bvalid) begin
				s_axi_bvalid <= '0;
			end
		end
	end
	
	// Read address handshake logic
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
	
	// Read data handshake logic
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			s_axi_rvalid <= '0;
			s_axi_rresp  <= '0;
		end else begin
			if (s_axi_arready && s_axi_arvalid) begin
				s_axi_rvalid <= '1;
				s_axi_rresp  <= '0;
			end else if (s_axi_rready && s_axi_rvalid) begin
				s_axi_rvalid <= '0;
			end
		end
	end
	
	// Counter logic
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			timer_count <= '0;
			irq         <= '0;
		end else begin
			if (timer_control[0] == 1'b1) begin
				if (timer_period != '0 && timer_count >= timer_period) begin
					timer_count <= '0;
					irq         <= 1'b1;
				end else begin
					timer_count <= timer_count + 1;
					irq         <= 1'b0;
				end
			end else begin
				timer_count <= '0;
				irq         <= '0;
			end
		end
	end
endmodule