module HazardUnit (
    input  logic [4:0] rs1D, rs2D, rs1E, rs2E,
    input  logic [4:0] rdE, rdM, rdW,
    input  logic       RegWriteM, RegWriteW,
    input  logic       ResultSrc0,
    input  logic       pcSrcE,   
    input  logic       lsu_stall,
    
    output logic [1:0] forwardAE, forwardBE,
    output logic       stallF, stallD, flushE, flushD
);
    // --- Logic Forwarding ---
    always_comb begin
        // Forward A
        if (((rs1E == rdM) && RegWriteM) && (rs1E != 0)) 
            forwardAE = 2'b10; // Forward FROM MEM STAGE
        else if (((rs1E == rdW) && RegWriteW) && (rs1E != 0)) 
            forwardAE = 2'b01; // Forward FROM WRITE_BACK STAGE
        else 
            forwardAE = 2'b00; // NO FORWARD

        if (((rs2E == rdM) && RegWriteM) && (rs2E != 0)) 
            forwardBE = 2'b10; // Forward from MEM STAGE
        else if (((rs2E == rdW) && RegWriteW) && (rs2E != 0)) 
            forwardBE = 2'b01; // Forward from WRITE_BACK STAGE
        else 
            forwardBE = 2'b00; // NO FORWARD
    end

    // --- Logic Stall for Load-Use Hazard ---
    logic lwStall;
    assign lwStall = ResultSrc0 && ((rs1D == rdE) || (rs2D == rdE));
    
    assign stallF = lwStall | lsu_stall;
    assign stallD = lwStall | lsu_stall;

    // --- Logic Flush for Control Hazard & Load-Use ---
    assign flushE = lwStall || pcSrcE;
    assign flushD = pcSrcE;

endmodule
