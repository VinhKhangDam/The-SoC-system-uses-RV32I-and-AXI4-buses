class axi_random_wr_rd extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(axi_random_wr_rd)

    function new(string name = "axi_random_wr_rd");
        super.new(name);
    endfunction

    task send_trans(bit [31:0] addr, bit [31:0] data, bit is_write, bit [3:0] wstrb = 4'hf);
        req = axi_transaction::type_id::create("req");
        start_item(req);
        req.addr     = addr;
        req.data     = data;
        req.is_write = is_write;
        req.wstrb    = wstrb; 
        finish_item(req);
    endtask

    virtual task body();
        bit [31:0] written_data[bit [31:0]];
        bit [31:0] r_addr, r_data;

        `uvm_info("SEQ", "--- STARTING SMART RANDOM TEST (ID 11, 12) ---", UVM_LOW)

        written_data.delete(); // Delete all data in array

        for(int i=0; i<256; i++) begin
            r_addr = 32'h1000_0000 + (i * 4);
            r_data = $urandom();
            written_data[r_addr] = r_data;
            send_trans(r_addr, r_data, 1'b1, 4'hf); 
        end

        foreach (written_data[addr]) begin
            send_trans(addr, 32'h0, 1'b0); 
        end

        send_trans(32'h1000_00A0, 32'h5555_AAAA, 1'b1);
        send_trans(32'h1000_00A0, 32'h0000_0000, 1'b0);
        
        `uvm_info("SEQ", "--- SMART RANDOM COMPLETED ---", UVM_LOW)
    endtask
endclass