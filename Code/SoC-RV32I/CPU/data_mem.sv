module data_mem (
    input logic clk, rstn,
    input logic WE,
    input logic [31:0] ALUResult,
    input logic [31:0] WriteData,
    output logic [31:0] ReadData
);
    logic [31:0] mem [0:255];

    // Write logc
    always_ff @( posedge clk or negedge rstn ) begin
        if (~rstn) begin
            for (int i = 0; i < 256; i++) begin
                mem[i] <= '0;
            end
        end
        else if (WE) begin
            mem[ALUResult[9:2]] <= WriteData;
        end
    end

    // Read logic
    assign ReadData = mem[ALUResult[9:2]];
endmodule