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

  extern task run_slave();
endclass : top_default_seq


function top_default_seq::new(string name = "");
  super.new(name);
endfunction : new


task top_default_seq::body();
  `uvm_info(get_type_name(), "Default sequence starting", UVM_HIGH)

  run_slave();

  repeat (m_seq_count) begin
    if (m_axi_master_agent.m_config.is_active == UVM_ACTIVE) begin
      axi_default_seq seq;
      seq = axi_default_seq::type_id::create("seq");
      seq.set_item_context(this, m_axi_master_agent.m_sequencer);
      if (!seq.randomize()) `uvm_fatal(get_type_name(), "Failed to randomize sequence")
      seq.m_config = m_axi_master_agent.m_config;
      seq.set_starting_phase(get_starting_phase());
      seq.start(m_axi_master_agent.m_sequencer, this);
    end
  end

  `uvm_info(get_type_name(), "Default sequence completed", UVM_HIGH)
endtask : body


task top_default_seq::run_slave();
  if (m_axi_slave_agent.m_config.is_active == UVM_ACTIVE) begin
    for (int rwb = 0; rwb < 2; rwb++) begin
      automatic bit rwb_auto;
      rwb_auto = rwb;
      fork
        forever begin
          axi_default_seq seq;
          seq = axi_default_seq::type_id::create("seq");
          seq.set_item_context(this, m_axi_slave_agent.m_sequencer);
          if (!seq.randomize() with {tx.rwb == rwb_auto;})
            `uvm_fatal(get_type_name(), "Failed to randomize sequence")
          seq.m_config = m_axi_slave_agent.m_config;
          seq.set_starting_phase(get_starting_phase());
          seq.start(m_axi_slave_agent.m_sequencer, this);
        end
      join_none
    end
  end
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
