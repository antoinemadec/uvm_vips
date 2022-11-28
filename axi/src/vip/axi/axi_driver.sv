`ifndef AXI_DRIVER_SV
`define AXI_DRIVER_SV

class axi_driver extends uvm_driver #(axi_tx);

  `uvm_component_utils(axi_driver)

  virtual axi_if vif;

  axi_config m_config;

  extern function new(string name, uvm_component parent);
  extern task wait_on_queue(ref axi_tx q_from_id[int][$]);
  extern function int get_available_id(ref axi_tx q_from_id[int][$]);
endclass : axi_driver


function axi_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


task axi_driver::wait_on_queue(ref axi_tx q_from_id[int][$]);
  wait ((q_from_id.sum with (int'(item.size()))) > 0);
endtask : wait_on_queue


function int axi_driver::get_available_id(ref axi_tx q_from_id[int][$]);
  int available_ids[$];
  available_ids = q_from_id.find_index with (item.size() > 0);
  return available_ids[$urandom_range(available_ids.size()-1)];
endfunction : get_available_id


`endif  // AXI_DRIVER_SV
