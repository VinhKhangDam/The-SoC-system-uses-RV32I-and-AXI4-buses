`uvm_analysis_imp_decl(_spi)

class spi_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(spi_scoreboard)

  uvm_analysis_imp_spi #(spi_transaction, spi_scoreboard)       imp;

  bit                                                     [7:0] exp_tx_byte;
  bit                                                     [7:0] exp_rx_byte;
  bit                                                           exp_rx_valid;
  bit                                                           exp_busy;
  bit                                                     [31:0] exp_ctrl_reg;
  bit                                                     [31:0] exp_baud_reg;

  int                                                           pass_count;
  int                                                           fail_count;
  int                                                           write_count;
  int                                                           read_count;
  int                                                           start_count;
  int                                                           pin_transfer_count;
  int                                                           rx_read_count;
  int                                                           status_read_count;
  int                                                           ignored_write_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    imp = new("imp", this);
    exp_ctrl_reg = 32'h0000_0008;
    exp_baud_reg = 32'd10;
  endfunction

  function void write_spi(spi_transaction tr);
    bit [31:0] expected;

    if (tr.op == SPI_EXPECT_TRANSFER) begin
      exp_rx_byte  = tr.exp_rx_byte;
      exp_rx_valid = 1'b1;
      exp_busy     = 1'b1;
      start_count++;
      pass_count++;
      `uvm_info("SPI_SCB", $sformatf("EXPECT TRANSFER rx=%02h", exp_rx_byte), UVM_LOW)
      return;
    end

    if (tr.op == SPI_PIN_TRANSFER) begin
      pin_transfer_count++;

      if (exp_rx_valid && tr.miso_byte !== exp_rx_byte) begin
        fail_count++;
        `uvm_error("SPI_SCB", $sformatf("PIN MISO FAIL expected=%02h got=%02h", exp_rx_byte,
                                        tr.miso_byte))
      end else begin
        pass_count++;
        `uvm_info("SPI_SCB", $sformatf("PIN TRANSFER PASS miso=%02h", tr.miso_byte), UVM_LOW)
      end
      return;
    end

    if (tr.op == SPI_AXI_WRITE) begin
      write_count++;

      if (tr.wstrb !== 4'hf) begin
        fail_count++;
        `uvm_error("SPI_SCB", $sformatf("WRITE FAIL addr=%h bad wstrb=%b", tr.addr, tr.wstrb))
        return;
      end

      case (tr.addr[3:0])
        4'h0: begin
          exp_tx_byte = tr.data[7:0];
          pass_count++;
          `uvm_info("SPI_SCB", $sformatf("DATA WRITE PASS tx=%02h", exp_tx_byte), UVM_LOW)
        end

        4'h4: begin
          exp_ctrl_reg = tr.data;
          pass_count++;
          if (tr.data[0] || tr.is_start_transfer)
            `uvm_info("SPI_SCB", $sformatf("CTRL START WRITE data=%h", tr.data), UVM_LOW)
          else
            `uvm_info("SPI_SCB", $sformatf("CTRL WRITE PASS data=%h", tr.data), UVM_LOW)
        end

        4'h8: begin
          ignored_write_count++;
          pass_count++;
          `uvm_info("SPI_SCB", $sformatf("WRITE IGNORED addr=%h data=%h", tr.addr, tr.data),
                    UVM_LOW)
        end

        4'hc: begin
          exp_baud_reg = tr.data;
          pass_count++;
          `uvm_info("SPI_SCB", $sformatf("BAUD WRITE PASS data=%h", tr.data), UVM_LOW)
        end

        default: begin
          ignored_write_count++;
          pass_count++;
          `uvm_info("SPI_SCB", $sformatf("WRITE IGNORED invalid addr=%h data=%h", tr.addr, tr.data),
                    UVM_LOW)
        end
      endcase
      return;
    end

    if (tr.op == SPI_AXI_READ) begin
      read_count++;

      case (tr.addr[3:0])
        4'h0: begin
          rx_read_count++;
          if (exp_rx_valid) begin
            expected = {24'h0, exp_rx_byte};
            if (tr.rdata !== expected) begin
              fail_count++;
              `uvm_error("SPI_SCB", $sformatf("DATA RX READ FAIL expected=%h got=%h", expected,
                                              tr.rdata))
            end else begin
              pass_count++;
              `uvm_info("SPI_SCB", $sformatf("DATA RX READ PASS got=%h", tr.rdata), UVM_LOW)
            end
            exp_rx_valid = 1'b0;
            exp_busy     = 1'b0;
          end else begin
            pass_count++;
            `uvm_info("SPI_SCB", $sformatf("DATA RX READ no expected rx, got=%h", tr.rdata),
                      UVM_LOW)
          end
        end

        4'h4: begin
          if (tr.rdata !== exp_ctrl_reg) begin
            fail_count++;
            `uvm_error("SPI_SCB", $sformatf("CTRL READ FAIL expected=%h got=%h", exp_ctrl_reg,
                                            tr.rdata))
          end else begin
            pass_count++;
            `uvm_info("SPI_SCB", $sformatf("CTRL READ PASS got=%h", tr.rdata), UVM_LOW)
          end
        end

        4'h8: begin
          status_read_count++;
          if ($isunknown(tr.rdata)) begin
            fail_count++;
            `uvm_error("SPI_SCB", $sformatf("STATUS FAIL X/Z got=%h", tr.rdata))
          end else begin
            pass_count++;
            `uvm_info("SPI_SCB", $sformatf("STATUS PASS got=%h", tr.rdata), UVM_LOW)
          end
        end

        4'hc: begin
          if (tr.rdata !== exp_baud_reg) begin
            fail_count++;
            `uvm_error("SPI_SCB", $sformatf("BAUD READ FAIL expected=%h got=%h", exp_baud_reg,
                                            tr.rdata))
          end else begin
            pass_count++;
            `uvm_info("SPI_SCB", $sformatf("BAUD READ PASS got=%h", tr.rdata), UVM_LOW)
          end
        end

        default: begin
          expected = 32'hDEAD_BEEF;
          if (tr.rdata !== expected) begin
            fail_count++;
            `uvm_error("SPI_SCB", $sformatf("INVALID READ FAIL expected=%h got=%h", expected,
                                            tr.rdata))
          end else begin
            pass_count++;
            `uvm_info("SPI_SCB", $sformatf("INVALID READ PASS got=%h", tr.rdata), UVM_LOW)
          end
        end
      endcase
    end
  endfunction

  function void check_phase(uvm_phase phase);
    if (fail_count == 0)
      `uvm_info("SPI_SCB", $sformatf(
                "SPI PASS pass=%0d fail=%0d writes=%0d reads=%0d starts=%0d pin_transfers=%0d rx_reads=%0d status_reads=%0d ignored_writes=%0d",
                pass_count,
                fail_count,
                write_count,
                read_count,
                start_count,
                pin_transfer_count,
                rx_read_count,
                status_read_count,
                ignored_write_count
                ), UVM_LOW)
    else
      `uvm_error("SPI_SCB", $sformatf(
                 "SPI FAIL pass=%0d fail=%0d writes=%0d reads=%0d starts=%0d pin_transfers=%0d rx_reads=%0d status_reads=%0d ignored_writes=%0d",
                 pass_count,
                 fail_count,
                 write_count,
                 read_count,
                 start_count,
                 pin_transfer_count,
                 rx_read_count,
                 status_read_count,
                 ignored_write_count
                 ))
  endfunction
endclass
