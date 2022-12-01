`ifndef TOP_SEQ_LIB_SV
`define TOP_SEQ_LIB_SV

class top_default_seq extends uvm_sequence #(uvm_sequence_item);

  `uvm_object_utils(top_default_seq)

  top_config m_config;

  axi_agent m_axi_master_agent;
  axi_agent m_axi_slave_agent;

  int m_seq_count = 100;

  extern function new(string name = "");
  extern task body();
  extern task pre_start();
  extern task post_start();

  extern task run_master(thread_struct_t thread_q[$]);
  extern task run_slave(int max_outstanding_cmds);
endclass : top_default_seq


function top_default_seq::new(string name = "");
  super.new(name);
endfunction : new


task top_default_seq::body();
  `uvm_info(get_type_name(), "Default sequence starting", UVM_HIGH)

  fork
    run_slave(1 << AXI_ID_WIDTH);
  join_none

  begin
    thread_struct_t thread_q[$];
    for (int th_idx = 0; th_idx < 16; th_idx++) begin
      bit [AXI_ADDR_WIDTH-1:0] addr_base;
      addr_base = th_idx * 'h1000_0000;
      thread_q.push_back('{addr_min: addr_base, addr_max: addr_base + 'h400, tx_nb: 128});
    end
    run_master(thread_q);
  end

  `uvm_info(get_type_name(), "Default sequence completed", UVM_HIGH)
endtask : body


task top_default_seq::run_master(thread_struct_t thread_q[$]);
  axi_master_threads_seq seq;
  seq = axi_master_threads_seq::type_id::create("seq");
  seq.m_threads_q = thread_q;
  seq.set_item_context(this, m_axi_master_agent.m_sequencer);
  if (!seq.randomize()) `uvm_fatal(get_type_name(), "Failed to randomize sequence")
  seq.m_config = m_axi_master_agent.m_config;
  seq.set_starting_phase(get_starting_phase());
  seq.start(m_axi_master_agent.m_sequencer, this);
endtask : run_master


task top_default_seq::run_slave(int max_outstanding_cmds);
  axi_forever_slave_seq seq;
  seq = axi_forever_slave_seq::type_id::create("seq");
  seq.m_outstandig_tx = {max_outstanding_cmds, max_outstanding_cmds};
  seq.set_item_context(this, m_axi_slave_agent.m_sequencer);
  if (!seq.randomize()) `uvm_fatal(get_type_name(), "Failed to randomize sequence")
  seq.m_config = m_axi_slave_agent.m_config;
  seq.set_starting_phase(get_starting_phase());
  seq.start(m_axi_slave_agent.m_sequencer, this);
endtask : run_slave


task top_default_seq::pre_start();
  uvm_phase phase = get_starting_phase();
  if (phase != null) phase.raise_objection(this);
endtask : pre_start


task top_default_seq::post_start();
  uvm_phase phase = get_starting_phase();
  if (phase != null) phase.drop_objection(this);
endtask : post_start


`endif  // TOP_SEQ_LIB_SV
