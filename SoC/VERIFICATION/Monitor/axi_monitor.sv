class axi_monitor extends uvm_monitor;
	`uvm_component_utils(axi_monitor)

	virtual clk_rst_inf vif_cr;
	virtual soc_inf     vif;

	uvm_analysis_port #(axi_transaction) item_collected_port;

	function new(string name, uvm_component parent);
		super.new(name, parent);
		item_collected_port = new("item_collected_port", this);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual soc_inf)::get(this, "", "vif_soc", vif))	
			`uvm_fatal("MON", "Could not get vif")
		if (!uvm_config_db#(virtual clk_rst_inf)::get(this, "", "vif_cr", vif_cr))
			`uvm_fatal("MON", "Could not get vif_cr")
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		fork
			collect_write_transactions();
			collect_read_transactions();
		join_none
	endtask

	// Watch Write Channel
	task collect_write_transactions();
		forever begin
			axi_transaction tr;
			@(posedge vif_cr.clk);

			if (vif.awvalid && vif.awready) begin
				tr          = axi_transaction::type_id::create("tr");
				tr.addr     = vif.awaddr;
				tr.awprot   = vif.awprot;
				tr.is_write = 1'b1;

				// Capture W channel
				while (!(vif.wvalid && vif.wready))
					@(posedge vif_cr.clk);
				tr.data  = vif.wdata;
				tr.wstrb = vif.wstrb;

				// Capture B response
				while (!(vif.bvalid && vif.bready))
					@(posedge vif_cr.clk);
				tr.bresp = vif.bresp;     

				`uvm_info("MON_WR",
					$sformatf("Detected WRITE : Addr=%h Data=%h Strb=%b Prot=%b BResp=%b",
						tr.addr, tr.data, tr.wstrb, tr.awprot, tr.bresp),
					UVM_LOW)
				item_collected_port.write(tr);
			end
		end
	endtask

	// Watch Read Channel
	task collect_read_transactions();
		forever begin
			axi_transaction tr;
			@(posedge vif_cr.clk);

			if (vif.arvalid && vif.arready) begin
				tr          = axi_transaction::type_id::create("tr");
				tr.addr     = vif.araddr;
				tr.arprot   = vif.arprot; 
				tr.is_write = 1'b0;

				// Capture R data + response
				while (!(vif.rvalid && vif.rready))
					@(posedge vif_cr.clk);
				tr.data  = vif.rdata;
				tr.rresp = vif.rresp;

				`uvm_info("MON_RD",
					$sformatf("Detected READ  : Addr=%h Data=%h Prot=%b RResp=%b",
						tr.addr, tr.data, tr.arprot, tr.rresp),
					UVM_LOW)
				item_collected_port.write(tr);
			end
		end
	endtask
endclass