class spi_coverage extends uvm_subscriber #(spi_transaction);
  `uvm_component_utils(spi_coverage)

  spi_op_e op;
  bit [31:0] addr;
  bit [31:0] data;
  bit [2:0] prot;
  bit [7:0] tx_byte;
  bit [7:0] rx_byte;

  covergroup spi_cg;
    option.per_instance = 1;

    cp_op: coverpoint op {
      bins wr = {SPI_AXI_WRITE};
      bins rd = {SPI_AXI_READ};
      bins exp = {SPI_EXPECT_TRANSFER};
      bins pin = {SPI_PIN_TRANSFER};
    }

    cp_addr: coverpoint addr[3:0] iff (op inside {SPI_AXI_WRITE, SPI_AXI_READ}) {
      bins data = {4'h0}; bins ctrl = {4'h4}; bins status = {4'h8}; bins baud = {4'hc};
    }

    cp_prot: coverpoint prot iff (op inside {SPI_AXI_WRITE, SPI_AXI_READ}) {bins p[] = {[0 : 7]};}

    cp_byte: coverpoint tx_byte {
      bins zero = {8'h00};
      bins ones = {8'hff};
      bins p55 = {8'h55};
      bins paa = {8'haa};
      bins misc = default;
    }

    cp_rx: coverpoint rx_byte {
      bins zero = {8'h00};
      bins ones = {8'hff};
      bins p55 = {8'h55};
      bins paa = {8'haa};
      bins misc = default;
    }

    op_x_addr : cross cp_op, cp_addr;
    addr_x_prot: cross cp_addr, cp_prot;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    spi_cg = new();
  endfunction

  function void write(spi_transaction t);
    op = t.op;
    addr = t.addr;
    data = t.data;
    prot = (t.op == SPI_AXI_WRITE) ? t.awprot : t.arprot;
    tx_byte = t.data[7:0];
    rx_byte = t.exp_rx_byte;
    spi_cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SPI_COV", $sformatf("TOTAL SPI Coverage = %.2f%%", spi_cg.get_inst_coverage()),
              UVM_LOW)
  endfunction
endclass
