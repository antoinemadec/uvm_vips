package axi_pkg;

  `include "uvm_macros.svh"

  import uvm_pkg::*;

  parameter int AXI_ID_WIDTH   = 4;
  parameter int AXI_ADDR_WIDTH = 32;
  parameter int AXI_DATA_WIDTH = 32;
  parameter int AXI_STRB_WIDTH = AXI_DATA_WIDTH>>3;

  `include "axi_tx.sv"
  `include "axi_config.sv"
  `include "axi_driver.sv"
  `include "axi_master_driver.sv"
  `include "axi_slave_driver.sv"
  `include "axi_monitor.sv"
  `include "axi_sequencer.sv"
  `include "axi_coverage.sv"
  `include "axi_agent.sv"
  `include "axi_seq_lib.sv"

endpackage : axi_pkg
