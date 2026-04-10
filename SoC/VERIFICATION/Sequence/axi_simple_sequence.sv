class axi_simple_sequence extends uvm_sequence #(axi_transaction);
	`uvm_object_utils(axi_simple_sequence)

	function new(string name = "axi_simple_sequence");
		super.new(name);
	endfunction

	virtual task body();
		`uvm_info("SEQ", "Bat dau goi tin AXI Write Test ... ", UVM_LOW)
		req = axi_transaction::type_id::create("req");

		start_item(req);

		if (!req.randomize() with {
				addr == 32'h0000_0100;
				data == 32'hDEAD_BEEF;
				is_write == 1'b1;
				}) begin
					`uvm_error("SEQ", "Random failed!")
				end
		finish_item(req);

		`uvm_info("SEQ", "Da gui xong goi tin!", UVM_LOW)
	endtask
endclass
