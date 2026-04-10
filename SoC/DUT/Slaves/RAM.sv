module RAM #(
    parameter ADDR_WIDTH = 14, // 16KB
    parameter INIT_FILE  = ""
) (
    input  logic        clk,
    input  logic        rstn,

    // AXI-Lite Slave Interface
    input  logic [31:0] s_axi_awaddr,
    input  logic [2:0]  s_axi_awprot,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    input  logic [31:0] s_axi_araddr,
    input  logic [2:0]  s_axi_arprot,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready
);
    // INTERNAL MEM
    logic [31:0] mem [0:(2**ADDR_WIDTH)/4-1];

    initial begin
        if (INIT_FILE != "") $readmemh(INIT_FILE, mem);
    end

    // --- 1. Synchronous Write (BRAM Style) ---
    always_ff @(posedge clk) begin
        if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
            if (s_axi_wstrb[0]) mem[s_axi_awaddr[ADDR_WIDTH-1:2]][7:0]   <= s_axi_wdata[7:0];
            if (s_axi_wstrb[1]) mem[s_axi_awaddr[ADDR_WIDTH-1:2]][15:8]  <= s_axi_wdata[15:8];
            if (s_axi_wstrb[2]) mem[s_axi_awaddr[ADDR_WIDTH-1:2]][23:16] <= s_axi_wdata[23:16];
            if (s_axi_wstrb[3]) mem[s_axi_awaddr[ADDR_WIDTH-1:2]][31:24] <= s_axi_wdata[31:24];
        end
    end

    // --- 2. Synchronous Read (BRAM Style) ---
    always_ff @(posedge clk) begin
        if (s_axi_arready && s_axi_arvalid) begin
            s_axi_rdata <= mem[s_axi_araddr[ADDR_WIDTH-1:2]];
        end
    end

    // --- 3. AXI-Lite Handshake Control ---
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
        end else begin
            // Write Handshake
            if (!s_axi_awready && s_axi_awvalid && s_axi_wvalid) begin
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
            end

            if (s_axi_awready && s_axi_wready) s_axi_bvalid <= 1'b1;
            else if (s_axi_bready) s_axi_bvalid <= 1'b0;

            // Read Handshake
            if (!s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_arready && s_axi_arvalid) s_axi_rvalid <= 1'b1;
            else if (s_axi_rready) s_axi_rvalid <= 1'b0;
        end
    end

    assign s_axi_bresp = 2'b00; // OKAY
    assign s_axi_rresp = 2'b00; // OKAY

endmodule