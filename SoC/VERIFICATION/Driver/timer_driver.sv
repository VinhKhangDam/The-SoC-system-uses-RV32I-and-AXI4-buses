class timer_driver extends uvm_driver #(timer_transaction);
   `uvm_component_utils(timer_driver)

   virtual soc_inf vif;

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction // new

   function void build_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual soc_inf)::get(this, "", "vif", vif))
          `uvm_fatal("TIMER_DRV", "Cannot get vif")
   endfunction // build_phase

   task run_phase(uvm_phase phase);
        timer_transaction tr;

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

        forever begin
            seq_item_port.get_next_item(tr);

            if (tr.is_write)
                drive_write(tr);
            else
                drive_read(tr);

            seq_item_port.item_done();
        end
   endtask // run_phase

   task drive_write(timer_transaction tr);
          vif.drv_cb.awaddr <= tr.addr;
          vif.drv_cb.awprot <= tr.awprot;
          vif.drv_cb.wdata  <= tr.data;
          vif.drv_cb.wstrb  <= tr.wstrb;
          vif.drv_cb.awvalid <= 1'b1;
          vif.drv_cb.wvalid  <= 1'b0;
          vif.drv_cb.bready  <= 1'b1;

          do @(vif.drv_cb);
          while (!vif.drv_cb.awready);
          vif.drv_cb.awvalid <= 1'b0;

          vif.drv_cb.wvalid  <= 1'b1;
          do @(vif.drv_cb);
          while (!vif.drv_cb.wready);
          vif.drv_cb.wvalid  <= 1'b0;

          do @(vif.drv_cb);
          while (!vif.drv_cb.bvalid);
          tr.resp = vif.drv_cb.bresp;

          @(vif.drv_cb);
          vif.drv_cb.bready  <= 1'b0;
   endtask // drive_write

   task drive_read(timer_transaction tr);
          vif.drv_cb.araddr  <= tr.addr;
          vif.drv_cb.arprot  <= tr.arprot;
          vif.drv_cb.arvalid <= 1'b1;
          vif.drv_cb.rready  <= 1'b1;

          do @(vif.drv_cb);
          while (!vif.drv_cb.arready);
          vif.drv_cb.arvalid <= 1'b0;

          do @(vif.drv_cb);
          while (!vif.drv_cb.rvalid);
          tr.rdata = vif.drv_cb.rdata;
          tr.resp = vif.drv_cb.rresp;

          @(vif.drv_cb);
          vif.drv_cb.rready  <= 1'b0;
   endtask
endclass
