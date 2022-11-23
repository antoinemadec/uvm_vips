`ifndef AXI_AGENT_SV
`define AXI_AGENT_SV

class axi_agent extends uvm_agent;

  `uvm_component_utils(axi_agent)

  uvm_analysis_port #(axi_tx) analysis_port;

  axi_config                  m_config;
  axi_sequencer_t             m_sequencer;
  axi_driver                  m_driver;
  axi_monitor                 m_monitor;

  local int                   m_is_active    = -1;

  extern function new(string name, uvm_component parent);

  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern function uvm_active_passive_enum get_is_active();

endclass : axi_agent


function axi_agent::new(string name, uvm_component parent);
  super.new(name, parent);
  analysis_port = new("analysis_port", this);
endfunction : new


function void axi_agent::build_phase(uvm_phase phase);

  if (!uvm_config_db#(axi_config)::get(this, "", "config", m_config))
    `uvm_fatal(get_type_name(), "axi config not found")

  m_monitor = axi_monitor::type_id::create("m_monitor", this);

  if (get_is_active() == UVM_ACTIVE) begin
    if (m_config.is_master) m_driver = axi_master_driver::type_id::create("m_driver", this);
    else m_driver = axi_slave_driver::type_id::create("m_driver", this);
    m_sequencer = axi_sequencer_t::type_id::create("m_sequencer", this);
  end

endfunction : build_phase


function void axi_agent::connect_phase(uvm_phase phase);
  if (m_config.vif == null) `uvm_warning(get_type_name(), "axi virtual interface is not set!")

  m_monitor.vif = m_config.vif;
  m_monitor.m_config = m_config;
  m_monitor.analysis_port.connect(analysis_port);

  if (get_is_active() == UVM_ACTIVE) begin
    m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    m_driver.vif = m_config.vif;
    m_driver.m_config = m_config;
  end

endfunction : connect_phase


function uvm_active_passive_enum axi_agent::get_is_active();
  if (m_is_active == -1) begin
    if (uvm_config_db#(uvm_bitstream_t)::get(this, "", "is_active", m_is_active)) begin
      if (m_is_active != m_config.is_active)
        `uvm_warning(get_type_name(), "is_active field in config_db conflicts with config object")
    end else m_is_active = m_config.is_active;
  end
  return uvm_active_passive_enum'(m_is_active);
endfunction : get_is_active


`endif  // AXI_AGENT_SV
