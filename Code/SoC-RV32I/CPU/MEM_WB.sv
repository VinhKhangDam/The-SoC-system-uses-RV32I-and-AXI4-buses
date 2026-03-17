module MEM_WB (
    input logic clk,
    input logic rstn,

    input logic RegWriteM,
    input logic ResultSrcM,
    input logic [31:0] ALUResultM,
    input logic [31:0] ReadDataM,
    input logic [4:0] rdM,
    input logic [31:0] pcPlus4M,

    output logic RegWriteW,
    output logic ResultSrcW,
    output logic [31:0] ALUResultW,
    output logic [31:0] ReadDataW,
    output logic [4:0] rdW,
    output logic [31:0] pcPlus4W,
);
    always_ff @( posedge clk or negedge rstn ) begin
        if (~rstn) begin
            RegWriteM <= '0;
            ResultSrcM <= '0;
            ALUResultM <= '0;
            ReadDataM <= '0;
            rdM <= '0;
            pcPlus4M <= '0;
        end
        else begin
            RegWriteM <= RegWriteW;
            ResultSrcM <= ResultSrcW;
            ALUResultM <= ALUResultW;
            ReadDataM <= ReadDataW;
            rdM <= rdW;
            pcPlus4M <= pcPlus4W;
        end 
    end
endmodule