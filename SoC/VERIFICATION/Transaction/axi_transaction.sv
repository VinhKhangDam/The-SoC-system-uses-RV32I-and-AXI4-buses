class axi_transaction extends uvm_sequence_item;
  rand logic [31:0] addr;
  rand logic [31:0] data;
  rand logic        is_write;  // 1 : write, 0 : read
  rand logic [ 3:0] wstrb;
  // AW channel
  rand logic [ 2:0] awprot;
  // AR channel
  rand logic [ 2:0] arprot;
  // B channel (write response)
  logic      [ 1:0] bresp;
  // R channel (read response)
  logic      [ 1:0] rresp;

  `uvm_object_utils_begin(axi_transaction)
    `uvm_field_int(addr, UVM_DEFAULT)
    `uvm_field_int(data, UVM_DEFAULT)
    `uvm_field_int(is_write, UVM_DEFAULT)
    `uvm_field_int(wstrb, UVM_DEFAULT)
    `uvm_field_int(awprot, UVM_DEFAULT)
    `uvm_field_int(arprot, UVM_DEFAULT)
    `uvm_field_int(bresp, UVM_DEFAULT)
    `uvm_field_int(rresp, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "axi_transaction");
    super.new(name);
  endfunction

  function string convert2string();
    if (is_write)
      return $sformatf(
          "WR Addr=%h Data=%h Strb=%b AWProt=%b BResp=%b", addr, data, wstrb, awprot, bresp
      );
    else return $sformatf("RD Addr=%h Data=%h ARProt=%b RResp=%b", addr, data, arprot, rresp);
  endfunction
endclass

