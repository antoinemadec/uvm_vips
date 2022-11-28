`ifndef AXI_MONITOR_SV
`define AXI_MONITOR_SV

class axi_monitor extends uvm_monitor;

  `uvm_component_utils(axi_monitor)

  virtual axi_if vif;

  axi_config m_config;

  uvm_analysis_port #(axi_tx) analysis_port;

  axi_tx m_write_cmd_q_from_id[int] [$];
  axi_tx m_wdata_from_id[int];
  axi_tx m_write_resp_q_from_id[int][$];
  axi_tx m_read_cmd_q_from_id[int]  [$];

  extern function new(string name, uvm_component parent);

  // run phase funtions
  extern task run_phase(uvm_phase phase);
  extern task do_write_cmd();
  extern task do_write_data();
  extern task do_write_rsp();
  extern task do_read_data();
  extern task do_read_cmd();

  // utils
  extern function void update_write_resp_q(int id);
  extern function bit queue_is_empty(ref axi_tx q_from_id[int][$], int id);

endclass : axi_monitor


function axi_monitor::new(string name, uvm_component parent);
  super.new(name, parent);
  analysis_port = new("analysis_port", this);
endfunction : new


task axi_monitor::run_phase(uvm_phase phase);
  `uvm_info(get_type_name(), "run_phase", UVM_HIGH)

  while (vif.cb_mon.ARESETn !== 1) @(vif.cb_mon);

  fork
    do_write_cmd();
    do_write_data();
    do_write_rsp();
    do_read_data();
    do_read_cmd();
  join_none
endtask : run_phase


task axi_monitor::do_write_cmd();
  forever begin
    axi_tx tx;

    @(vif.cb_mon);
    while (vif.cb_mon.AWREADY !== 1 || vif.cb_mon.AWVALID !==1) @(vif.cb_mon);

    tx = axi_tx::type_id::create("tx");
    tx.rwb             = 0;
    tx.id              = vif.cb_mon.AWID;
    tx.addr            = vif.cb_mon.AWADDR;
    tx.burst_len_m1    = vif.cb_mon.AWLEN;
    tx.burst_size_log2 = vif.cb_mon.AWSIZE;
    tx.burst_type      = vif.cb_mon.AWBURST;
    tx.lock            = vif.cb_mon.AWLOCK;
    tx.cache           = vif.cb_mon.AWCACHE;
    tx.prot            = vif.cb_mon.AWPROT;
    tx.qos             = vif.cb_mon.AWQOS;
    tx.region          = vif.cb_mon.AWREGION;
    m_write_cmd_q_from_id[tx.id].push_back(tx);
    update_write_resp_q(tx.id);
  end
endtask : do_write_cmd


// FIXME: handle multiple beats
task axi_monitor::do_write_data();
  forever begin
    int id;

    @(vif.cb_mon);
    while (vif.cb_mon.WREADY !== 1 || vif.cb_mon.WVALID !==1) @(vif.cb_mon);

    id = vif.cb_mon.WID;
    if (!m_wdata_from_id.exists(id)) begin
      m_wdata_from_id[id] = axi_tx::type_id::create("wdata");
    end
    m_wdata_from_id[id].data.push_back(vif.cb_mon.WDATA);
    m_wdata_from_id[id].byte_en.push_back(vif.cb_mon.WSTRB);
    update_write_resp_q(id);
  end
endtask : do_write_data


task axi_monitor::do_write_rsp();
  forever begin
    axi_tx tx;
    int id;

    @(vif.cb_mon);
    while (vif.cb_mon.BREADY !== 1 || vif.cb_mon.BVALID !==1) @(vif.cb_mon);

    id = vif.cb_mon.BID;
    if (queue_is_empty(m_write_resp_q_from_id, id)) begin
      `uvm_fatal(get_type_name(), $sformatf("received unexpected BRESP for id=%0d", id))
    end
    tx = m_write_resp_q_from_id[id].pop_front();
    tx.resp = vif.cb_mon.BRESP;
    analysis_port.write(tx);
  end
endtask : do_write_rsp


task axi_monitor::do_read_cmd();
  forever begin
    axi_tx tx;

    @(vif.cb_mon);
    while (vif.cb_mon.ARREADY !== 1 || vif.cb_mon.ARVALID !==1) @(vif.cb_mon);

    tx = axi_tx::type_id::create("tx");
    tx.rwb             = 1;
    tx.id              = vif.cb_mon.ARID;
    tx.addr            = vif.cb_mon.ARADDR;
    tx.burst_len_m1    = vif.cb_mon.ARLEN;
    tx.burst_size_log2 = vif.cb_mon.ARSIZE;
    tx.burst_type      = vif.cb_mon.ARBURST;
    tx.lock            = vif.cb_mon.ARLOCK;
    tx.cache           = vif.cb_mon.ARCACHE;
    tx.prot            = vif.cb_mon.ARPROT;
    tx.qos             = vif.cb_mon.ARQOS;
    tx.region          = vif.cb_mon.ARREGION;
    m_read_cmd_q_from_id[tx.id].push_back(tx);
  end
endtask : do_read_cmd


// FIXME: handle multiple beats
task axi_monitor::do_read_data();
  forever begin
    axi_tx tx;
    int id;

    @(vif.cb_mon);
    while (vif.cb_mon.RREADY !== 1 || vif.cb_mon.RVALID !==1) @(vif.cb_mon);

    id = vif.cb_mon.RID;
    if (queue_is_empty(m_read_cmd_q_from_id, id)) begin
      `uvm_fatal(get_type_name(), $sformatf("received unexpected RDATA for id=%0d", id))
    end
    tx            = m_read_cmd_q_from_id[id].pop_front();
    tx.data[0]    = vif.cb_mon.RDATA;
    tx.byte_en[0] = {AXI_STRB_WIDTH{1'b1}};
    tx.resp       = vif.cb_mon.RRESP;
    analysis_port.write(tx);
  end
endtask : do_read_data


// FIXME: handle multiple beats
function void axi_monitor::update_write_resp_q(int id);
  if (!queue_is_empty(m_write_cmd_q_from_id, id) &&
    m_wdata_from_id.exists(id) && m_wdata_from_id[id].data.size() > 0) begin
    axi_tx tx;
    tx = m_write_cmd_q_from_id[id].pop_front();
    tx.data[0]    = m_wdata_from_id[id].data.pop_front();
    tx.byte_en[0] = m_wdata_from_id[id].byte_en.pop_front();
    m_write_resp_q_from_id[id].push_back(tx);
  end
endfunction


function bit axi_monitor::queue_is_empty(ref axi_tx q_from_id[int][$], int id);
  return !q_from_id.exists(id) || (q_from_id[id].size() == 0);
endfunction


`endif  // AXI_MONITOR_SV
