`uvm_analysis_imp_decl(_uart)

class uart_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(uart_scoreboard)

  uvm_analysis_imp_uart #(uart_transaction, uart_scoreboard)        imp;

  bit                                                        [31:0] exp_baud           = 32'd115200;
  bit                                                        [ 7:0] exp_rx_byte;
  bit                                                               exp_rx_valid;
  int                                                               pass_count;
  int                                                               fail_count;
  int                                                               write_count;
  int                                                               read_count;
  int                                                               tx_write_count;
  int                                                               rx_read_count;
  int                                                               status_read_count;
  int                                                               rx_expect_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    imp = new("imp", this);
    exp_baud = 32'd115200;
  endfunction

  function void write_uart(uart_transaction tr);
    bit [31:0] expected;

    if (tr.op == UART_RX_BYTE) begin
      exp_rx_byte  = tr.rx_byte;
      exp_rx_valid = 1'b1;
      rx_expect_count++;
      pass_count++;
      `uvm_info("UART_SCB", $sformatf("RX EXPECT byte=%02h baud_cycles=%0d", tr.rx_byte,
                                      tr.baud_cycles), UVM_LOW)
      return;
    end

    if (tr.op == UART_AXI_WRITE) begin
      write_count++;

      if (tr.wstrb !== 4'hf) begin
        fail_count++;
        `uvm_error("UART_SCB", $sformatf("WRITE FAIL addr=%h bad wstrb=%b", tr.addr, tr.wstrb))
        return;
      end

      case (tr.addr[3:0])
        4'h0: begin
          tx_write_count++;
          pass_count++;
          `uvm_info("UART_SCB", $sformatf(
                    "TXDATA WRITE PASS byte=%02h awprot=%b", tr.data[7:0], tr.awprot), UVM_LOW)
        end
        4'hc: begin
          exp_baud = tr.data;
          pass_count++;
          `uvm_info("UART_SCB", $sformatf("BAUD WRITE PASS data=%0d awprot=%b", tr.data, tr.awprot),
                    UVM_LOW)
        end
        default: begin
          pass_count++;
          `uvm_info("UART_SCB", $sformatf("WRITE IGNORED addr=%h data=%h", tr.addr, tr.data),
                    UVM_LOW)
        end
      endcase
      return;
    end

    if (tr.op == UART_AXI_READ) begin
      read_count++;

      case (tr.addr[3:0])
        4'h0: expected = 32'h0000_0000;
        4'h4: begin
          rx_read_count++;
          if (exp_rx_valid) begin
            expected = {24'h0, exp_rx_byte};
            if (tr.rdata !== expected) begin
              fail_count++;
              `uvm_error("UART_SCB", $sformatf("RXDATA FAIL expected=%h got=%h", expected,
                                               tr.rdata))
            end else begin
              pass_count++;
              `uvm_info("UART_SCB", $sformatf("RXDATA PASS got=%h", tr.rdata), UVM_LOW)
            end
            exp_rx_valid = 1'b0;
          end else begin
            pass_count++;
            `uvm_info("UART_SCB", $sformatf(
                      "RXDATA READ with no expected RX byte, got stale/idle value=%h", tr.rdata),
                      UVM_LOW)
          end
          return;
        end
        4'h8: begin
          status_read_count++;
          if (tr.rdata[1] !== exp_rx_valid) begin
            fail_count++;
            `uvm_error("UART_SCB", $sformatf("STATUS RX_READY FAIL expected=%0b got=%0b status=%h",
                                             exp_rx_valid, tr.rdata[1], tr.rdata))
          end else begin
            pass_count++;
            `uvm_info(
                "UART_SCB", $sformatf(
                "STATUS PASS status=%h tx_busy=%0b rx_ready=%0b", tr.rdata, tr.rdata[0], tr.rdata[1]
                ), UVM_LOW)
          end
          return;
        end
        4'hc: expected = exp_baud;
        default: expected = 32'h0000_0000;
      endcase

      if (tr.rdata !== expected) begin
        fail_count++;
        `uvm_error("UART_SCB", $sformatf("READ FAIL addr=%h expected=%h got=%h", tr.addr, expected,
                                         tr.rdata))
      end else begin
        pass_count++;
        `uvm_info("UART_SCB", $sformatf("READ PASS addr=%h got=%h", tr.addr, tr.rdata), UVM_LOW)
      end
    end  // if (tr.op == UART_AXI_READ)

  endfunction

  function void check_phase(uvm_phase phase);
    if (fail_count == 0)
      `uvm_info("UART_SCB", $sformatf(
                "UART PASS pass=%0d fail=%0d writes=%0d reads=%0d tx=%0d rx_expect=%0d rx_reads=%0d status_reads=%0d",
                pass_count,
                fail_count,
                write_count,
                read_count,
                tx_write_count,
                rx_expect_count,
                rx_read_count,
                status_read_count
                ), UVM_LOW)
    else `uvm_error("UART_SCB", $sformatf("UART FAIL pass=%0d fail=%0d", pass_count, fail_count))
  endfunction
endclass
