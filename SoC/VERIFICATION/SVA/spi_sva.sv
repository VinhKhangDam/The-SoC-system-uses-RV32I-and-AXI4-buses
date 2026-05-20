module spi_sva (
    input logic clk,
    input logic rstn,

    input logic [31:0] awaddr,
    input logic [2:0] awprot,
    input logic awvalid,
    input logic awready,

    input logic [31:0] wdata,
    input logic [3:0] wstrb,
    input logic wvalid,
    input logic wready,

    input logic bvalid,
    input logic bready,
    input logic [1:0] bresp,

    input logic [31:0] araddr,
    input logic [2:0] arprot,
    input logic arvalid,
    input logic arready,

    input logic [31:0] rdata,
    input logic [1:0] rresp,
    input logic rready,
    input logic rvalid,

    input logic spi_sck,
    input logic spi_mosi,
    input logic spi_miso,
    input logic spi_cs_n
);
  assert property (@(posedge clk) disable iff (!rstn) bvalid |-> bresp == 2'b00)
  else $error("[SPI_SVA] BRESP not OKAY");

  assert property (@(posedge clk) disable iff (!rstn) rvalid |-> rresp == 2'b00)
  else $error("[SPI_SVA] RRESP NOT OKAY");

  assert property (@(posedge clk) disable iff (!rstn) awvalid |-> !$isunknown({awaddr, awprot}))
  else $error("[SPI_SVA] AW has X/Z");

  assert property (@(posedge clk) disable iff (!rstn) wvalid |-> !$isunknown({wdata, wstrb}))
  else $error("[SPI_SVA] W has X/Z");

  assert property (@(posedge clk) disable iff (!rstn) arvalid |-> !$isunknown({araddr, arprot}))
  else $error("[SPI_SVA] AR has X/Z");

  assert property (@(posedge clk) disable iff (!rstn) awvalid && !awready |=> $stable(
      {awaddr, awprot}
  ))
  else $error("[SPI_SVA] AW changed while waiting");

  assert property (@(posedge clk) disable iff (!rstn) wvalid && !wready |=> $stable({wdata, wstrb}))
  else $error("[SPI_SVA] W changed while waiting");

  assert property (@(posedge clk) disable iff (!rstn) arvalid & !arready |=> $stable(
      {araddr, arprot}
  ))
  else $error("[SPI_SVA] AR changed while waiting");

  assert property (@(posedge clk) disable iff (!rstn) rvalid |-> !$isunknown(rdata))
  else $error("[SPI_SVA] RDATA has X/Z while RVALID");

  assert property (@(posedge clk) disable iff (!rstn) !$isunknown(
      {spi_sck, spi_mosi, spi_miso, spi_cs_n}
  ))
  else $error("[SPI_SVA] SPI pin has X/Z");
endmodule
