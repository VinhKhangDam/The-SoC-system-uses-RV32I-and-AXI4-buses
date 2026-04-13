module AXI4_Lite_Interconnect #(
    parameter NUM_SLAVES = 5
) ( 
    input logic clk,
    input logic rstn,

    // Signals from Master
    input   logic           m_axi_rready,
    output  logic           m_axi_rvalid,
    output  logic [1:0]     m_axi_rresp, 
    output  logic [31:0]    m_axi_rdata,

    input   logic [31:0]    m_axi_awaddr,
    input   logic [2:0]     m_axi_awprot,
    input   logic           m_axi_awvalid,
    output  logic           m_axi_awready,

    input   logic [31:0]    m_axi_wdata,
    input   logic [3:0]     m_axi_wstrb,
    input   logic           m_axi_wvalid,
    output  logic           m_axi_wready,

    output  logic [1:0]     m_axi_bresp,
    output  logic           m_axi_bvalid,
    input   logic           m_axi_bready,

    input   logic [31:0]    m_axi_araddr,
    input   logic [2:0]     m_axi_arprot,
    input   logic           m_axi_arvalid,
    output  logic           m_axi_arready,

    // Signals to Slaves
    output logic [NUM_SLAVES-1:0] [31:0] s_axi_awaddr,
    output logic [NUM_SLAVES-1:0] [2:0]  s_axi_awprot,
    output logic [NUM_SLAVES-1:0]        s_axi_awvalid,
    input  logic [NUM_SLAVES-1:0]        s_axi_awready,

    output logic [NUM_SLAVES-1:0] [31:0] s_axi_wdata,
    output logic [NUM_SLAVES-1:0] [3:0]  s_axi_wstrb,
    output logic [NUM_SLAVES-1:0]        s_axi_wvalid,
    input  logic [NUM_SLAVES-1:0]        s_axi_wready,

    input  logic [NUM_SLAVES-1:0] [1:0]  s_axi_bresp,
    input  logic [NUM_SLAVES-1:0]        s_axi_bvalid,
    output logic [NUM_SLAVES-1:0]        s_axi_bready,

    output logic [NUM_SLAVES-1:0] [31:0] s_axi_araddr,
    output logic [NUM_SLAVES-1:0] [2:0]  s_axi_arprot,
    output logic [NUM_SLAVES-1:0]        s_axi_arvalid,
    input  logic [NUM_SLAVES-1:0]        s_axi_arready,

    input  logic [NUM_SLAVES-1:0] [31:0] s_axi_rdata,
    input  logic [NUM_SLAVES-1:0] [1:0]  s_axi_rresp,
    input  logic [NUM_SLAVES-1:0]        s_axi_rvalid,
    output logic [NUM_SLAVES-1:0]        s_axi_rready
);

    // Address of Slaves
    localparam [31:0] ADDR_IRAM_BASE  = 32'h0000_0000; // Instruction RAM
    localparam [31:0] ADDR_DRAM_BASE  = 32'h1000_0000; // Data RAM
    localparam [31:0] ADDR_TIMER_BASE = 32'h2000_0000; // Timer
    localparam [31:0] ADDR_UART_BASE  = 32'h3000_0000; // UART
    localparam [31:0] ADDR_SPI_BASE   = 32'h4000_0000; // SPI

    localparam [31:0] ADDR_MASK_STRICT  = 32'hFF00_0000; 

    // Decoder address
    logic [2:0] write_sel, read_sel; // 0: Instruction RAM, 1: Data RAM, 2: Timer, 3: UART, 4: SPI

    always_comb begin : Write_selection
        case (m_axi_awaddr & ADDR_MASK_STRICT)
            ADDR_IRAM_BASE : write_sel = 3'd0;
            ADDR_DRAM_BASE : write_sel = 3'd1;
            ADDR_TIMER_BASE: write_sel = 3'd2;
            ADDR_UART_BASE : write_sel = 3'd3;
            ADDR_SPI_BASE  : write_sel = 3'd4;
            default        : write_sel = 3'd7;
        endcase
    end // Write_selection

    always_comb begin : Read_selection
        case (m_axi_araddr & ADDR_MASK_STRICT)
            ADDR_IRAM_BASE : read_sel = 3'd0;
            ADDR_DRAM_BASE : read_sel = 3'd1;
            ADDR_TIMER_BASE: read_sel = 3'd2;
            ADDR_UART_BASE : read_sel = 3'd3;
            ADDR_SPI_BASE  : read_sel = 3'd4;
            default        : read_sel = 3'd7; 
        endcase
    end // Read_selection

    // Send write address and write data to all slaves but will turn on the valid signal to selected slave
    always_comb begin
        for (int i = 0; i < NUM_SLAVES; i++) begin
            s_axi_awaddr[i] = m_axi_awaddr;
            s_axi_awprot[i] = m_axi_awprot;
            s_axi_wdata[i] = m_axi_wdata;
            s_axi_wstrb[i] = m_axi_wstrb;

            // Just sent the valid signals to selected slave
            s_axi_awvalid[i] = (m_axi_awvalid && (write_sel == i));
            s_axi_wvalid[i]  = (m_axi_wvalid && (write_sel == i));

            // Read address logic
            s_axi_araddr[i] = m_axi_araddr;
            s_axi_arprot[i] = m_axi_arprot;
            s_axi_arvalid[i] = (m_axi_arvalid && (read_sel == i));
        end
    end

    always_comb begin
        // Mux ready for Write channels
        if (write_sel < NUM_SLAVES) begin
            m_axi_awready = s_axi_awready[write_sel];
            m_axi_wready = s_axi_wready[write_sel];
        end else begin
            m_axi_awready = 1'b1;
            m_axi_wready = 1'b1;
        end

        // Mux ready for Read channels
        if (read_sel < NUM_SLAVES) begin
            m_axi_arready = s_axi_arready[read_sel];
        end else begin
            m_axi_arready = '1;
        end
    end

    // Response logic (R & B Channels)
    logic [2:0] write_sel_q, read_sel_q;
    always_ff @( posedge clk or negedge rstn ) begin
        if (!rstn) begin
            write_sel_q <= 3'd7;
            read_sel_q  <= 3'd7;
        end else begin
            if (m_axi_awvalid && m_axi_awready) write_sel_q <= write_sel;
            if (m_axi_arvalid && m_axi_arready) read_sel_q <= read_sel;
        end
    end

    always_comb begin
        if (write_sel_q < NUM_SLAVES) begin
            m_axi_bresp = s_axi_bresp[write_sel_q];
            m_axi_bvalid = s_axi_bvalid[write_sel_q];
            for (int i = 0; i < NUM_SLAVES; i++) s_axi_bready[i] = (write_sel_q == i) ? m_axi_bready : 1'b0;
        end else if (write_sel_q == 3'd7) begin
            m_axi_bresp  = 2'b11; // DECERR
            m_axi_bvalid = 1'b1;
            s_axi_bready = '0;
        end else begin
            m_axi_bvalid = 1'b0;
            s_axi_bready = '0;
        end

        if (read_sel_q < NUM_SLAVES) begin
            m_axi_rdata   = s_axi_rdata[read_sel_q]; 
            m_axi_rresp   = s_axi_rresp[read_sel_q]; 
            m_axi_rvalid  = s_axi_rvalid[read_sel_q]; 
            for (int i=0; i<NUM_SLAVES; i++) 
                s_axi_rready[i] = (read_sel_q == i) ? m_axi_rready : 1'b0;
        end else if (read_sel_q == 3'd7) begin
            m_axi_rdata   = 32'hDEADBEEF;
            m_axi_rresp   = 2'b11; // DECERR 
            m_axi_rvalid  = 1'b1; 
            s_axi_rready  = '0; 
        end else begin
            m_axi_rdata   = 32'h0;
            m_axi_rresp   = 2'b00;
            m_axi_rvalid  = 1'b0;
            s_axi_rready  = '0;
        end
    end
    
endmodule
