//  Class: axi_write_sequence
//
class axi_write_sequence extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(axi_write_sequence);

    function new(string name = "axi_write_sequence");
        super.new(name);
    endfunction: new

    task send_write(bit[31:0] addr, bit [31:0] data);
        req = axi_transaction::type_id::create("req");
        start_item(req);
        req.addr        = addr;
        req.data        = data;
        req.is_write    = 1'b1;
        req.wstrb       = 4'hF;
        finish_item(req);
    endtask // send_write

    task send_read(bit[31:0] addr);
        req = axi_transaction::type_id::create("req");
        start_item(req);
        req.addr        = addr;
        req.data        = 32'h0;
        req.is_write    = 1'b0;
        req.wstrb       = 4'h0;
        finish_item(req);
    endtask // send_read

    //  Task: body
    //  This is the user-defined task where the main sequence code resides.
    virtual task body();
        `uvm_info("SEQ", "Basic AXI4-Lite Write", UVM_LOW)

        // Write 
        send_write(32'h1000_0000, 32'hDEAD_BEEF);
        send_write(32'h1000_0004, 32'hAAAA_5555);
        send_write(32'h1000_0008, 32'h1234_5678);
        send_write(32'h1000_000C, 32'h3848_3772);

        // Read
        send_read(32'h1000_0000);
        send_read(32'h1000_0004);
        send_read(32'h1000_0008);
        send_read(32'h1000_000C);

        `uvm_info("SEQ", "Basic AXI4-Lite Write Done", UVM_LOW)
    endtask // body
    
endclass: axi_write_sequence