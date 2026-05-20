class spi_monitor extends uvm_monitor;
  `uvm_component_utils(spi_monitor)

  virtual soc_inf vif;
  uvm_analysis_port #(spi_transaction) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual soc_inf)::get(this, "", "vif", vif))
      `uvm_fatal("SPI_MON", "Cannot get vif")
  endfunction

  task run_phase(uvm_phase phase);
    fork
      monitor_axi();
      monitor_spi_pins();
    join
  endtask

  task monitor_axi();
    spi_transaction tr;
    bit [31:0] awaddr_q;
    bit [2:0] awprot_q;
    bit [31:0] araddr_q;
    bit [2:0] arprot_q;

    forever begin
      @(vif.mon_cb);

      if (vif.mon_cb.awvalid && vif.mon_cb.awready) begin
        awaddr_q = vif.mon_cb.awaddr;
        awprot_q = vif.mon_cb.awprot;
      end

      if (vif.mon_cb.arvalid && vif.mon_cb.arready) begin
        araddr_q = vif.mon_cb.araddr;
        arprot_q = vif.mon_cb.arprot;
      end

      if (vif.mon_cb.wvalid && vif.mon_cb.wready) begin
        tr                   = spi_transaction::type_id::create("tr");
        tr.op                = SPI_AXI_WRITE;
        tr.addr              = awaddr_q;
        tr.awprot            = awprot_q;
        tr.data              = vif.mon_cb.wdata;
        tr.wstrb             = vif.mon_cb.wstrb;
        tr.is_start_transfer = (awaddr_q == 32'h4000_0004 && vif.mon_cb.wdata[0]);

        `uvm_info("SPI_MON_AXI", $sformatf("WRITE addr=%h data=%h prot=%b strb=%b start=%0b",
                                           tr.addr, tr.data, tr.awprot, tr.wstrb,
                                           tr.is_start_transfer), UVM_LOW)

        ap.write(tr);
      end

      if (vif.mon_cb.rvalid && vif.mon_cb.rready) begin
        tr        = spi_transaction::type_id::create("tr");
        tr.op     = SPI_AXI_READ;
        tr.addr   = araddr_q;
        tr.arprot = arprot_q;
        tr.rdata  = vif.mon_cb.rdata;
        tr.resp   = vif.mon_cb.rresp;

        `uvm_info("SPI_MON_AXI", $sformatf("READ addr=%h data=%h prot=%b resp=%b", tr.addr,
                                           tr.rdata, tr.arprot, tr.resp), UVM_LOW)

        ap.write(tr);
      end
    end
  endtask

  task monitor_spi_pins();
    spi_transaction tr;
    bit [7:0] mosi_byte;
    bit [7:0] miso_byte;
    int bit_idx;

    forever begin
      wait (vif.spi_cs_n === 1'b0);

      mosi_byte = 8'h00;
      miso_byte = 8'h00;

      for (bit_idx = 7; bit_idx >= 0; bit_idx--) begin
        @(negedge vif.spi_sck);
        mosi_byte[bit_idx] = vif.spi_mosi;
        miso_byte[bit_idx] = vif.spi_miso;
      end

      wait (vif.spi_cs_n === 1'b1);

      tr             = spi_transaction::type_id::create("tr");
      tr.op          = SPI_PIN_TRANSFER;
      tr.addr        = 32'h4000_0004;
      tr.data        = 32'h0000_0001;
      tr.miso_byte   = miso_byte;
      tr.exp_rx_byte = miso_byte;

      `uvm_info("SPI_MON_PIN", $sformatf(
                "SPI transfer observed MOSI=%02h MISO=%02h", mosi_byte, miso_byte), UVM_LOW)

      ap.write(tr);
    end
  endtask
endclass
