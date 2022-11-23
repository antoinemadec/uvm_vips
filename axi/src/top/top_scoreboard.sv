`ifndef TOP_SCOREBOARD
`define TOP_SCOREBOARD

`uvm_analysis_imp_decl(_from_axi_master)
`uvm_analysis_imp_decl(_from_axi_slave)

class top_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(top_scoreboard)

  uvm_analysis_imp_from_axi_master #(axi_tx, top_scoreboard) axi_master_export;
  uvm_analysis_imp_from_axi_slave #(axi_tx, top_scoreboard) axi_slave_export;

  top_config m_config;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    if (!uvm_config_db#(top_config)::get(this, "", "config", m_config))
      `uvm_fatal(get_type_name(), "Unable to get top_config")
    axi_master_export = new("axi_master_export", this);
    axi_slave_export  = new("axi_slave_export", this);
  endfunction : new


  virtual function void write_from_axi_master(input axi_tx pkt);
    `uvm_info(get_type_name(), $sformatf(
              "Received tx from axi_master: %s", pkt.sprint(uvm_default_line_printer)), UVM_HIGH)
  endfunction : write_from_axi_master


  virtual function void write_from_axi_slave(input axi_tx pkt);
    `uvm_info(get_type_name(), $sformatf(
              "Received tx from axi_slave: %s", pkt.sprint(uvm_default_line_printer)), UVM_HIGH)
  endfunction : write_from_axi_slave


endclass : top_scoreboard


`endif  //  `ifndef TOP_SCOREBOARD
