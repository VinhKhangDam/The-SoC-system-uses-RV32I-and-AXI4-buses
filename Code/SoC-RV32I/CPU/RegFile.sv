module RegFile (
    input logic clk, 
    input logic rstn, 
    input logic [4:0] rs1, rs2, 
    input logic [4:0] rd,
    input logic [31:0] WriteData,
    input logic write_enable,
    output logic [31:0] rd1, rd2
);
    logic [31:0] reg_internal [31:0]; // Array has 32 register, each has 32bit

    // Write logic
    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            for (int i = 0; i < 32; i++) begin
                reg_internal[i] <= '0;
            end
        end
        else begin
            if (write_enable && (!rd == 5'd0)) begin
                reg_internal[rd] <= WriteData;
            end
        end
    end

    // Read logic
    assign rd1 = (rs1 != 5'd0) ? (reg_internal[rs1]) : 32'd0;
    assign rd2 = (rs2 != 5'd0) ? (reg_internal[rs2]) : 32'd0;
endmodule