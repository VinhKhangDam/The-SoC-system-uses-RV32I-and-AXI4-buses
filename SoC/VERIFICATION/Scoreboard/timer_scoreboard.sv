`uvm_analysis_imp_decl(_timer)

class timer_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(timer_scoreboard)

  uvm_analysis_imp_timer #(timer_transaction, timer_scoreboard)        imp;

  bit                                                           [31:0] exp_control;
  bit                                                           [31:0] exp_period;
  bit                                                           [31:0] exp_count;
  time                                                                 last_model_time;
  bit                                                                  model_started;
  int                                                                  pass_count;
  int                                                                  fail_count;
  int                                                                  write_count;
  int                                                                  read_count;
  int                                                                  ignored_write_count;
  int                                                                  count_read_count;
  int                                                                  count_check_count;

  localparam longint unsigned CLK_PERIOD = 10_000;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    imp = new("imp", this);
    exp_control = 32'h0;
    exp_period = 32'h0;
    exp_count = 32'h0;
    last_model_time = 0;
    model_started = 1'b0;
  endfunction  // new

  function void start_or_advance_model();
    time now_time;
    longint unsigned elapsed_cycles;

    now_time = $time;
    if (!model_started) begin
      model_started   = 1'b1;
      last_model_time = now_time;
      return;
    end

    if (now_time <= last_model_time) return;

    elapsed_cycles = (now_time - last_model_time) / CLK_PERIOD;
    while (elapsed_cycles > 0) begin
      tick_model();
      elapsed_cycles--;
    end

    last_model_time = now_time;
  endfunction

  function void tick_model();
    if (exp_control[0]) begin
      if (exp_period != 32'h0 && exp_count >= exp_period) exp_count = 32'h0;
      else exp_count = exp_count + 1'b1;
    end else begin
      exp_count = 32'h0;
    end
  endfunction

  function bit count_matches(bit [31:0] actual);
    bit [31:0] probe;

    if (!exp_control[0]) return (actual == 32'h0);

    if (exp_period != 32'h0 && actual <= exp_period) return 1'b1;

    if (exp_period == 32'h0) begin
      for (int i = 0; i < 8; i++) begin
        if (actual == (exp_count + i)) return 1'b1;
        if (exp_count >= i && actual == (exp_count - i)) return 1'b1;
      end
      return 1'b0;
    end

    probe = exp_count;
    for (int i = 0; i < 4; i++) begin
      if (actual == probe) return 1'b1;

      if (exp_period != 32'h0 && probe >= exp_period) probe = 32'h0;
      else probe = probe + 1'b1;
    end

    return 1'b0;
  endfunction

  function void write_timer(timer_transaction tr);
    bit [31:0] expected;

    start_or_advance_model();

    if (tr.is_write) begin
      write_count++;

      if (tr.wstrb !== 4'hf) begin
        fail_count++;
        `uvm_error("TIMER_SCB",
                   $sformatf("WRITE FAIL addr=%h data=%h wstrb=%b expected full-word wstrb=1111",
                             tr.addr, tr.data, tr.wstrb))
        return;
      end

      case (tr.addr[3:0])
        4'h0: begin
          exp_control = tr.data;
          if (!tr.data[0]) exp_count = 32'h0;
          pass_count++;
          `uvm_info("TIMER_SCB", $sformatf(
                    "WRITE PASS CONTROL addr=%h data=%h awprot=%b", tr.addr, tr.data, tr.awprot),
                    UVM_LOW)
        end
        4'h4: begin
          exp_period = tr.data;
          pass_count++;
          `uvm_info("TIMER_SCB", $sformatf(
                    "WRITE PASS PERIOD addr=%h data=%h awprot=%b", tr.addr, tr.data, tr.awprot),
                    UVM_LOW)
        end
        default: begin
          ignored_write_count++;
          `uvm_info("TIMER_SCB", $sformatf(
                    "WRITE IGNORED addr=%h data=%h awprot=%b", tr.addr, tr.data, tr.awprot),
                    UVM_LOW)
        end
      endcase  // case (tr.addr[3:0])
      return;
    end

    read_count++;

    case (tr.addr[3:0])
      4'h0: expected = exp_control;
      4'h4: expected = exp_period;
      4'h8: begin
        count_read_count++;
        if (count_matches(tr.rdata)) begin
          pass_count++;
          count_check_count++;
          `uvm_info("TIMER_SCB", $sformatf("COUNT PASS got=%h model=%h control=%h period=%h",
                                           tr.rdata, exp_count, exp_control, exp_period), UVM_LOW)
        end else begin
          fail_count++;
          `uvm_error("TIMER_SCB", $sformatf(
                     "COUNT FAIL got=%h model=%h control=%h period=%h",
                     tr.rdata,
                     exp_count,
                     exp_control,
                     exp_period
                     ))
        end
        return;
      end
      default: expected = 32'hDEAD_BEEF;
    endcase  // case (tr.addr[3:0])

    if (tr.rdata !== expected) begin
      fail_count++;
      `uvm_error("TIMER_SCB", $sformatf("READ FAIL addr=%h expected=%h got=%h", tr.addr, expected,
                                        tr.rdata))
    end else begin
      pass_count++;
      `uvm_info("TIMER_SCB", $sformatf("READ PASS addr=%h got=%h", tr.addr, tr.rdata), UVM_LOW)
    end
  endfunction  // write_timer

  function void check_phase(uvm_phase phase);
    if (fail_count == 0)
      `uvm_info("TIMER_SCB", $sformatf(
                "TIMER PASS pass=%0d fail=%0d writes=%0d reads=%0d ignored_writes=%0d count_reads=%0d count_checks=%0d",
                pass_count,
                fail_count,
                write_count,
                read_count,
                ignored_write_count,
                count_read_count,
                count_check_count
                ), UVM_LOW)
    else
      `uvm_error("TIMER_SCB", $sformatf(
                 "TIMER FAIL pass=%0d fail=%0d writes=%0d reads=%0d ignored_writes=%0d count_reads=%0d count_checks=%0d",
                 pass_count,
                 fail_count,
                 write_count,
                 read_count,
                 ignored_write_count,
                 count_read_count,
                 count_check_count
                 ))
  endfunction  // check_phase
endclass  // timer_scoreboard
