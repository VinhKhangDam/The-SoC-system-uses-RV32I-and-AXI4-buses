class timer_monitor extends uvm_monitor;
   `uvm_component_utils(timer_monitor)

   virtual soc_inf vif;
   uvm_analysis_port #(timer_transaction) ap;

   function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
   endfunction // new

   function void build_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual soc_inf)::get(this, "", "vif", vif))
          `uvm_fatal("TIMER_MON", "Cannot get vif")
   endfunction // build_phase

   task run_phase(uvm_phase phase);
          timer_transaction tr;
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
                 tr = timer_transaction::type_id::create("wr_tr");
                 tr.is_write = 1'b1;
                 tr.addr = awaddr_q;
                 tr.awprot = awprot_q;
                 tr.data = vif.mon_cb.wdata;
                 tr.wstrb = vif.mon_cb.wstrb;
                 ap.write(tr);
             end

             if (vif.mon_cb.rready && vif.mon_cb.rvalid) begin
                 tr = timer_transaction::type_id::create("rd_tr");
                 tr.is_write = 1'b0;
                 tr.addr = araddr_q;
                 tr.arprot = arprot_q;
                 tr.rdata = vif.mon_cb.rdata;
                 tr.resp =  vif.mon_cb.rresp;
                 ap.write(tr);
             end
          end
   endtask // run_phase

endclass // timer_monitor
