module instr_mem (
    input  logic [31:0] addr,
    output logic [31:0] instr
);
  // Memory array: 256 x 32-bit (1KB)
  logic [31:0] mem[0:255];

  initial begin
    $readmemh("instr.mem", mem);

    if (mem[0] === 32'bx || mem[0] === 32'bz) begin
      $display("--- ERROR: Not found file .mem or empty file ---");
    end else begin
      $display("--- SUCCESS: Loaded instructions from .mem ---");
    end
  end

  assign instr = mem[addr[9:2]];

endmodule

