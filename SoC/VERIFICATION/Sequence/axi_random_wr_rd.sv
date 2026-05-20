class axi_random_wr_rd extends uvm_sequence #(axi_transaction);
  `uvm_object_utils(axi_random_wr_rd)

  function new(string name = "axi_random_wr_rd");
    super.new(name);
  endfunction

  task send_trans(bit [31:0] addr, bit [31:0] data, bit is_write, bit [3:0] wstrb = 4'hf,
                  bit [2:0] prot = 3'b000);
    req = axi_transaction::type_id::create("req");
    start_item(req);
    req.addr     = addr;
    req.data     = data;
    req.is_write = is_write;
    req.wstrb    = wstrb;
    req.awprot   = prot;
    req.arprot   = prot;
    finish_item(req);
  endtask

  virtual task body();
    bit [31:0] written_data[bit [31:0]];
    bit [31:0] r_addr, r_data;
    bit [31:0] iram_addr;

    `uvm_info("SEQ", "--- STARTING SMART RANDOM TEST (ID 11, 12) ---", UVM_LOW)

    written_data.delete();  // Delete all data in array

    for (int i = 0; i < 256; i++) begin
      r_addr = 32'h1000_0000 + (i * 4);
      r_data = $urandom();
      written_data[r_addr] = r_data;
      send_trans(r_addr, r_data, 1'b1, 4'hf);
    end

    foreach (written_data[addr]) begin
      send_trans(addr, 32'h0, 1'b0);
    end

    for (int i = 0; i < 100; i++) begin
      iram_addr = 32'h0000_0000 + (i * 4);
      send_trans(iram_addr, 32'h0, 1'b0);
    end

    `uvm_info("SEQ", "--- DIRECTED COVERAGE CLOSURE ---", UVM_LOW)

    // Data pattern bins: ZERO, ONES, ALT_5A, ALT_A5, WALKING_1, OTHERS
    send_trans(32'h1000_0400, 32'h0000_0000, 1'b1, 4'hf, 3'b000);
    send_trans(32'h1000_0400, 32'h0000_0000, 1'b0, 4'h0, 3'b000);
    send_trans(32'h1000_2000, 32'hFFFF_FFFF, 1'b1, 4'hf, 3'b001);
    send_trans(32'h1000_2000, 32'h0000_0000, 1'b0, 4'h0, 3'b001);
    send_trans(32'h1000_3FFC, 32'hAAAA_5555, 1'b1, 4'hf, 3'b010);
    send_trans(32'h1000_3FFC, 32'h0000_0000, 1'b0, 4'h0, 3'b010);
    send_trans(32'h1000_00A0, 32'h5555_AAAA, 1'b1, 4'hf, 3'b111);
    send_trans(32'h1000_00A0, 32'h0000_0000, 1'b0, 4'h0, 3'b111);

    for (int i = 0; i < 8; i++) begin
      bit [31:0] walk_addr = 32'h1000_2200 + (i * 4);
      bit [31:0] walk_data = 32'h1 << i;
      send_trans(walk_addr, walk_data, 1'b1, 4'hf, 3'b000);
      send_trans(walk_addr, 32'h0, 1'b0, 4'h0, 3'b000);
    end

    // DRAM byte-lane strobe bins.
    send_trans(32'h1000_2300, 32'h0000_0000, 1'b1, 4'hf);
    send_trans(32'h1000_2300, 32'h1111_1111, 1'b1, 4'b0001);
    send_trans(32'h1000_2300, 32'h0000_0000, 1'b0, 4'h0);
    send_trans(32'h1000_2304, 32'h0000_0000, 1'b1, 4'hf);
    send_trans(32'h1000_2304, 32'h2222_2222, 1'b1, 4'b0010);
    send_trans(32'h1000_2304, 32'h0000_0000, 1'b0, 4'h0);
    send_trans(32'h1000_2308, 32'h0000_0000, 1'b1, 4'hf);
    send_trans(32'h1000_2308, 32'h4444_4444, 1'b1, 4'b0100);
    send_trans(32'h1000_2308, 32'h0000_0000, 1'b0, 4'h0);
    send_trans(32'h1000_230C, 32'h0000_0000, 1'b1, 4'hf);
    send_trans(32'h1000_230C, 32'h8888_8888, 1'b1, 4'b1000);
    send_trans(32'h1000_230C, 32'h0000_0000, 1'b0, 4'h0);
    send_trans(32'h1000_2310, 32'h0000_0000, 1'b1, 4'hf);
    send_trans(32'h1000_2310, 32'h3333_3333, 1'b1, 4'b0011);
    send_trans(32'h1000_2310, 32'h0000_0000, 1'b0, 4'h0);
    send_trans(32'h1000_2314, 32'h0000_0000, 1'b1, 4'hf);
    send_trans(32'h1000_2314, 32'hCCCC_CCCC, 1'b1, 4'b1100);
    send_trans(32'h1000_2314, 32'h0000_0000, 1'b0, 4'h0);

    // Peripheral register bins, so this random test is not DRAM-only.
    send_trans(32'h2000_0004, 32'h0000_0020, 1'b1, 4'hf, 3'b001);
    send_trans(32'h2000_0000, 32'h0000_0001, 1'b1, 4'hf, 3'b001);
    send_trans(32'h2000_0000, 32'h0000_0000, 1'b0, 4'h0, 3'b001);
    send_trans(32'h2000_0004, 32'h0000_0000, 1'b0, 4'h0, 3'b001);
    send_trans(32'h2000_0008, 32'h0000_0000, 1'b0, 4'h0, 3'b001);

    send_trans(32'h3000_000C, 32'd115200, 1'b1, 4'hf, 3'b010);
    send_trans(32'h3000_0000, 32'h0000_0041, 1'b1, 4'hf, 3'b010);
    send_trans(32'h3000_0004, 32'h0000_0000, 1'b0, 4'h0, 3'b010);
    send_trans(32'h3000_0008, 32'h0000_0000, 1'b0, 4'h0, 3'b010);
    send_trans(32'h3000_000C, 32'h0000_0000, 1'b0, 4'h0, 3'b010);

    send_trans(32'h4000_0004, 32'h0000_0001, 1'b1, 4'hf, 3'b000);
    send_trans(32'h4000_000C, 32'h0000_0004, 1'b1, 4'hf, 3'b000);
    send_trans(32'h4000_0000, 32'h0000_00A5, 1'b1, 4'hf, 3'b000);
    send_trans(32'h4000_0004, 32'h0000_0000, 1'b0, 4'h0, 3'b000);
    send_trans(32'h4000_0008, 32'h0000_0000, 1'b0, 4'h0, 3'b000);
    send_trans(32'h4000_000C, 32'h0000_0000, 1'b0, 4'h0, 3'b000);

    // Decode-error coverage. Interconnect should return DECERR and DEADBEEF on read.
    send_trans(32'h5000_0000, 32'h1234_5678, 1'b1, 4'hf, 3'b010);
    send_trans(32'h5000_0000, 32'h0000_0000, 1'b0, 4'h0, 3'b010);

    `uvm_info("SEQ", "--- SMART RANDOM COMPLETED ---", UVM_LOW)
  endtask
endclass
