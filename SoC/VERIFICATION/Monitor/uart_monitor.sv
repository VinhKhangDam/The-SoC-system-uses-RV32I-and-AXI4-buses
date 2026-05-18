class uart_monitor extends uvm_monitor;
   `uvm_component_utils(uart_monitor)

   virtual soc_inf vif;
   uvm_analysis_port #(uart_transaction) ap;

   function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
   endfunction

   function void build_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual soc_inf)::get(this, "", "vif", vif))
        `uvm_fatal("UART_MON", "Cannot get vif")
   endfunction

   task run_phase(uvm_phase phase);
      uart_transaction tr;
      bit [31:0] awaddr_q;
      bit [2:0]  awprot_q;
      bit [31:0] araddr_q;
      bit [2:0]  arprot_q;

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
            tr = uart_transaction::type_id::create("wr_tr");
            tr.op     = UART_AXI_WRITE;
            tr.addr   = awaddr_q;
            tr.awprot = awprot_q;
            tr.data   = vif.mon_cb.wdata;
            tr.wstrb  = vif.mon_cb.wstrb;
            `uvm_info("UART_MON_WR",
                      $sformatf("WRITE : Addr=%h Data=%h Prot=%b Strb=%b",
                                tr.addr, tr.data, tr.awprot, tr.wstrb)
                      , UVM_LOW)
            ap.write(tr);
         end

         if (vif.mon_cb.rvalid && vif.mon_cb.rready) begin
            tr = uart_transaction::type_id::create("rd_tr");
            tr.op     = UART_AXI_READ;
            tr.addr   = araddr_q;
            tr.arprot = arprot_q;
            tr.rdata  = vif.mon_cb.rdata;
            tr.resp   = vif.mon_cb.rresp;
            `uvm_info("UART_MON_RD",
                      $sformatf("READ : Addr = %h Data = %h Prot = %b Resp = %b",
                                tr.addr, tr.data, tr.arprot, tr.resp),
                      UVM_LOW)
            ap.write(tr);
         end
      end
   endtask
endclass
