`ifndef AXI_MONITOR_SV
`define AXI_MONITOR_SV

class axi_monitor extends uvm_monitor;

  `uvm_component_utils(axi_monitor)

  virtual axi_if vif;

  axi_config m_config;

  uvm_analysis_port #(axi_tx) analysis_port;

  axi_tx m_trans;

  extern function new(string name, uvm_component parent);

  extern task run_phase(uvm_phase phase);
  extern task do_mon();

endclass : axi_monitor


function axi_monitor::new(string name, uvm_component parent);
  super.new(name, parent);
  analysis_port = new("analysis_port", this);
endfunction : new


task axi_monitor::run_phase(uvm_phase phase);
  `uvm_info(get_type_name(), "run_phase", UVM_HIGH)

  m_trans = axi_tx::type_id::create("m_trans");
  do_mon();
endtask : run_phase


task axi_monitor::do_mon();
  `uvm_fatal(get_type_name(), "TODO: fill do_mon()");
endtask : do_mon


`endif  // AXI_MONITOR_SV
