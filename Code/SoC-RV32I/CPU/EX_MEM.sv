module EX_MEM (
    input logic clk,
    input logic rstn,
    input logic RegWriteE,
    input logic [1:0] ResultSrcE,
    input logic MemWriteE,
    input logic [31:0] ALUResultE,
    input logic [31:0] WriteDataE,
    input logic [4:0] rdE,
    input logic [31:0] pcPlus4E,

    //Output
    output logic RegWriteM,
    output logic [1:0] ResultSrcM,
    output logic MemWriteM,
    output logic [31:0] ALUResultM,
    output logic [31:0] WriteDataM,
    output logic [4:0] rdM,
    output logic [31:0] pcPlus4M
);
    always_ff @(posedge clk or negedge rstn ) begin
        if (~rstn) begin
            RegWriteM <= 0;
            ResultSrcM <= '0;
            MemWriteM <= 0;
            ALUResultM <= 32'd0;
            WriteDataM <= 32'd0;
            rdM <= 5'd0;
            pcPlus4M <= 32'd0;
        end
        else begin
            RegWriteM <= RegWriteE;
            ResultSrcM <= ResultSrcE;
            MemWriteM <= MemWriteE;
            ALUResultM <= ALUResultE;
            WriteDataM <= WriteDataE;
            rdM <= rdE;
            pcPlus4M <= pcPlus4E;
        end
    end
endmodule