class timer_sequence extends uvm_sequence #(timer_transaction);
   `uvm_object_utils(timer_sequence)

   function new(string name = "timer_sequence");
      super.new(name);
   endfunction // new

   task body();
      `uvm_info("TIMER_SEQ", "Start Timer default/corner/stress sequence", UVM_LOW)

      // Default/reset-visible state checks.
      write_reg(32'h2000_0000, 32'h0, 3'b000);
      read_reg(32'h2000_0000, 3'b000);
      read_reg(32'h2000_0004, 3'b000);
      read_reg(32'h2000_0008, 3'b000);
      read_reg(32'h2000_000C, 3'b000);

      // Basic enable/period/count flow.
      write_reg(32'h2000_0004, 32'd5, 3'b001);
      read_reg(32'h2000_0004, 3'b001);

      write_reg(32'h2000_0000, 32'h1, 3'b010);

      repeat(20)
        read_reg(32'h2000_0008, 3'b010);

      write_reg(32'h2000_0000, 32'h0, 3'b011);
      read_reg(32'h2000_0000, 3'b011);

      read_reg(32'h2000_000C, 3'b100);

      // Corner cases: period 0, tiny periods, large period, invalid writes, all PROT values.
      write_reg(32'h2000_0004, 32'd0, 3'b101);
      write_reg(32'h2000_0000, 32'h1, 3'b101);
      repeat(8) read_reg(32'h2000_0008, 3'b101);

      write_reg(32'h2000_0000, 32'h0, 3'b110);
      write_reg(32'h2000_0004, 32'd1, 3'b110);
      write_reg(32'h2000_0000, 32'h1, 3'b110);
      repeat(12) read_reg(32'h2000_0008, 3'b110);

      write_reg(32'h2000_0000, 32'h0, 3'b111);
      write_reg(32'h2000_0004, 32'hffff_ffff, 3'b111);
      read_reg(32'h2000_0004, 3'b111);

      write_reg(32'h2000_000C, 32'h1234_5678, 3'b011);
      read_reg(32'h2000_000C, 3'b011);

      for (int p = 0; p < 8; p++) begin
         write_reg(32'h2000_0000, {31'h0, p[0]}, p[2:0]);
         read_reg(32'h2000_0000, p[2:0]);
         write_reg(32'h2000_0004, p + 1, p[2:0]);
         read_reg(32'h2000_0004, p[2:0]);
      end

      // Stress: random read/write traffic across legal and invalid Timer offsets.
      repeat(300) begin
         timer_transaction tr;
         tr = timer_transaction::type_id::create("rand_tr");
         start_item(tr);
         assert(tr.randomize() with {
            is_write dist {1'b1 := 45, 1'b0 := 55};
            if (is_write) {
               addr dist {
                  32'h2000_0000 := 35,
                  32'h2000_0004 := 45,
                  32'h2000_000C := 20
               };
            } else {
               addr dist {
                  32'h2000_0000 := 20,
                  32'h2000_0004 := 20,
                  32'h2000_0008 := 40,
                  32'h2000_000C := 20
               };
            }
            if (addr == 32'h2000_0000)
               data inside {32'h0, 32'h1, 32'h2, 32'h3};
            if (addr == 32'h2000_0004)
               data inside {32'd0, [32'd1:32'd20], 32'd100, 32'hffff_ffff};
            wstrb == 4'hf;
         });
         finish_item(tr);
      end

      write_reg(32'h2000_0000, 32'h0, 3'b000);
      read_reg(32'h2000_0000, 3'b000);
      read_reg(32'h2000_0008, 3'b000);

      `uvm_info("TIMER_SEQ", "Finished Timer default/corner/stress sequence", UVM_LOW)
   endtask // body

   task write_reg(bit[31:0] addr, bit [31:0] data, bit [2:0] prot);
      timer_transaction tr;
      tr = timer_transaction::type_id::create("wr");
      start_item(tr);
      tr.is_write = 1'b1;
      tr.addr = addr;
      tr.data = data;
      tr.wstrb = 4'hf;
      tr.awprot = prot;
      tr.arprot = 3'b000;
      finish_item(tr);
   endtask // write_reg

   task read_reg(bit[31:0] addr, bit[2:0] prot);
      timer_transaction tr;
      tr = timer_transaction::type_id::create("rd");
      start_item(tr);
      tr.is_write = 1'b0;
      tr.addr = addr;
      tr.data = '0;
      tr.wstrb = 4'hf;
      tr.awprot = 3'b000;
      tr.arprot = prot;
      finish_item(tr);
   endtask // read_reg
endclass // timer_sequence
