// ============================================================
// cpu_transaction.sv
// Represents one register writeback event from the CPU pipeline.
// Captured by the CPU monitor every time RegWriteW=1.
// ============================================================
class cpu_transaction extends uvm_sequence_item;
    `uvm_object_utils(cpu_transaction)
 
    logic [31:0] pc;         // PC of the instruction (from PcF at the time)
    logic [31:0] instr;      // Instruction word (from InstrF)
    logic [4:0]  rd;         // Destination register index
    logic [31:0] result;     // Value written into rd
 
    // Pipeline signals captured at same cycle
    logic [31:0] alu_result; // ALUResultM (address or compute result)
    logic        mem_write;  // MemWriteM  (was this a store?)
    logic [31:0] mem_wdata;  // WriteDataM
    logic [1:0]  forward_a;  // ForwardA mux sel
    logic [1:0]  forward_b;  // ForwardB mux sel
    logic        branch_taken;// PCSrc
 
    function new(string name = "cpu_wb_transaction");
        super.new(name);
    endfunction
 
    function string convert2string();
        string alu_op;
        return $sformatf(
            "PC=%h INSTR=%h | WB: x%02d <= %h | ALU=%h Store=%0b Fwd=[%b,%b] Branch=%0b",
            pc, instr, rd, result, alu_result,
            mem_write, forward_a, forward_b, branch_taken);
    endfunction
endclass
 