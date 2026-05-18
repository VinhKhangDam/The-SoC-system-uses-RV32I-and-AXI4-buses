class uart_driver extends uvm_driver #(uart_transaction);
   `uvm_component_utils(uart_driver)

   virtual soc_inf vif;
   virtual clk_rst_inf cr_vif;
   uvm_analysis_port #(uart_transaction) ap;

   function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
   endfunction

   function void build_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual soc_inf)::get(this, "", "vif", vif))
        `uvm_fatal("UART_DRV", "Cannot get vif")

      if (!uvm_config_db #(virtual clk_rst_inf)::get(this, "", "vif_cr", cr_vif))
        `uvm_fatal("UART_DRV", "Cannot get vif_cr")
   endfunction

   task run_phase(uvm_phase phase);
      uart_transaction tr;

      vif.drv_cb.awvalid <= 1'b0;
      vif.drv_cb.wvalid  <= 1'b0;
      vif.drv_cb.bready  <= 1'b0;
      vif.drv_cb.arvalid <= 1'b0;
      vif.drv_cb.rready  <= 1'b0;
      vif.uart_rx        <= 1'b1;

      forever begin
         seq_item_port.get_next_item(tr);

         case (tr.op)
            UART_AXI_WRITE: drive_write(tr);
            UART_AXI_READ : drive_read(tr);
            UART_RX_BYTE  : begin
               drive_rx_byte(tr.rx_byte, tr.baud_cycles);
               repeat (tr.baud_cycles + 4) @(posedge cr_vif.clk);
               ap.write(tr);
            end
            default       : `uvm_error("UART_DRV", "Unknown UART op")
         endcase

         seq_item_port.item_done();
      end
   endtask

   task drive_write(uart_transaction tr);
      vif.drv_cb.awaddr  <= tr.addr;
      vif.drv_cb.awprot  <= tr.awprot;
      vif.drv_cb.wdata   <= tr.data;
      vif.drv_cb.wstrb   <= tr.wstrb;
      vif.drv_cb.awvalid <= 1'b1;
      vif.drv_cb.wvalid  <= 1'b1;
      vif.drv_cb.bready  <= 1'b1;

      do @(vif.drv_cb); while (!(vif.drv_cb.awready && vif.drv_cb.wready));
      vif.drv_cb.awvalid <= 1'b0;
      vif.drv_cb.wvalid  <= 1'b0;

      do @(vif.drv_cb); while (!vif.drv_cb.bvalid);
      tr.resp = vif.drv_cb.bresp;

      @(vif.drv_cb);
      vif.drv_cb.bready <= 1'b0;
   endtask

   task drive_read(uart_transaction tr);
      vif.drv_cb.araddr  <= tr.addr;
      vif.drv_cb.arprot  <= tr.arprot;
      vif.drv_cb.arvalid <= 1'b1;
      vif.drv_cb.rready  <= 1'b1;

      do @(vif.drv_cb); while (!vif.drv_cb.arready);
      vif.drv_cb.arvalid <= 1'b0;

      do @(vif.drv_cb); while (!vif.drv_cb.rvalid);
      tr.rdata = vif.drv_cb.rdata;
      tr.resp  = vif.drv_cb.rresp;

      @(vif.drv_cb);
      vif.drv_cb.rready <= 1'b0;
   endtask

   task drive_rx_byte(bit [7:0] rx_byte, int unsigned baud_cycles);
      int unsigned bit_cycles;

      bit_cycles = baud_cycles + 1;

      vif.uart_rx <= 1'b1;
      repeat (bit_cycles) @(posedge cr_vif.clk);

      vif.uart_rx <= 1'b0;
      repeat (bit_cycles) @(posedge cr_vif.clk);

      for (int i = 0; i < 8; i++) begin
         vif.uart_rx <= rx_byte[i];
         repeat (bit_cycles) @(posedge cr_vif.clk);
      end

      vif.uart_rx <= 1'b1;
      repeat (bit_cycles) @(posedge cr_vif.clk);
   endtask
endclass
