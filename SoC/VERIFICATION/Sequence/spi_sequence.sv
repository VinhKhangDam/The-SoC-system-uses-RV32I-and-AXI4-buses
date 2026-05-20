class spi_sequence extends uvm_sequence #(spi_transaction);

  `uvm_object_utils(spi_sequence)

  function new(string name = "spi_sequence");
    super.new(name);
  endfunction

  task body();
    `uvm_info("SPI_SEQ", "Start SPI directed + random sequence", UVM_LOW)

    read_reg(32'h4000_0000, 3'b000);
    read_reg(32'h4000_0004, 3'b000);
    read_reg(32'h4000_0008, 3'b000);
    read_reg(32'h4000_000C, 3'b000);

    spi_xfer(8'ha5, 8'h3c, 3'b001);
    spi_xfer(8'h00, 8'h00, 3'b010);
    spi_xfer(8'hff, 8'hff, 3'b011);
    spi_xfer(8'h55, 8'haa, 3'b100);
    spi_xfer(8'haa, 8'h55, 3'b101);

    // Start while busy / back-to-back Start
    write_reg(32'h4000_000C, 32'h0000_0002, 3'b110);
    start_spi(8'h34, 3'b110);
    write_reg(32'h4000_0004, 32'h0000_0001, 3'b110);
    repeat (30) read_reg(32'h4000_0008, 3'b110);
    read_reg(32'h4000_0000, 3'b110);
    write_reg(32'h4000_0004, 32'h0000_0008, 3'b110);

    // Ignore write
    write_reg(32'h4000_0008, 32'hdead_beef, 3'b111);
    write_reg(32'h4000_000C, 32'h0000_000A, 3'b111);
    read_reg(32'h4000_0004, 3'b111);
    read_reg(32'h4000_000C, 3'b111);

    repeat (200) begin
      bit [7:0] tx_b;
      bit [7:0] miso_b;

      tx_b   = $urandom_range(0, 255);
      miso_b = $urandom_range(0, 255);
      spi_xfer(tx_b, miso_b, $urandom_range(0, 7));
    end

    `uvm_info("SPI_SEQ", "Finished SPI directed + random sequence", UVM_LOW)
  endtask

  task spi_xfer(bit [7:0] tx_byte, bit [7:0] miso_byte, bit [2:0] prot);
    write_reg(32'h4000_0000, {24'h0, tx_byte}, prot);
    start_spi(miso_byte, prot);
    repeat (20) read_reg(32'h4000_0008, prot);
    read_reg(32'h4000_0000, prot);
    write_reg(32'h4000_0004, 32'h0000_0008, prot);
  endtask

  task start_spi(bit [7:0] miso_byte, bit [2:0] prot);
    spi_transaction tr;
    tr = spi_transaction::type_id::create("start_tr");

    start_item(tr);
    tr.op = SPI_AXI_WRITE;
    tr.addr = 32'h4000_0004;
    tr.data = 32'h0000_0001;
    tr.wstrb = 4'hf;
    tr.awprot = prot;
    tr.miso_byte = miso_byte;
    tr.exp_rx_byte = miso_byte;
    tr.is_start_transfer = 1'b1;
    finish_item(tr);
  endtask

  task write_reg(bit [31:0] addr, bit [31:0] data, bit [2:0] prot);
    spi_transaction tr;
    tr = spi_transaction::type_id::create("wr");

    start_item(tr);
    tr.op = SPI_AXI_WRITE;
    tr.addr = addr;
    tr.data = data;
    tr.wstrb = 4'hf;
    tr.awprot = prot;
    tr.is_start_transfer = 1'b0;
    finish_item(tr);
  endtask

  task read_reg(bit [31:0] addr, bit [2:0] prot);
    spi_transaction tr;
    tr = spi_transaction::type_id::create("rd");

    start_item(tr);
    tr.op = SPI_AXI_READ;
    tr.addr = addr;
    tr.arprot = prot;
    finish_item(tr);
  endtask

endclass
