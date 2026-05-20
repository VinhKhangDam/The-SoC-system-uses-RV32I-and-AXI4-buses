class timer_transaction extends uvm_sequence_item;
  rand bit        is_write;
  rand bit [31:0] addr;
  rand bit [31:0] data;
  rand bit [ 3:0] wstrb;
  rand bit [ 2:0] awprot;
  rand bit [ 2:0] arprot;

  bit      [31:0] rdata;
  bit      [ 1:0] resp;

  constraint c_addr {addr inside {32'h2000_0000, 32'h2000_0004, 32'h2000_0008, 32'h2000_000C};}

  constraint c_wstrb {wstrb == 4'b1111;}

  `uvm_object_utils_begin(timer_transaction)
    `uvm_field_int(is_write, UVM_DEFAULT)
    `uvm_field_int(addr, UVM_DEFAULT)
    `uvm_field_int(data, UVM_DEFAULT)
    `uvm_field_int(wstrb, UVM_DEFAULT)
    `uvm_field_int(awprot, UVM_DEFAULT)
    `uvm_field_int(arprot, UVM_DEFAULT)
    `uvm_field_int(rdata, UVM_DEFAULT)
    `uvm_field_int(resp, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "timer_transaction");
    super.new(name);
  endfunction  // new
endclass
