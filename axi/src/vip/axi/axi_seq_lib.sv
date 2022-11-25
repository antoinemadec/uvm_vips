`ifndef AXI_SEQ_LIB_SV
`define AXI_SEQ_LIB_SV

class axi_default_seq extends uvm_sequence #(axi_tx);

  `uvm_object_utils(axi_default_seq)

  axi_config m_config;

  extern function new(string name = "");
  extern task body();

endclass : axi_default_seq


function axi_default_seq::new(string name = "");
  super.new(name);
endfunction : new


task axi_default_seq::body();
  `uvm_info(get_type_name(), "Default sequence starting", UVM_HIGH)

  req = axi_tx::type_id::create("req");
  start_item(req);
  if (!req.randomize()) `uvm_fatal(get_type_name(), "Failed to randomize transaction")
  finish_item(req);
  get_response(rsp, req.get_transaction_id());

  `uvm_info(get_type_name(), "Default sequence completed", UVM_HIGH)
endtask : body

`endif  // AXI_SEQ_LIB_SV
