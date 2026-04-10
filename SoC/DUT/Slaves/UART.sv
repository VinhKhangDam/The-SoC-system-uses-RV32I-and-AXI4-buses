module UART (
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
	
	// UART Physical Interface
	output logic 		uart_tx,
	input logic 		uart_rx
);
	// Register map & internal register
	// 0x0 : UART_TXDATA (Write only)
	// 0x4 : UART_RXDATA (Read only)
	// 0x8 : UART_STATUS (BIT_0 : TX_BUSY,BIT_1 ; RX_READY)
	// 0xC : UART_BAUD   (Divider value)
	logic [31:0] uart_baud;
	logic [7:0] uart_tx_reg, uart_rx_reg;
	logic uart_tx_busy, uart_tx_start, uart_rx_ready, uart_rx_clear;

	// Write logic
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			s_axi_awready <= '0;
			s_axi_wready  <= '0;
			s_axi_bvalid  <= '0;
			uart_tx_start <= '0;
			uart_baud     <= 32'd434; // Default 115200 @ 50MHz
		end else begin
			if (!s_axi_awready && s_axi_awvalid && s_axi_wvalid) begin
				s_axi_awready <= '1;
				s_axi_wready  <= '1;
				case (s_axi_awaddr[3:0])
					4'h0: begin
						uart_tx_reg <= s_axi_wdata[7:0];
						uart_tx_start <= 1'b1;
					end
					4'hC: uart_baud <= s_axi_wdata;
				endcase
			end else begin
				s_axi_awready <= '0;
				s_axi_wready  <= '0;
				uart_tx_start <= '0;
			end

			if (s_axi_awready && s_axi_wready) s_axi_bvalid <= '1;
			else if (s_axi_bready) s_axi_bvalid <= '0;
		end
	end

	assign s_axi_bresp = 2'b00;

	// Read logic
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			s_axi_arready <= '0;
			s_axi_rvalid  <= '0;
			uart_rx_clear <= '0;
		end else begin
			if (!s_axi_arready && s_axi_arvalid) begin
				s_axi_arready <= '1;
				case (s_axi_araddr[3:0]) 
					4'h4 : begin
						s_axi_rdata <= {24'd0, uart_rx_reg};
						uart_rx_clear <= 1'b1;
					end
					4'h8 : s_axi_rdata <= {30'd0, uart_rx_ready, uart_tx_busy};
				        4'hC : s_axi_rdata <= uart_baud;
					default: s_axi_rdata <= 32'h0;	
				endcase
			end else begin
				s_axi_arready <= '0;
				uart_rx_clear <= '0;
			end

			if (s_axi_arready) s_axi_rvalid <= 1'b1;
			else if (s_axi_rready) s_axi_rvalid <= '0;
		end
	end
	
	assign s_axi_rresp = 2'b00;

	// UART TX ENGINE
	enum logic [1:0] {TX_IDLE, TX_START, TX_DATA, TX_STOP} tx_state;
	logic [31:0] uart_tx_count;
	logic [2:0] tx_bit_idx;
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			tx_state <= TX_IDLE;
			uart_tx  <= '0;
			uart_tx_busy  <= '0;
		end else begin
			case (tx_state) 
				TX_IDLE : begin
					if (uart_tx_start) begin
						tx_state <= TX_START;
						uart_tx_busy <= 1'b1;
						uart_tx_count <= '0;
					end else uart_tx_busy <= 1'b0;
				end

				TX_START : begin
					uart_tx <= 1'b0;
					if (uart_tx_count < uart_baud) uart_tx_count <= uart_tx_count + 1;
					else begin
						uart_tx_count <= '0;
						tx_state <= TX_START;
						tx_bit_idx <= '0;
					end
				end

				TX_DATA : begin
					uart_tx <= uart_tx_reg[tx_bit_idx];
					if (uart_tx_count < uart_baud) uart_tx_count <= uart_tx_count + 1;
					else begin
						uart_tx_count <= '0;
						if (tx_bit_idx < 7) tx_bit_idx <= tx_bit_idx + 1;
						else tx_state <= TX_STOP;
					end
				end
				
				TX_STOP : begin
					uart_tx <= 1'b1;
					if (uart_tx_count < uart_baud) uart_tx_count <= uart_tx_count + 1;
					else tx_state <= TX_IDLE;
				end
			endcase
		end
	end

	// UART RX ENGINE
	enum logic [1:0] {RX_IDLE, RX_START, RX_DATA, RX_STOP} rx_state;
	logic [31:0] uart_rx_count;
	logic [2:0] rx_bit_idx;

	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			rx_state <= RX_IDLE;
			uart_rx_ready <= 1'b0;		
		end else begin
			if (uart_rx_clear) uart_rx_ready <= 1'b0;
			case (rx_state) 
				RX_IDLE : begin
					if (!uart_rx) begin
						rx_state <= RX_START;
						uart_rx_count <= '0;
					end
				end

				RX_START : begin
					if (uart_rx_count < (uart_baud >> 1)) uart_rx_count <= uart_rx_count + 1;
					else begin
						uart_rx_count <= '0;
						rx_state <= RX_DATA;
						rx_bit_idx <= '0;
					end
				end

				RX_DATA : begin
					if (uart_rx_count < uart_baud) uart_rx_count <= uart_rx_count + 1;
					else begin
						uart_rx_count <= '0;
						uart_rx_reg[rx_bit_idx] <= uart_rx;
						if (rx_bit_idx < 7) rx_bit_idx <= rx_bit_idx + 1;
						else rx_state <= RX_STOP;
					end	
				end

				RX_STOP : begin
					if (uart_rx_count < uart_baud) uart_rx_count <= uart_rx_count + 1;
					else begin
						uart_rx_ready <= 1'b1;
						rx_state <= RX_IDLE;
					end
				end
			endcase
		end
	end
endmodule
