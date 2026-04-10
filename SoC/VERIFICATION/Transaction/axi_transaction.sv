class axi_transaction extends uvm_sequence_item;
	rand logic [31:0] addr;
	rand logic [31:0] data;
	rand logic is_write; // 1 : write, 0 : read
	rand logic [3:0]  wstrb;

	`uvm_object_utils_begin(axi_transaction)
		`uvm_field_int(addr, UVM_DEFAULT)
		`uvm_field_int(data, UVM_DEFAULT)
		`uvm_field_int(is_write, UVM_DEFAULT)
		`uvm_field_int(wstrb, UVM_DEFAULT)
	`uvm_object_utils_end

	function new(string name = "axi_transaction");
		super.new(name);
	endfunction
endclass
