class axi_driver extends uvm_driver #(axi_transaction);
	`uvm_component_utils(axi_driver)
	
	// Connect with Interface through config_db
	virtual soc_if vif;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	
	// Take interface from storage
	virtual function void build_phase(uvm_phase phase);
		if (!uvm_config_db#(virtual soc_if)::get(this, "", "vif_soc", vif))
			`uvm_fatal("NO_VIF", {"virtual interface must be set for : ", get_full_name(), ".vif"})
	endfunction
	
	// Run  process
	virtual task run_phase(uvm_phase phase);
		// Initilize the bus's intial state
		reset_bus();

		forever begin
			// 1. Take transaction from sequencer
			seq_item_port.get_next_item(req);

			// 2. Do transaction based on types (Write/Read)
			if (req.is_write)
				drive_write(req);
			else 
				drive_read(req);

			// 3. End transaction
			seq_item_port.item_done();
		end
	endtask

	// Task reset for bus
	task reset_bus();
		wait(vif.rstn === 0);
	       	vif.drv_cb.awvalid <= 0;
		vif.drv_cb.wvalid  <= 0;
		vif.drv_cb.arvalid <= 0;
		vif.drv_cb.bready  <= 0;
		vif.drv_cb.rready  <= 0;
		wait(vif.rstn === 1);	
	endtask

	// Write task
	task drive_write (axi_transaction tr);
		@(vif.drv_cb);
		vif.drv_cb.awaddr 	<= tr.addr;
		vif.drv_cb.awvalid 	<= 1'b1;
		vif.drv_cb.wdata   	<= tr.data;
	        vif.drv_cb.wstrb	<= tr.wstrb;
		vif.drv_cb.wvalid	<= 1'b1;
		vif.drv_cb.bready	<= 1'b1;

		// Hanshake AW & W
		fork 
			wait(vif.drv_cb.awready);
			wait(vif.drv_cb.wready);
		join

		@(vif.drv_cb);
		vif.drv_cb.awvalid <= 1'b0;
		vif.drv_cb.wvalid  <= 1'b0;

		// Wait done response from Slaves
		wait(vif.drv_cb.bvalid);
		@(vif.drv_cb);
		vif.drv_cb.bready <= 1'b0;
		`uvm_info("DRV", $sformatf("Write Done: Addr = %h, Data = %h", tr.addr, tr.data), UVM_HIGH)	
	endtask

	// Read task
	task drive_read (axi_transaction tr);
		@(vif.drv_cb);
		vif.drv_cb.araddr 	<= tr.addr;
		vif.drv_cb.arvalid	<= 1'b1;
	       	vif.drv_cb.rready	<= 1'b1;

		// Handshake AR
		wait (vif.drv_cb.arready);
		@(vif.drv_cb);
		vif.drv_cb.arvalid 	<= 1'b0;

		// Wait for return signals from Slaves
		wait (vif.drv_cb.rvalid);
		tr.data = vif.drv_cb.rdata;
		@(vif.drv_cb);
		vif.drv_cb.rready 	<= 1'b0;
		`uvm_info("DRV", $sformatf("Read Done: Addr = %h, Data = %h", tr.addr, tr.data), UVM_HIGH)	
	endtask
endclass
