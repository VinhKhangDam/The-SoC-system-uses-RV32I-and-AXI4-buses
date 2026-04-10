package uvm_tb_udf_pkg;
  
  parameter HALF_CLK	=			50;
  
  `define ADDR_WIDTH      16
  `define DATA_WIDTH      8
  `define HALF_PERIOD     50
  `define USB_ADDR_MIN    32'h0000_1000
  `define USB_ADDR_MAX    32'h0000_1fff
  `define RESET_LENGTH    5
  `define ADDR_ARR_SIZE   50
  `define GEN_SOURCE_NUM  3
  `define GENERATE_SIZE   5
  `define COUNT_THRESHOLD 7
  `define START_WAIT      1
  `define MEM_REGION_SEL  0
  `define SEQ_LOOP_COUNT  25  
  `define NUM_TRANS       20
  `define NUM_WRITE       20
  
  parameter GLB_TIMEOUT   =  500000;
  parameter DRAIN_TIME  =    1000;
  parameter MUX_IN_DATA_WIDTH =	32;
  parameter MUX_IN_CHAN_WIDTH	= 2;

  typedef bit [MUX_IN_DATA_WIDTH-1:0] mux_in_data_t;
  typedef bit [MUX_IN_CHAN_WIDTH-1:0] mux_in_chan_t;
  typedef enum {IS_TRUE, IS_FALSE, IS_ENABLE, IS_DISABLE} bool_t;
  
endpackage
