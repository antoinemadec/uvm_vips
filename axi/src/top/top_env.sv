`ifndef TOP_ENV_SV
`define TOP_ENV_SV

class top_env extends uvm_env;

  `uvm_component_utils(top_env)

  extern function new(string name, uvm_component parent);

  top_config     m_config;
  top_scoreboard m_scoreboard;

  axi_config     m_axi_master_config;
  axi_agent      m_axi_master_agent;
  axi_coverage   m_axi_master_coverage;

  axi_config     m_axi_slave_config;
  axi_agent      m_axi_slave_agent;
  axi_coverage   m_axi_slave_coverage;

  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern function void end_of_elaboration_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);

endclass : top_env


function top_env::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


function void top_env::build_phase(uvm_phase phase);
  `uvm_info(get_type_name(), "In build_phase", UVM_HIGH)

  if (!uvm_config_db#(top_config)::get(this, "", "config", m_config))
    `uvm_fatal(get_type_name(), "Unable to get top_config")

  uvm_config_db#(top_config)::set(this, "m_scoreboard", "config", m_config);
  m_scoreboard = top_scoreboard::type_id::create("m_scoreboard", this);

  m_axi_master_config = m_config.m_axi_master_config;
  uvm_config_db#(axi_config)::set(this, "m_axi_master_agent", "config", m_axi_master_config);
  if (m_axi_master_config.is_active == UVM_ACTIVE)
    uvm_config_db#(axi_config)::set(this, "m_axi_master_agent.m_sequencer", "config",
                                    m_axi_master_config);
  uvm_config_db#(axi_config)::set(this, "m_axi_master_coverage", "config", m_axi_master_config);

  m_axi_master_agent = axi_agent::type_id::create("m_axi_master_agent", this);
  m_axi_master_coverage = axi_coverage::type_id::create("m_axi_master_coverage", this);

  m_axi_slave_config = m_config.m_axi_slave_config;
  uvm_config_db#(axi_config)::set(this, "m_axi_slave_agent", "config", m_axi_slave_config);
  if (m_axi_slave_config.is_active == UVM_ACTIVE)
    uvm_config_db#(axi_config)::set(this, "m_axi_slave_agent.m_sequencer", "config",
                                    m_axi_slave_config);
  uvm_config_db#(axi_config)::set(this, "m_axi_slave_coverage", "config", m_axi_slave_config);

  m_axi_slave_agent = axi_agent::type_id::create("m_axi_slave_agent", this);
  m_axi_slave_coverage = axi_coverage::type_id::create("m_axi_slave_coverage", this);
endfunction : build_phase


function void top_env::connect_phase(uvm_phase phase);
  `uvm_info(get_type_name(), "In connect_phase", UVM_HIGH)

  m_axi_master_agent.analysis_port.connect(m_axi_master_coverage.analysis_export);
  m_axi_master_agent.analysis_port.connect(m_scoreboard.axi_master_export);

  m_axi_slave_agent.analysis_port.connect(m_axi_slave_coverage.analysis_export);
  m_axi_slave_agent.analysis_port.connect(m_scoreboard.axi_slave_export);
endfunction : connect_phase


function void top_env::end_of_elaboration_phase(uvm_phase phase);
  uvm_factory factory = uvm_factory::get();
  `uvm_info(get_type_name(), "Information printed from top_env::end_of_elaboration_phase method",
            UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Verbosity threshold is %d", get_report_verbosity_level()),
            UVM_MEDIUM)
  uvm_top.print_topology();
  factory.print();
endfunction : end_of_elaboration_phase


task top_env::run_phase(uvm_phase phase);
  top_default_seq vseq;
  vseq = top_default_seq::type_id::create("vseq");
  vseq.set_item_context(null, null);
  if (!vseq.randomize()) `uvm_fatal(get_type_name(), "Failed to randomize virtual sequence")
  vseq.m_axi_master_agent = m_axi_master_agent;
  vseq.m_axi_slave_agent = m_axi_slave_agent;
  vseq.m_config = m_config;
  vseq.set_starting_phase(phase);
  vseq.start(null);
endtask : run_phase


`endif  // TOP_ENV_SV
