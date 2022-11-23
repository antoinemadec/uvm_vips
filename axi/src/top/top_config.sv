`ifndef TOP_CONFIG_SV
`define TOP_CONFIG_SV

class top_config extends uvm_object;

  // do not register config class with the factory

  rand axi_config m_axi_master_config;
  rand axi_config m_axi_slave_config;

  extern function new(string name = "", bit coverage_enable = 0);

endclass : top_config


function top_config::new(string name = "", bit coverage_enable = 0);
  super.new(name);

  m_axi_master_config = new("m_axi_master_config");
  m_axi_master_config.is_active = UVM_ACTIVE;
  m_axi_master_config.is_master = 1;
  m_axi_master_config.checks_enable = 1;
  m_axi_master_config.coverage_enable = coverage_enable;

  m_axi_slave_config = new("m_axi_slave_config");
  m_axi_slave_config.is_active = UVM_ACTIVE;
  m_axi_slave_config.is_master = 0;
  m_axi_slave_config.checks_enable = 1;
  m_axi_slave_config.coverage_enable = coverage_enable;
endfunction : new


`endif  // TOP_CONFIG_SV
