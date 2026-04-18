class axi_driver extends uvm_driver #(axi_transaction);
	`uvm_component_utils(axi_driver)
	
	virtual soc_inf vif;
	virtual clk_rst_inf vif_cr;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		if (!uvm_config_db#(virtual soc_inf)::get(this, "", "vif_soc", vif))
			`uvm_fatal("NO_VIF", {"virtual interface must be set for : ", get_full_name(), ".vif"})
		if (!uvm_config_db#(virtual clk_rst_inf)::get(this, "", "vif_cr", vif_cr))
			`uvm_fatal("NO_VIF", {"Virtual interface must be set for :", get_full_name(), ".vif"})
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		reset_bus();
		forever begin
			seq_item_port.get_next_item(req);
			if (req.is_write)
				drive_write(req);
			else 
				drive_read(req);
			seq_item_port.item_done();
		end
	endtask

	task reset_bus();
		vif.drv_cb.awvalid <= 0;
		vif.drv_cb.wvalid  <= 0;
		vif.drv_cb.arvalid <= 0;
		vif.drv_cb.bready  <= 0;
		vif.drv_cb.rready  <= 0;
		if (vif_cr.rstn !== 1'b1)
			@(posedge vif_cr.rstn);
		@(vif.drv_cb);
	endtask

	task drive_write(axi_transaction tr);
		// Present address and data
		@(vif.drv_cb);
		vif.drv_cb.awaddr  <= tr.addr;
		vif.drv_cb.awvalid <= 1'b1;
		vif.drv_cb.wdata   <= tr.data;
		vif.drv_cb.wstrb   <= tr.wstrb;
		vif.drv_cb.wvalid  <= 1'b1;
		vif.drv_cb.bready  <= 1'b1;

		// Wait for AW handshake (sample each clock edge)
		@(vif.drv_cb);
		while (!vif.drv_cb.awready) @(vif.drv_cb);
		vif.drv_cb.awvalid <= 1'b0;

		// Wait for W handshake (sample each clock edge)  
		// wready may come same cycle or later
		while (!vif.drv_cb.wready) @(vif.drv_cb);
		vif.drv_cb.wvalid <= 1'b0;

		// Wait for B response
		while (!vif.drv_cb.bvalid) @(vif.drv_cb);
		@(vif.drv_cb);
		vif.drv_cb.bready <= 1'b0;

		`uvm_info("DRV", $sformatf("Write Done: Addr=%h, Data=%h", tr.addr, tr.data), UVM_HIGH)
	endtask

	task drive_read(axi_transaction tr);
		// Present address
		@(vif.drv_cb);
		vif.drv_cb.araddr  <= tr.addr;
		vif.drv_cb.arvalid <= 1'b1;
		vif.drv_cb.rready  <= 1'b1;

		// Wait for AR handshake
		@(vif.drv_cb);
		while (!vif.drv_cb.arready) @(vif.drv_cb);
		vif.drv_cb.arvalid <= 1'b0;

		// Wait for R data
		while (!vif.drv_cb.rvalid) @(vif.drv_cb);
		tr.data = vif.drv_cb.rdata;
		@(vif.drv_cb);
		vif.drv_cb.rready <= 1'b0;

		`uvm_info("DRV", $sformatf("Read Done: Addr=%h, Data=%h", tr.addr, tr.data), UVM_HIGH)
	endtask
endclass