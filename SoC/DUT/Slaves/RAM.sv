module RAM #(
    parameter ADDR_WIDTH = 14, // 16KB
    parameter INIT_FILE  = ""
) (
    input  logic        clk,
    input  logic        rstn,
    // AW Channel
    input  logic [31:0] s_axi_awaddr,
    input  logic [2:0]  s_axi_awprot,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,
    // W Channel
    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,
    // B Channel
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,
    // AR Channel
    input  logic [31:0] s_axi_araddr,
    input  logic [2:0]  s_axi_arprot,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,
    // R Channel
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready
);
    // 16KB / 4 = 4096 dòng (words)
    localparam MEM_DEPTH = (2**ADDR_WIDTH) / 4;
    logic [31:0] mem [0:MEM_DEPTH-1];

    wire mem_write_en = s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid;

    wire [ADDR_WIDTH-3:0] mem_index  = s_axi_awaddr[ADDR_WIDTH-1:2];
    wire [ADDR_WIDTH-3:0] read_index = s_axi_araddr[ADDR_WIDTH-1:2];

    always_ff @(posedge clk) begin
        if (mem_write_en) begin
            if (s_axi_wstrb[0]) mem[mem_index][7:0]   <= s_axi_wdata[7:0];
            if (s_axi_wstrb[1]) mem[mem_index][15:8]  <= s_axi_wdata[15:8];
            if (s_axi_wstrb[2]) mem[mem_index][23:16] <= s_axi_wdata[23:16];
            if (s_axi_wstrb[3]) mem[mem_index][31:24] <= s_axi_wdata[31:24];
        end
    end

    // always_ff @(posedge clk) begin
    //     if (s_axi_arready && s_axi_arvalid) begin
    //         s_axi_rdata <= mem[read_index];
    //     end
    // end
    assign s_axi_rdata = mem[read_index];

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
        end else begin
            // --- Nhánh Write ---
            // Sẵn sàng nhận ngay khi có VALID và không đang bận (Zero Wait State)
            s_axi_awready <= !s_axi_awready && s_axi_awvalid;
            s_axi_wready  <= !s_axi_wready && s_axi_wvalid;

            // Phản hồi phản hồi ghi (B Channel)
            if (mem_write_en) 
                s_axi_bvalid <= 1'b1;
            else if (s_axi_bready) 
                s_axi_bvalid <= 1'b0;

            // --- Nhánh Read ---
            // Chấp nhận địa chỉ đọc ngay lập tức
            s_axi_arready <= !s_axi_arready && s_axi_arvalid;
            
            // Chỉ bật RVALID khi địa chỉ đã được chấp nhận xong
            if (s_axi_arready && s_axi_arvalid) 
                s_axi_rvalid <= 1'b1;
            else if (s_axi_rready) 
                s_axi_rvalid <= 1'b0;
        end
    end

    assign s_axi_bresp = 2'b00; // OKAY
    assign s_axi_rresp = 2'b00; // OKAY
endmodule