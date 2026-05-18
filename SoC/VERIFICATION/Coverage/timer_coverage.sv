class timer_coverage extends uvm_subscriber #(timer_transaction);
   `uvm_component_utils(timer_coverage)

   bit        is_write;
   bit [31:0] addr;
   bit [31:0] data;
   bit [2:0]  prot;
   int unsigned sample_count;
   int unsigned write_count;
   int unsigned read_count;
   int unsigned control_count;
   int unsigned period_count;
   int unsigned count_count;
   int unsigned invalid_count;

   covergroup timer_cg;
      option.per_instance = 1;

      cp_rw: coverpoint is_write {
         bins read = {0};
         bins write = {1};
      }

      cp_addr: coverpoint addr[3:0] {
         bins control = {4'h0};
         bins period  = {4'h4};
         bins count   = {4'h8};
         bins invalid = {4'hc};
      }

      cp_prot: coverpoint prot {
         bins p0 = {3'b000};
         bins p1 = {3'b001};
         bins p2 = {3'b010};
         bins p3 = {3'b011};
         bins p4 = {3'b100};
         bins p5 = {3'b101};
         bins p6 = {3'b110};
         bins p7 = {3'b111};
      }

      cp_enable: coverpoint data[0] iff (is_write && addr[3:0] == 4'h0) {
         bins timer_disable = {0};
         bins timer_enable  = {1};
      }

      cp_period: coverpoint data iff (is_write && addr[3:0] == 4'h4) {
         bins zero = {0};
         bins period_small = {[1:10]};
         bins period_mid = {[11:1000]};
         bins period_large = {[1001:$]};
      }

      rw_x_addr: cross cp_rw, cp_addr;
      addr_x_prot : cross cp_addr, cp_prot;

   endgroup // timer_cg

   function new(string name, uvm_component parent);
      super.new(name, parent);
      timer_cg = new();
   endfunction // new

   function void write (timer_transaction t);
      is_write = t.is_write;
      addr = t.addr;
      data = t.is_write ? t.data : t.rdata;
      prot = t.is_write ? t.awprot : t.arprot;

      sample_count++;
      if (t.is_write)
        write_count++;
      else
        read_count++;

      case (t.addr[3:0])
        4'h0: control_count++;
        4'h4: period_count++;
        4'h8: count_count++;
        default: invalid_count++;
      endcase

      timer_cg.sample();
   endfunction // write

   function void report_phase(uvm_phase phase);
      `uvm_info("TIMER_COV", "", UVM_LOW)
      `uvm_info("TIMER_COV", "======================================================", UVM_LOW)
      `uvm_info("TIMER_COV", "              TIMER COVERAGE REPORT                  ", UVM_LOW)
      `uvm_info("TIMER_COV", "======================================================", UVM_LOW)
      `uvm_info("TIMER_COV",
                $sformatf(" Samples              : %0d", sample_count),
                UVM_LOW)
      `uvm_info("TIMER_COV",
                $sformatf(" Access Counts        : WR=%0d RD=%0d", write_count, read_count),
                UVM_LOW)
      `uvm_info("TIMER_COV",
                $sformatf(" Register Hits        : CONTROL=%0d PERIOD=%0d COUNT=%0d INVALID=%0d",
                          control_count, period_count, count_count, invalid_count),
                UVM_LOW)
      `uvm_info("TIMER_COV", "------------------------------------------------------", UVM_LOW)
      `uvm_info("TIMER_COV",
                $sformatf(" RW Coverage          : %.2f%%", timer_cg.cp_rw.get_coverage()),
                UVM_LOW)
      `uvm_info("TIMER_COV",
                $sformatf(" Address Coverage     : %.2f%%", timer_cg.cp_addr.get_coverage()),
                UVM_LOW)
      `uvm_info("TIMER_COV",
                $sformatf(" PROT Coverage        : %.2f%%", timer_cg.cp_prot.get_coverage()),
                UVM_LOW)
      `uvm_info("TIMER_COV",
                $sformatf(" Enable Coverage      : %.2f%%", timer_cg.cp_enable.get_coverage()),
                UVM_LOW)
      `uvm_info("TIMER_COV",
                $sformatf(" Period Coverage      : %.2f%%", timer_cg.cp_period.get_coverage()),
                UVM_LOW)
      `uvm_info("TIMER_COV",
                $sformatf(" RW x Address Cross   : %.2f%%", timer_cg.rw_x_addr.get_coverage()),
                UVM_LOW)
      `uvm_info("TIMER_COV",
                $sformatf(" Addr x PROT Cross    : %.2f%%", timer_cg.addr_x_prot.get_coverage()),
                UVM_LOW)
      `uvm_info("TIMER_COV", "------------------------------------------------------", UVM_LOW)
      `uvm_info("TIMER_COV",
                $sformatf(" TOTAL Timer Coverage : %.2f%%", timer_cg.get_inst_coverage()),
                UVM_LOW)
      `uvm_info("TIMER_COV", "======================================================", UVM_LOW)
   endfunction // report_phase
endclass // timer_coverage
