typedef enum {
  UART_AXI_WRITE,
  UART_AXI_READ,
  UART_RX_BYTE
} uart_op_e;

class uart_transaction extends uvm_sequence_item;
  rand uart_op_e           op;
  rand bit          [31:0] addr;
  rand bit          [31:0] data;
  rand bit          [ 3:0] wstrb;
  rand bit          [ 2:0] awprot;
  rand bit          [ 2:0] arprot;
  rand bit          [ 7:0] rx_byte;
  rand int unsigned        baud_cycles;

  bit               [31:0] rdata;
  bit               [ 1:0] resp;

  constraint c_addr {addr inside {32'h3000_0000, 32'h3000_0004, 32'h3000_0008, 32'h3000_000C};}

  constraint c_wstrb {wstrb == 4'hf;}

  constraint c_baud {baud_cycles inside {4, 8, 16, 32};}

  `uvm_object_utils_begin(uart_transaction)
    `uvm_field_enum(uart_op_e, op, UVM_DEFAULT)
    `uvm_field_int(addr, UVM_DEFAULT)
    `uvm_field_int(data, UVM_DEFAULT)
    `uvm_field_int(wstrb, UVM_DEFAULT)
    `uvm_field_int(awprot, UVM_DEFAULT)
    `uvm_field_int(arprot, UVM_DEFAULT)
    `uvm_field_int(rx_byte, UVM_DEFAULT)
    `uvm_field_int(baud_cycles, UVM_DEFAULT)
    `uvm_field_int(rdata, UVM_DEFAULT)
    `uvm_field_int(resp, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "uart_transaction");
    super.new(name);
  endfunction
endclass
