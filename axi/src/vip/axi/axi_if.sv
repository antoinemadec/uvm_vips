`ifndef AXI_IF_SV
`define AXI_IF_SV

interface axi_if ();

  timeunit 1ns; timeprecision 1ps;

  import axi_pkg::*;

  // global
  wire                      ACLK;
  wire                      ARESETn;
  // write address
  wire [AXI_ID_WIDTH-1:0]   AWID;
  wire [AXI_ADDR_WIDTH-1:0] AWADDR;
  wire [7:0]                AWLEN;    // AXI3: 4 bits; AXI4: 8 bits
  wire [2:0]                AWSIZE;
  wire [1:0]                AWBURST;
  wire [1:0]                AWLOCK;   // AXI3: 2 bits; AXI4: 1 bit
  wire [3:0]                AWCACHE;
  wire [2:0]                AWPROT;
  wire [3:0]                AWQOS;    // AXI4 only
  wire [3:0]                AWREGION; // AXI4 only
  wire                      AWVALID;
  wire                      AWREADY;
  // write data
  wire [AXI_ID_WIDTH-1:0]   WID;      // AXI3 only
  wire [AXI_DATA_WIDTH-1:0] WDATA;
  wire                      WSTRB;
  wire                      WLAST;
  wire                      WVALID;
  wire                      WREADY;
  // write response
  wire [AXI_ID_WIDTH-1:0]   BID;
  wire [1:0]                BRESP;
  wire                      BVALID;
  wire                      BREADY;
  // read address
  wire [AXI_ID_WIDTH-1:0]   ARID;
  wire [AXI_ADDR_WIDTH-1:0] ARADDR;
  wire [7:0]                ARLEN;    // AXI3: 4 bits; AXI4: 8 bits
  wire [2:0]                ARSIZE;
  wire [1:0]                ARBURST;
  wire [1:0]                ARLOCK;   // AXI3: 2 bits; AXI4: 1 bits
  wire [3:0]                ARCACHE;
  wire [2:0]                ARPROT;
  wire [3:0]                ARQOS;    // AXI4 only
  wire [3:0]                ARREGION; // AXI4 only
  wire                      ARVALID;
  wire                      ARREADY;
  // read data
  wire [AXI_ID_WIDTH-1:0]   RID;
  wire [AXI_DATA_WIDTH-1:0] RDATA;
  wire [1:0]                RRESP;
  wire                      RLAST;
  wire                      RVALID;
  wire                      RREADY;

  clocking cb_drv_m @(posedge ACLK);
    input  ARESETn;
    output AWID;
    output AWADDR;
    output AWLEN;
    output AWSIZE;
    output AWBURST;
    output AWLOCK;
    output AWCACHE;
    output AWPROT;
    output AWQOS;
    output AWREGION;
    output AWVALID;
    input  AWREADY;
    output WID;
    output WDATA;
    output WSTRB;
    output WLAST;
    output WVALID;
    input  WREADY;
    input  BID;
    input  BRESP;
    input  BVALID;
    output BREADY;
    output ARID;
    output ARADDR;
    output ARLEN;
    output ARSIZE;
    output ARBURST;
    output ARLOCK;
    output ARCACHE;
    output ARPROT;
    output ARQOS;
    output ARREGION;
    output ARVALID;
    input  ARREADY;
    input  RID;
    input  RDATA;
    input  RRESP;
    input  RLAST;
    input  RVALID;
    output RREADY;
  endclocking : cb_drv_m

  clocking cb_drv_s @(posedge ACLK);
    input  ARESETn;
    input  AWID;
    input  AWADDR;
    input  AWLEN;
    input  AWSIZE;
    input  AWBURST;
    input  AWLOCK;
    input  AWCACHE;
    input  AWPROT;
    input  AWQOS;
    input  AWREGION;
    input  AWVALID;
    output AWREADY;
    input  WID;
    input  WDATA;
    input  WSTRB;
    input  WLAST;
    input  WVALID;
    output WREADY;
    output BID;
    output BRESP;
    output BVALID;
    input  BREADY;
    input  ARID;
    input  ARADDR;
    input  ARLEN;
    input  ARSIZE;
    input  ARBURST;
    input  ARLOCK;
    input  ARCACHE;
    input  ARPROT;
    input  ARQOS;
    input  ARREGION;
    input  ARVALID;
    output ARREADY;
    output RID;
    output RDATA;
    output RRESP;
    output RLAST;
    output RVALID;
    input  RREADY;
  endclocking : cb_drv_s

  clocking cb_mon @(posedge ACLK);
    input ARESETn;
    input AWID;
    input AWADDR;
    input AWLEN;
    input AWSIZE;
    input AWBURST;
    input AWLOCK;
    input AWCACHE;
    input AWPROT;
    input AWQOS;
    input AWREGION;
    input AWVALID;
    input AWREADY;
    input WID;
    input WDATA;
    input WSTRB;
    input WLAST;
    input WVALID;
    input WREADY;
    input BID;
    input BRESP;
    input BVALID;
    input BREADY;
    input ARID;
    input ARADDR;
    input ARLEN;
    input ARSIZE;
    input ARBURST;
    input ARLOCK;
    input ARCACHE;
    input ARPROT;
    input ARQOS;
    input ARREGION;
    input ARVALID;
    input ARREADY;
    input RID;
    input RDATA;
    input RRESP;
    input RLAST;
    input RVALID;
    input RREADY;
  endclocking : cb_mon

endinterface : axi_if

`endif  // AXI_IF_SV
