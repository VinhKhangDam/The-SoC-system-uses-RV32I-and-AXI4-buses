class axi_coverage extends uvm_subscriber #(axi_transaction);
	`uvm_component_utils(axi_coverage)

	axi_transaction tr;

	// COVERGROUP
	covergroup axi_cg;
		option.per_instance = 1;
		option.comment = "Coverage for SOC RISC-V AXI-Lite";

		// 1. Cover all Memory Map (Check Address Decoder)
		ADDR_CP : coverpoint tr.addr {
			bins ram 	= {[32'h0000_0000:32'h0000_03FF]};	// RAM 1KB
			bins timer 	= {[32'h0000_0400:32'h0000_07FF]};	// Timer
			bins uart	= {[32'h0000_0800:32'h0000_0BFF]};	// UART
			bins spi	= {[32'h0000_0C00:32'h0000_0FFF]};	// SPI
			bins illegal	= default;
		}

		// 2. Cover instructions
		CMD_CP : coverpoint tr.is_write {
			bins write_acess	= {1};
			bins read_acess		= {0};	
		}

		// 3. Cover Data Platform
		DATA_CP : coverpoint tr.data {
			bins zero	= {32'h0000_0000};
			bins ones	= {32'hFFFF_FFFF};
			bins alt_05	= {32'h5555_5555};
			bins alt_A	= {32'hAAAA_AAAA};
			bins deadbeef	= {32'hDEAD_BEEF};
			bins others	= default;	
		}

		// 4. Cover Byte enable
		STRB_CP : coverpoint tr.wstrb {
			bins byte_0	= {4'b0001};
			bins byte_1	= {4'b0010};
			bins byte_2	= {4'b0100};
			bins byte_3	= {4'b1000};
			bins word	= {4'b1111};	
		}

		// 5. CROSS COVERAGE
		// Check : Have ever written to a UART? Have ever read from a timer?
		ADDR_x_CMD : cross ADDR_CP, CMD_CP;
		
		// Check : Enable bytes are being written to RAM.
		RAM_x_STRB : cross ADDR_CP, STRB_CP {
			ignore_bins others = RAM_x_STRB with (!(ADDR_CP inside {[32'h0000_0000:32'h0000_03FF]}));
		}
	endgroup

	function new(string name, uvm_component parent);
		super.new(name, parent);
		axi_cg = new();
	endfunction

	virtual function void write(axi_transaction t);
		this.tr = t;
		axi_cg.sample();
	endfunction
endclass
