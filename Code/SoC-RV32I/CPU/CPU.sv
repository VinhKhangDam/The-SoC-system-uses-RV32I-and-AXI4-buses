module CPU (
    input logic clk,
    input logic rstn,
    // Imem
    input logic [31:0] instr,
    output logic [31:0] pc,
    // Dmem
    input logic [31:0] memRdata,
    output logic memWrite,
    output logic [31:0] memALUResult,
    output logic [31:0] memWriteData
);
    
endmodule