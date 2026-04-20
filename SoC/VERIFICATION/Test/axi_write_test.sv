class axi_write_test extends uvm_test;
    `uvm_component_utils(axi_write_test)

    axi_env env;

    function new(string name = "axi_write_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_write_sequence seq;
        phase.raise_objection(this);
        seq = axi_write_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass // axi_write_test