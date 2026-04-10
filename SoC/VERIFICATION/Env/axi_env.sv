class axi_env extends uvm_env;
	`uvm_component_utils(axi_env)

	axi_agent agent;

	axi_scoreboard scoreboard;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase (uvm_phase phase);
		super.build_phase(phase);
		uvm_config_db#(uvm_active_passive_enum)::set(this, "agent", "is_active", 1); 
		agent = axi_agent::type_id::create("agent", this);
		scoreboard = axi_scoreboard::type_id::create("scoreeboard", this);
	endfunction

	function void connect_phase (uvm_phase phase);
		super.connect_phase(phase);
		agent.monitor.item_collected_port.connect(scoreboard.item_collected_export);
	endfunction
endclass
