`ifndef AXI_SLAVE_DRIVER_SV
`define AXI_SLAVE_DRIVER_SV

class axi_slave_driver extends axi_driver;

  `uvm_component_utils(axi_slave_driver)

  extern function new(string name, uvm_component parent);

  extern task run_phase(uvm_phase phase);
  extern task do_drive();

endclass : axi_slave_driver


function axi_slave_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


task axi_slave_driver::run_phase(uvm_phase phase);
  `uvm_info(get_type_name(), "run_phase", UVM_HIGH)

  forever begin
    seq_item_port.get_next_item(req);
    `uvm_info(get_type_name(), {"req item\n", req.sprint}, UVM_DEBUG)
    do_drive();
    seq_item_port.item_done();
  end
endtask : run_phase


task axi_slave_driver::do_drive();
  `uvm_fatal(get_type_name(), "TODO: fill do_drive()");
endtask : do_drive


`endif  // AXI_SLAVE_DRIVER_SV
