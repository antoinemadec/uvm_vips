`ifndef AXI_CONFIG_SV
`define AXI_CONFIG_SV

class axi_config extends uvm_object;

  // do not register config class with the factory

  virtual axi_if          vif;

  uvm_active_passive_enum is_active        = UVM_ACTIVE;
  bit                     is_master;
  bit                     coverage_enable;
  bit                     checks_enable;

  extern function new(string name = "");

endclass : axi_config


function axi_config::new(string name = "");
  super.new(name);
endfunction : new


`endif  // AXI_CONFIG_SV
