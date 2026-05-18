class uart_sequence extends uvm_sequence #(uart_transaction);
   `uvm_object_utils(uart_sequence)

   function new(string name = "uart_sequence");
      super.new(name);
   endfunction // new

   task body();
      int unsigned cur_baud;

      cur_baud = 8;
      write_reg(32'h3000_000C, 32'd8, 3'b000);
      read_reg (32'h3000_000C, 3'b000);
      read_reg (32'h3000_0004, 3'b000);
      read_reg (32'h3000_0008, 3'b000);

      write_reg(32'h3000_0000, 32'h55, 3'b001);
      repeat (15) read_reg(32'h3000_0008, 3'b001);

      rx_byte(8'ha5, 8);
      repeat (100) read_reg(32'h3000_0008, 3'b010);
      read_reg(32'h3000_0004, 3'b010);
      read_reg(32'h3000_0008, 3'b010);

      rx_byte(8'h11, 8);
      rx_byte(8'h22, 8);
      repeat (120) read_reg(32'h3000_0008, 3'b001);
      read_reg(32'h3000_0004, 3'b001);
      read_reg(32'h3000_0008, 3'b001);

      write_reg(32'h3000_000C, 32'd4, 3'b011);
      write_reg(32'h3000_0000, 32'haa, 3'b011);
      write_reg(32'h3000_0000, 32'h5a, 3'b011);
      read_reg(32'h3000_0008, 3'b011);
      rx_byte(8'h3c, 4);
      repeat (80) read_reg(32'h3000_0008, 3'b011);
      read_reg(32'h3000_0004, 3'b011);

      write_reg(32'h3000_000C, 32'd16, 3'b100);
      write_reg(32'h3000_0000, 32'h00, 3'b100);
      write_reg(32'h3000_0000, 32'hff, 3'b101);

      for (int p = 0; p < 8; p++) begin
         write_reg(32'h3000_000C, p + 4, p[2:0]);
         read_reg(32'h3000_000C, p[2:0]);
      end

      cur_baud = 8;
      write_reg(32'h3000_000C, cur_baud, 3'b000);

      repeat (200) begin
         uart_transaction tr;
         tr = uart_transaction::type_id::create("rand_tr");

         start_item(tr);
         assert(tr.randomize() with {
            op dist {
               UART_AXI_WRITE := 45,
               UART_AXI_READ  := 45,
               UART_RX_BYTE   := 10
            };

            if (op == UART_AXI_WRITE) {
               addr dist {
                  32'h3000_0000 := 60,
                  32'h3000_000C := 30,
                  32'h3000_0004 := 5,
                  32'h3000_0008 := 5
               };
            }

            if (op == UART_AXI_READ) {
               addr dist {
                  32'h3000_0004 := 25,
                  32'h3000_0008 := 45,
                  32'h3000_000C := 30
               };
            }

            if (addr == 32'h3000_000C)
               data inside {32'd4, 32'd8, 32'd16, 32'd32};

            if (op == UART_RX_BYTE)
               baud_cycles == cur_baud;

            wstrb == 4'hf;
         });
         finish_item(tr);

         if (tr.op == UART_AXI_WRITE && tr.addr == 32'h3000_000C)
           cur_baud = tr.data;
      end
   endtask // body

   task write_reg(bit [31:0] addr, bit[31:0] data, bit[2:0] prot);
      uart_transaction tr;
      tr = uart_transaction::type_id::create("wr");
      start_item(tr);
      tr.op = UART_AXI_WRITE;
      tr.addr = addr;
      tr.data = data;
      tr.wstrb = 4'hf;
      tr.awprot = prot;
      finish_item(tr);
   endtask // write_reg

   task read_reg(bit [31:0] addr, bit[2:0] prot);
      uart_transaction tr;
      tr = uart_transaction::type_id::create("rd");
      start_item(tr);
      tr.op = UART_AXI_READ;
      tr.addr = addr;
      tr.wstrb = 4'hf;
      tr.arprot = prot;
      finish_item(tr);
   endtask // read_reg

   task rx_byte(bit [7:0] data, int unsigned baud);
      uart_transaction tr;
      tr = uart_transaction::type_id::create("rx");
      start_item(tr);
      tr.op = UART_RX_BYTE;
      tr.rx_byte = data;
      tr.baud_cycles = baud;
      finish_item(tr);
   endtask // rx_byte
endclass // uart_sequence
