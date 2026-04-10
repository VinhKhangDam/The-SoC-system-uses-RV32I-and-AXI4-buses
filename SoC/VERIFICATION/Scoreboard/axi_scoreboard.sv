class axi_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(axi_scoreboard)
	
	uvm_analysis_imp #(axi_transaction, axi_scoreboard) item_collected_export;

	bit [31:0] sc_mem [bit[31:0]];

	function new(string name, uvm_component parent);
		super.new(name, parent);
		item_collected_export = new("item_collected_export", this);
	endfunction

	virtual function void write(axi_transaction tr);
		if (tr.is_write) begin
			sc_mem[tr.addr] = tr.data;
			`uvm_info("SCB", $sformatf("Ghi vao bo nho : Addr = %h, Data = %h", tr.addr, tr.data), UVM_LOW)
		end else begin
			if (sc_mem.exists(tr.addr)) begin
				if (sc_mem[tr.addr] == tr.data)
					`uvm_info("SCB PASS", "Du lieu trung khop", UVM_LOW)
				else
					`uvm_error("SCB FAIL", $sformatf("Sai! Expected %h but real %h", sc_mem[tr.addr], tr.data))
			end
		end
	endfunction
endclass
