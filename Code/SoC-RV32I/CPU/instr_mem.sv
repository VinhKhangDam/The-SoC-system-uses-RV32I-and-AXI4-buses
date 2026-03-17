module instr_mem (
    input logic clk, 
    input logic rstn,
    input logic [31:0] addr,
    output logic [31:0] instr
);
    // Memory array: 1KB = 256 x 32-bit
    logic [31:0] mem [0:255];

    initial begin
        $readmemh("instr.mem", mem);
    end

    assign instr = mem[addr[9:2]];
endmodule