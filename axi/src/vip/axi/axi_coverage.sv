`ifndef AXI_COVERAGE_SV
`define AXI_COVERAGE_SV

class axi_coverage extends uvm_subscriber #(axi_tx);

  `uvm_component_utils(axi_coverage)

  axi_config m_config;
  axi_tx     m_item;
  bit        m_is_covered;

  covergroup m_cov;
    option.per_instance = 1;

    cp_rwb: coverpoint m_item.rwb;
    cp_id: coverpoint m_item.id;
    cp_addr: coverpoint m_item.addr;
    // FIXME
    // cp_data: coverpoint m_item.data;
    // cp_byte_en: coverpoint m_item.byte_en;
    cp_burst_len_m1: coverpoint m_item.burst_len_m1;
    cp_burst_size_log2: coverpoint m_item.burst_size_log2;
    cp_burst_type: coverpoint m_item.burst_type;
    cp_lock: coverpoint m_item.lock;
    cp_cache: coverpoint m_item.cache;
    cp_prot: coverpoint m_item.prot;
    cp_qos: coverpoint m_item.qos;
    cp_region: coverpoint m_item.region;

  endgroup

  extern function new(string name, uvm_component parent);
  extern function void write(input axi_tx t);
  extern function void build_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi_coverage


function axi_coverage::new(string name, uvm_component parent);
  super.new(name, parent);
  m_is_covered = 0;
  m_cov = new();
endfunction : new


function void axi_coverage::write(input axi_tx t);
  if (m_config.coverage_enable) begin
    m_item = t;
    m_cov.sample();
    // Check coverage - could use m_cov.option.goal instead of 100 if your simulator supports it
    if (m_cov.get_inst_coverage() >= 100) m_is_covered = 1;
  end
endfunction : write


function void axi_coverage::build_phase(uvm_phase phase);
  if (!uvm_config_db#(axi_config)::get(this, "", "config", m_config))
    `uvm_fatal(get_type_name(), "fifo_in config not found")
endfunction : build_phase


function void axi_coverage::report_phase(uvm_phase phase);
  if (m_config.coverage_enable)
    `uvm_info(get_type_name(), $sformatf("Coverage score = %3.1f%%", m_cov.get_inst_coverage()),
              UVM_MEDIUM)
  else `uvm_info(get_type_name(), "Coverage disabled for this agent", UVM_MEDIUM)
endfunction : report_phase


`endif  // AXI_COVERAGE_SV
