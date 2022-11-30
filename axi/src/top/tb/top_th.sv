module top_th;

  timeunit 1ns; timeprecision 1ps;


  logic clk = 0;
  logic rstn;

  always #10 clk = ~clk;

  initial begin
    rstn = 0;
    #75 rstn = 1;
  end

  axi_if axi_master_if ();
  axi_if axi_slave_if ();

  //-----------------------------------------------------------
  // connect master to slave
  //-----------------------------------------------------------
  // global
  assign axi_master_if.ACLK    = clk;
  assign axi_slave_if.ACLK     = clk;
  assign axi_master_if.ARESETn = rstn;
  assign axi_slave_if.ARESETn  = rstn;
  // write address
  assign axi_slave_if.AWID     = axi_master_if.AWID;
  assign axi_slave_if.AWADDR   = axi_master_if.AWADDR;
  assign axi_slave_if.AWLEN    = axi_master_if.AWLEN;
  assign axi_slave_if.AWSIZE   = axi_master_if.AWSIZE;
  assign axi_slave_if.AWBURST  = axi_master_if.AWBURST;
  assign axi_slave_if.AWLOCK   = axi_master_if.AWLOCK;
  assign axi_slave_if.AWCACHE  = axi_master_if.AWCACHE;
  assign axi_slave_if.AWPROT   = axi_master_if.AWPROT;
  assign axi_slave_if.AWQOS    = axi_master_if.AWQOS;
  assign axi_slave_if.AWREGION = axi_master_if.AWREGION;
  assign axi_slave_if.AWVALID  = axi_master_if.AWVALID;
  assign axi_master_if.AWREADY = axi_slave_if.AWREADY;
  // write data
  assign axi_slave_if.WID      = axi_master_if.WID;
  assign axi_slave_if.WDATA    = axi_master_if.WDATA;
  assign axi_slave_if.WSTRB    = axi_master_if.WSTRB;
  assign axi_slave_if.WLAST    = axi_master_if.WLAST;
  assign axi_slave_if.WVALID   = axi_master_if.WVALID;
  assign axi_master_if.WREADY  = axi_slave_if.WREADY;
  // write response
  assign axi_master_if.BID     = axi_slave_if.BID;
  assign axi_master_if.BRESP   = axi_slave_if.BRESP;
  assign axi_master_if.BVALID  = axi_slave_if.BVALID;
  assign axi_slave_if.BREADY   = axi_master_if.BREADY;
  // read address
  assign axi_slave_if.ARID     = axi_master_if.ARID;
  assign axi_slave_if.ARADDR   = axi_master_if.ARADDR;
  assign axi_slave_if.ARLEN    = axi_master_if.ARLEN;
  assign axi_slave_if.ARSIZE   = axi_master_if.ARSIZE;
  assign axi_slave_if.ARBURST  = axi_master_if.ARBURST;
  assign axi_slave_if.ARLOCK   = axi_master_if.ARLOCK;
  assign axi_slave_if.ARCACHE  = axi_master_if.ARCACHE;
  assign axi_slave_if.ARPROT   = axi_master_if.ARPROT;
  assign axi_slave_if.ARQOS    = axi_master_if.ARQOS;
  assign axi_slave_if.ARREGION = axi_master_if.ARREGION;
  assign axi_slave_if.ARVALID  = axi_master_if.ARVALID;
  assign axi_master_if.ARREADY = axi_slave_if.ARREADY;
  // read data
  assign axi_master_if.RID     = axi_slave_if.RID;
  assign axi_master_if.RDATA   = axi_slave_if.RDATA;
  assign axi_master_if.RRESP   = axi_slave_if.RRESP;
  assign axi_master_if.RLAST   = axi_slave_if.RLAST;
  assign axi_master_if.RVALID  = axi_slave_if.RVALID;
  assign axi_slave_if.RREADY   = axi_master_if.RREADY;

  initial begin
    // simvision
    $shm_open("waves.shm");
    $shm_probe("ACMTF");
  end

endmodule
