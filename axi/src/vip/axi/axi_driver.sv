`ifndef AXI_DRIVER_SV
`define AXI_DRIVER_SV

class axi_driver extends uvm_driver #(axi_tx);

  `uvm_component_utils(axi_driver)

  virtual axi_if vif;

  axi_config m_config;

  extern function new(string name, uvm_component parent);



endclass : axi_driver


function axi_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new





`endif  // AXI_DRIVER_SV
