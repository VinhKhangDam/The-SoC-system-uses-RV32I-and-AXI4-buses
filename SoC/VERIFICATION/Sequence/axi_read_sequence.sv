class axi_read_sequence extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(axi_read_sequence)

    function new(string name = "axi_read_sequence");
        super.new(name);
    endfunction //new()

    task send_write (bit [31:0] addr, bit [31:0] data);
        req = axi_transaction::type_id::create("req");
        start_item(req);
        req.addr = addr;
        req.data = data;
        req.is_write = 1'b1;
        req.wstrb = 4'hF;
        finish_item(req);
    endtask

    task send_read (bit [31:0] addr);
        req = axi_transaction::type_id::create("req");
        start_item(req);
        req.addr = addr;
        req.data = 32'h0;
        req.is_write = 1'b0;
        req.wstrb = 4'h0;
        finish_item(req);
    endtask

    virtual task body();
        `uvm_info("SEQ", "Basic AXI4-Lite Read", UVM_LOW)

        // --- Setup: write boundary and special values ---
        send_write(32'h1000_0010, 32'h0000_0000); // Zero
        send_write(32'h1000_0014, 32'hFFFF_FFFF); // All ones
        send_write(32'h1000_0018, 32'h5555_AAAA); // Alternating pattern
        send_write(32'h1000_001C, 32'hAAAA_5555); // Inverse pattern
        send_write(32'h1000_0020, 32'h0000_0001); // LSB only
        send_write(32'h1000_0024, 32'h8000_0000); // MSB only

        // Read from address
        send_read(32'h1000_0010);
        send_read(32'h1000_0014);
        send_read(32'h1000_0018);
        send_read(32'h1000_001C);
        send_read(32'h1000_0020);
        send_read(32'h1000_0024);
    endtask
endclass //axi_read_sequence