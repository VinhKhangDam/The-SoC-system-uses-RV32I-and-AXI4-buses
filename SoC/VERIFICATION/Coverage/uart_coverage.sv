class uart_coverage extends uvm_subscriber #(uart_transaction);
  `uvm_component_utils(uart_coverage)

  uart_op_e op;
  bit [31:0] addr;
  bit [31:0] data;
  bit [2:0] prot;

  int unsigned sample_count;
  int unsigned write_count;
  int unsigned read_count;
  int unsigned rx_byte_count;

  covergroup uart_cg;
    option.per_instance = 1;

    cp_op: coverpoint op {
      bins axi_write = {UART_AXI_WRITE};
      bins axi_read = {UART_AXI_READ};
      bins rx_byte = {UART_RX_BYTE};
    }

    cp_addr: coverpoint addr[3:0] iff (op != UART_RX_BYTE) {
      bins txdata = {4'h0}; bins rxdata = {4'h4}; bins status = {4'h8}; bins baud = {4'hc};
    }

    cp_prot: coverpoint prot iff (op != UART_RX_BYTE) {
      bins p0 = {3'b000};
      bins p1 = {3'b001};
      bins p2 = {3'b010};
      bins p3 = {3'b011};
      bins p4 = {3'b100};
      bins p5 = {3'b101};
      bins p6 = {3'b110};
      bins p7 = {3'b111};
    }

    cp_tx_byte: coverpoint data[7:0] iff (op == UART_AXI_WRITE && addr[3:0] == 4'h0) {
      bins byte_zero = {8'h00};
      bins byte_ones = {8'hff};
      bins pattern55 = {8'h55};
      bins patternaa = {8'haa};
      bins printable = {[8'h20 : 8'h7e]};
      bins others = default;
    }

    cp_baud: coverpoint data iff (op == UART_AXI_WRITE && addr[3:0] == 4'hc) {
      bins baud_4 = {32'd4};
      bins baud_8 = {32'd8};
      bins baud_16 = {32'd16};
      bins baud_32 = {32'd32};
      bins baud_115200 = {32'd115200};
    }

    op_x_addr: cross cp_op, cp_addr;
    addr_x_prot: cross cp_addr, cp_prot;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    uart_cg = new();
  endfunction

  function void write(uart_transaction t);
    op   = t.op;
    addr = t.addr;
    data = (t.op == UART_AXI_READ) ? t.rdata : t.data;
    prot = (t.op == UART_AXI_WRITE) ? t.awprot : t.arprot;

    sample_count++;
    if (t.op == UART_AXI_WRITE) write_count++;
    else if (t.op == UART_AXI_READ) read_count++;
    else rx_byte_count++;

    uart_cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("UART_COV", "======================================================", UVM_LOW)
    `uvm_info("UART_COV", "               UART COVERAGE REPORT                  ", UVM_LOW)
    `uvm_info("UART_COV", "======================================================", UVM_LOW)
    `uvm_info("UART_COV", $sformatf("Samples        : %0d", sample_count), UVM_LOW)
    `uvm_info("UART_COV", $sformatf(
              "Counts         : WR=%0d RD=%0d RX_BYTE=%0d", write_count, read_count, rx_byte_count),
              UVM_LOW)
    `uvm_info("UART_COV", $sformatf("Op Coverage    : %.2f%%", uart_cg.cp_op.get_coverage()),
              UVM_LOW)
    `uvm_info("UART_COV", $sformatf("Addr Coverage  : %.2f%%", uart_cg.cp_addr.get_coverage()),
              UVM_LOW)
    `uvm_info("UART_COV", $sformatf("PROT Coverage  : %.2f%%", uart_cg.cp_prot.get_coverage()),
              UVM_LOW)
    `uvm_info("UART_COV", $sformatf("TX Byte Cover  : %.2f%%", uart_cg.cp_tx_byte.get_coverage()),
              UVM_LOW)
    `uvm_info("UART_COV", $sformatf("Baud Coverage  : %.2f%%", uart_cg.cp_baud.get_coverage()),
              UVM_LOW)
    `uvm_info("UART_COV", $sformatf("TOTAL Coverage : %.2f%%", uart_cg.get_inst_coverage()),
              UVM_LOW)
    `uvm_info("UART_COV", "======================================================", UVM_LOW)
  endfunction
endclass
