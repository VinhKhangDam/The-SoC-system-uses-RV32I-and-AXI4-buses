class axi_random_wr_rd_test extends uvm_test;
	`uvm_component_utils(axi_random_wr_rd_test)

	axi_env env;

	function new(string name = "axi_random_wr_rd_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env = axi_env::type_id::create("env", this);
	endfunction

	virtual task run_phase (uvm_phase phase);
		//axi_simple_sequence seq;
		axi_random_wr_rd seq;
		phase.raise_objection(this); // Start test
		//seq = axi_simple_sequence::type_id::create("seq");
		seq = axi_random_wr_rd::type_id::create("seq");
    	if (!seq.randomize()) 
			`uvm_error("TEST", "Randomized failed!")
		seq.start(env.agent.sequencer); // Run sequence on sequencer
		#100ns; //wait for 100 ns
		phase.drop_objection(this); // End test
	endtask
endclass
