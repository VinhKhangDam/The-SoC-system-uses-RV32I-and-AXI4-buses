module MEM_WB (
    input logic clk,
    input logic rstn,

    input logic RegWriteM,
    input logic [1:0] ResultSrcM,
    input logic [31:0] ALUResultM,
    input logic [31:0] ReadDataM,
    input logic [4:0] rdM,
    input logic [31:0] pcPlus4M,

    output logic RegWriteW,
    output logic [1:0] ResultSrcW,
    output logic [31:0] ALUResultW,
    output logic [31:0] ReadDataW,
    output logic [4:0] rdW,
    output logic [31:0] pcPlus4W,

    input logic stall
);
    always_ff @( posedge clk or negedge rstn ) begin
        if (~rstn) begin
            RegWriteW <= '0;
            ResultSrcW<= '0;
            ALUResultW <= '0;
            ReadDataW <= '0;
            rdW <= '0;
            pcPlus4W <= '0;
        end
        else if (!stall) begin
            RegWriteW <= RegWriteM;
            ResultSrcW <= ResultSrcM;
            ALUResultW <= ALUResultM;
            ReadDataW <= ReadDataM;
            rdW <= rdM;
            pcPlus4W <= pcPlus4M;
        end 
    end
endmodule