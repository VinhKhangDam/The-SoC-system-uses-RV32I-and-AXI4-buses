typedef enum {
  SPI_AXI_WRITE,
  SPI_AXI_READ,
  SPI_EXPECT_TRANSFER,
  SPI_PIN_TRANSFER
} spi_op_e;

class spi_transaction extends uvm_sequence_item;
  rand spi_op_e        op;

  rand bit      [31:0] addr;
  rand bit      [31:0] data;
  rand bit      [ 3:0] wstrb;
  rand bit      [ 2:0] awprot;
  rand bit      [ 2:0] arprot;

  bit           [31:0] rdata;
  bit           [ 1:0] resp;

  rand bit      [ 7:0] miso_byte;
  rand bit             is_start_transfer;
  bit           [ 7:0] exp_rx_byte;

  constraint c_addr {addr inside {32'h4000_0000, 32'h4000_0004, 32'h4000_0008, 32'h4000_000C};}

  constraint c_wstrb {wstrb == 4'hf;}

  `uvm_object_utils_begin(spi_transaction)
    `uvm_field_enum(spi_op_e, op, UVM_DEFAULT)
    `uvm_field_int(addr, UVM_DEFAULT)
    `uvm_field_int(data, UVM_DEFAULT)
    `uvm_field_int(wstrb, UVM_DEFAULT)
    `uvm_field_int(awprot, UVM_DEFAULT)
    `uvm_field_int(arprot, UVM_DEFAULT)
    `uvm_field_int(rdata, UVM_DEFAULT)
    `uvm_field_int(resp, UVM_DEFAULT)
    `uvm_field_int(miso_byte, UVM_DEFAULT)
    `uvm_field_int(is_start_transfer, UVM_DEFAULT)
    `uvm_field_int(exp_rx_byte, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "spi_transaction");
    super.new(name);
  endfunction
endclass
