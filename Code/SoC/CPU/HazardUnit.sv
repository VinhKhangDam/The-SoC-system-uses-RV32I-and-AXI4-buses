module HazardUnit (
    input  logic [4:0] rs1D, rs2D, rs1E, rs2E,
    input  logic [4:0] rdE, rdM, rdW,
    input  logic       RegWriteM, RegWriteW,
    input  logic       ResultSrc0, // Tín hiệu ResultSrcE[0] (báo lệnh Load)
    input  logic       pcSrcE,      // Tín hiệu quyết định rẽ nhánh
    input  logic       lsu_stall,
    
    output logic [1:0] forwardAE, forwardBE,
    output logic       stallF, stallD, flushE, flushD
);
    // --- Logic Forwarding ---
    always_comb begin
        // Forward A
        if (((rs1E == rdM) && RegWriteM) && (rs1E != 0)) 
            forwardAE = 2'b10; // Forward từ MEM
        else if (((rs1E == rdW) && RegWriteW) && (rs1E != 0)) 
            forwardAE = 2'b01; // Forward từ WB
        else 
            forwardAE = 2'b00; // Không forward

        // Forward B tương tự cho rs2E...
        if (((rs2E == rdM) && RegWriteM) && (rs2E != 0)) 
            forwardBE = 2'b10; // Forward từ MEM
        else if (((rs2E == rdW) && RegWriteW) && (rs2E != 0)) 
            forwardBE = 2'b01; // Forward từ WB
        else 
            forwardBE = 2'b00; // Không forward
    end

    // --- Logic Stall cho Load-Use Hazard ---
    logic lwStall;
    assign lwStall = ResultSrc0 && ((rs1D == rdE) || (rs2D == rdE));
    
    assign stallF = lwStall | lsu_stall;
    assign stallD = lwStall | lsu_stall;

    // --- Logic Flush cho Control Hazard & Load-Use ---
    assign flushE = lwStall || pcSrcE;
    assign flushD = pcSrcE;

endmodule