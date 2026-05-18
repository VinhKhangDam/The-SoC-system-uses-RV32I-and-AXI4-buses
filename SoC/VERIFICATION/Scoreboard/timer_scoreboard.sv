`uvm_analysis_imp_decl(_timer)

class timer_scoreboard extends uvm_scoreboard;
   `uvm_component_utils(timer_scoreboard)

   uvm_analysis_imp_timer #(timer_transaction, timer_scoreboard) imp;

   bit [31:0] exp_control;
   bit [31:0] exp_period;
   int        pass_count;
   int        fail_count;
   int        write_count;
   int        read_count;
   int        ignored_write_count;

   function new(string name, uvm_component parent);
      super.new(name, parent);
      imp = new("imp", this);
      exp_control = 32'h0;
      exp_period = 32'h0;
   endfunction // new

   function void write_timer (timer_transaction tr);
      bit [31:0] expected;

      if (tr.is_write) begin
         write_count++;

         if (tr.wstrb !== 4'hf) begin
            fail_count++;
            `uvm_error("TIMER_SCB",
               $sformatf("WRITE FAIL addr=%h data=%h wstrb=%b expected full-word wstrb=1111",
                  tr.addr, tr.data, tr.wstrb))
            return;
         end

         case(tr.addr[3:0])
           4'h0: begin
              exp_control = tr.data;
              pass_count++;
              `uvm_info("TIMER_SCB",
                 $sformatf("WRITE PASS CONTROL addr=%h data=%h awprot=%b",
                    tr.addr, tr.data, tr.awprot),
                 UVM_LOW)
           end
           4'h4: begin
              exp_period = tr.data;
              pass_count++;
              `uvm_info("TIMER_SCB",
                 $sformatf("WRITE PASS PERIOD addr=%h data=%h awprot=%b",
                    tr.addr, tr.data, tr.awprot),
                 UVM_LOW)
           end
           default: begin
              ignored_write_count++;
              `uvm_info("TIMER_SCB",
                 $sformatf("WRITE IGNORED addr=%h data=%h awprot=%b",
                    tr.addr, tr.data, tr.awprot),
                 UVM_LOW)
           end
         endcase // case (tr.addr[3:0])
         return;
      end

      read_count++;

      case (tr.addr[3:0])
         4'h0: expected = exp_control;
         4'h4: expected = exp_period;
         4'h8: begin
            `uvm_info("TIMER_SCB", $sformatf("COUNT volatile read = %h", tr.rdata), UVM_LOW)
            return;
         end
        default: expected = 32'hDEAD_BEEF;
      endcase // case (tr.addr[3:0])

      if (tr.rdata !== expected) begin
         fail_count++;
         `uvm_error("TIMER_SCB", $sformatf("READ FAIL addr=%h expected=%h got=%h", tr.addr, expected, tr.rdata))
      end else begin
         pass_count++;
         `uvm_info("TIMER_SCB", $sformatf("READ PASS addr=%h got=%h", tr.addr, tr.rdata), UVM_LOW)
      end
   endfunction // write_timer

   function void check_phase(uvm_phase phase);
      if (fail_count == 0)
        `uvm_info("TIMER_SCB",
                  $sformatf("TIMER PASS pass=%0d fail=%0d writes=%0d reads=%0d ignored_writes=%0d",
                            pass_count, fail_count, write_count, read_count, ignored_write_count),
                  UVM_LOW)
      else
        `uvm_error("TIMER_SCB",
                   $sformatf("TIMER FAIL pass=%0d fail=%0d writes=%0d reads=%0d ignored_writes=%0d",
                             pass_count, fail_count, write_count, read_count, ignored_write_count))
   endfunction // check_phase
endclass // timer_scoreboard
