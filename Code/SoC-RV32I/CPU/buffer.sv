module buffer (
    input logic [31:0] pc_in,
    input logic clk, 
    input logic rstn,
    output logic [31:0] pc_out
);
    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            pc_out <= '0;
        end else begin
            pc_out <= pc_in;
        end
    end
endmodule