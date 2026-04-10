module SPI (
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
	
	// SPI physical interface
	output logic 		spi_sck,
	output logic 		spi_mosi,
	input logic 		spi_miso,
	output logic 		spi_cs_n // CHIP SELECT (ACTIVE LOW)
);

	// REGISTER MAP
	// 0x0 : SPI_DATA (R/W) - TRANSMIT/RECEIVE DATA
	// 0x4 : SPI_CONTROL (R/W) - BIT 0 : START, BIT 3 : CS (MANUAL CONTROL)
	// 0x8 : SPI_STATUS (RO) - BIT 0 : BUSY
	// 0xC : SPI_BAUD (R/W)
	logic [7:0] spi_tx_reg, spi_rx_reg;
	logic [31:0] spi_baud_reg;
	logic [31:0] spi_ctrl_reg;
	logic spi_start, spi_busy;

	// Write Logic
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin	
		s_axi_awready <= '0;
		s_axi_wready  <= '0;
		s_axi_bvalid  <= '0;
		spi_tx_reg    <= '0;
		spi_ctrl_reg  <= 32'h0000_0008; // DEFAULT : CS_N = 1 (DON'T SELECT SLAVES)
		spi_baud_reg  <= 32'd10;	// DEFAULT : DIVIDE INTO 10
		spi_start     <= '0;
		end else begin
			if (!s_axi_awready && s_axi_awvalid && s_axi_wvalid) begin
				s_axi_awready <= '1;
				s_axi_wready  <= '1;
				spi_start     <= '0;
				case (s_axi_awaddr[3:0]) 
					4'h0 : spi_tx_reg <= s_axi_wdata[7:0];
					4'h4 : begin
						spi_ctrl_reg <= s_axi_wdata;
						spi_start    <= s_axi_wdata[0]; // ACTIVE TRANSMIT IF BIT 0 EQUAL TO 1
					end
					4'hC : spi_baud_reg  <= s_axi_wdata;
				endcase
			end else begin
				s_axi_awready <= '0;
				s_axi_wready  <= '0;
				spi_start     <= '0;
			end

			if (s_axi_awready && s_axi_wready) s_axi_bvalid <= '1;
			else if (s_axi_bready) s_axi_bvalid <= '0;
		end
	end

	assign s_axi_bresp = '0;
	assign spi_cs_n = spi_ctrl_reg[3]; // CPU CONTROL CS PORT

	// READ LOGIC
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			s_axi_arready <= '0;
			s_axi_rvalid  <= '0;
		end else begin
			if (!s_axi_arready && s_axi_arvalid) begin
				s_axi_arready <= '1;
				case (s_axi_araddr[3:0]) 
					4'h0 : s_axi_rdata <= {24'h0, spi_rx_reg};
					4'h4 : s_axi_rdata <= spi_ctrl_reg;
					4'h8 : s_axi_rdata <= {31'h0, spi_busy};
					4'hC : s_axi_rdata <= spi_baud_reg;
					default : s_axi_rdata <= 32'h0;
				endcase
			end else begin
				s_axi_arready <= '0;
			end

			if (s_axi_arready) s_axi_rvalid <= '1;
			else if (s_axi_rready) s_axi_rvalid <= '0;
		end
	end

	assign s_axi_rresp = 2'b00;

	// SPI MASTER ENGINE
	typedef enum logic [1:0] {IDLE, TRANSFER, DONE} spi_state_t;
	spi_state_t spi_state;
	logic [31:0] baud_count;
	logic [3:0] bit_count;
	logic [7:0] shift_reg;
	logic sck_internal;

	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			spi_state 	<= IDLE;
			spi_busy 	<= '0;
			sck_internal 	<= '0;
			spi_mosi  	<= '0;
			baud_count 	<= '0;
			bit_count 	<= '0;
		end else begin
			case (spi_state)
				IDLE : begin
					if (spi_start) begin
						spi_state 	<= TRANSFER;
						spi_busy  	<= '1;
						shift_reg 	<= spi_tx_reg;
						bit_count 	<= 0;
						baud_count 	<= 0;
						sck_internal 	<= 1'b0; // CPOL = 0
					end else begin
						spi_busy	<= '0;
					end
				end

				TRANSFER : begin
					if (baud_count < (spi_baud_reg)) begin
						baud_count <= baud_count + 1;
					end else begin
						baud_count <= '0;
						sck_internal <= ~sck_internal;
						
						// LEADING EDGE - MODE
						// 0 : PUSH DATA OUT OF MOSI
						if (!sck_internal) begin
							spi_mosi <= shift_reg[7];
						end

						// TRAILING EDGE : SAMPLING
						// DATA FROM MISO
						else begin
							shift_reg <= {shift_reg[6:0], spi_miso};
							if (bit_count == 7) begin
								spi_state <= DONE;
							end else begin
								bit_count <= bit_count + 1;
							end
						end
					end
				end

				DONE : begin
					spi_rx_reg <= shift_reg;
					spi_busy   <= '0;
					spi_state  <= IDLE;
				end
			endcase
		end
	end
	
	assign spi_sck = sck_internal;

endmodule
