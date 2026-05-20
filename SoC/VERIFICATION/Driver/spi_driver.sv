class spi_driver extends uvm_driver #(spi_transaction);
  `uvm_component_utils(spi_driver)

  virtual soc_inf vif;
  virtual clk_rst_inf cr_vif;

  uvm_analysis_port #(spi_transaction) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual soc_inf)::get(this, "", "vif", vif))
      `uvm_fatal("SPI_DRIVER", "Cannot get vif")
    if (!uvm_config_db#(virtual clk_rst_inf)::get(this, "", "cr_vif", cr_vif))
      `uvm_fatal("SPI_DRIVER", "Cannot get cr_vif")
  endfunction

  task run_phase(uvm_phase phase);
    spi_transaction tr;

    vif.drv_cb.awaddr  <= '0;
    vif.drv_cb.awprot  <= '0;
    vif.drv_cb.awvalid <= 1'b0;

    vif.drv_cb.wdata   <= '0;
    vif.drv_cb.wstrb   <= '0;
    vif.drv_cb.wvalid  <= 1'b0;

    vif.drv_cb.bready  <= 1'b0;

    vif.drv_cb.araddr  <= '0;
    vif.drv_cb.arprot  <= '0;
    vif.drv_cb.arvalid <= 1'b0;

    vif.drv_cb.rready  <= 1'b0;

    vif.spi_miso       <= 1'b0;

    wait (cr_vif.rstn == 1'b1);
    repeat (2) @(posedge cr_vif.clk);

    forever begin
      seq_item_port.get_next_item(tr);

      unique case (tr.op)
        SPI_AXI_WRITE: begin
          if (tr.is_start_transfer) begin
            fork
              drive_spi_miso(tr);
              drive_write(tr);
            join
          end else begin
            drive_write(tr);
          end
        end
        SPI_AXI_READ: drive_read(tr);
        default:      `uvm_error("SPI_ERROR", "Unknow SPI op")
      endcase

      seq_item_port.item_done();
    end
  endtask

  task drive_write(spi_transaction tr);
    vif.drv_cb.awaddr  <= tr.addr;
    vif.drv_cb.awprot  <= tr.awprot;
    vif.drv_cb.wstrb   <= tr.wstrb;
    vif.drv_cb.wdata   <= tr.data;

    vif.drv_cb.awvalid <= 1'b1;
    vif.drv_cb.wvalid  <= 1'b1;
    vif.drv_cb.bready  <= 1'b1;

    do @(vif.drv_cb); while (!(vif.drv_cb.awready && vif.drv_cb.wready));
    vif.drv_cb.awvalid <= 1'b0;
    vif.drv_cb.wvalid  <= 1'b0;

    do @(vif.drv_cb); while (!(vif.drv_cb.bvalid));

    tr.resp = vif.drv_cb.bresp;

    @(vif.drv_cb);
    vif.drv_cb.bready <= 1'b0;
  endtask

  task drive_read(spi_transaction tr);
    vif.drv_cb.araddr  <= tr.addr;
    vif.drv_cb.arprot  <= tr.arprot;

    vif.drv_cb.arvalid <= 1'b1;
    vif.drv_cb.rready  <= 1'b1;

    do @(vif.drv_cb); while (!vif.drv_cb.arready);

    vif.drv_cb.arvalid <= 1'b0;

    do @(vif.drv_cb); while (!vif.drv_cb.rvalid);

    tr.rdata <= vif.drv_cb.rdata;
    tr.resp  <= vif.drv_cb.rresp;

    @(vif.drv_cb);
    vif.drv_cb.rready <= 1'b0;
  endtask

  task drive_spi_miso(spi_transaction tr);
    spi_transaction exp_tr;
    int bit_idx;
    int timeout;

    timeout = 0;
    while (vif.spi_cs_n != 1'b0 && timeout < 1000) begin
      @(posedge cr_vif.clk);
      timeout++;
    end

    if (timeout >= 1000) begin
      `uvm_error("SPI_DRIVER", "Timeout waiting for spi_cs_n active");
      return;
    end

    exp_tr             = spi_transaction::type_id::create("spi_exp_tr");
    exp_tr.op          = SPI_EXPECT_TRANSFER;
    exp_tr.addr        = tr.addr;
    exp_tr.data        = tr.data;
    exp_tr.awprot      = tr.awprot;
    exp_tr.miso_byte   = tr.miso_byte;
    exp_tr.exp_rx_byte = tr.miso_byte;
    ap.write(exp_tr);

    for (bit_idx = 7; bit_idx >= 0; bit_idx--) begin
      @(posedge vif.spi_sck);
      vif.spi_miso <= tr.miso_byte[bit_idx];
    end
  endtask
endclass
