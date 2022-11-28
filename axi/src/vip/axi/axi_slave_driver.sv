`ifndef AXI_SLAVE_DRIVER_SV
`define AXI_SLAVE_DRIVER_SV

class axi_slave_driver extends axi_driver;

  `uvm_component_utils(axi_slave_driver)

  extern function new(string name, uvm_component parent);

  bit [AXI_DATA_WIDTH-1:0] mem[*];

  axi_tx m_write_cmd_q_from_id[int] [$];
  axi_tx m_wdata_from_id[int];
  axi_tx m_write_resp_q_from_id[int][$];
  axi_tx m_read_cmd_q_from_id[int]  [$];

  // run phase funtions
  extern task run_phase(uvm_phase phase);
  extern task do_write_cmd();
  extern task do_write_data();
  extern task do_write_rsp();
  extern task do_read_data();
  extern task do_read_cmd();

  // utils
  extern task set_b_data_signals_to_X();
  extern task set_r_data_signals_to_X();
  extern function void update_write_resp_q(int id);
  extern function bit queue_is_empty(ref axi_tx q_from_id[int][$], int id);

endclass : axi_slave_driver


function axi_slave_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


task axi_slave_driver::run_phase(uvm_phase phase);
  `uvm_info(get_type_name(), "run_phase", UVM_HIGH)

  // init
  vif.cb_drv_s.AWREADY <= 0;
  vif.cb_drv_s.WREADY  <= 0;
  vif.cb_drv_s.BVALID  <= 0;
  vif.cb_drv_s.ARREADY <= 0;
  vif.cb_drv_s.RVALID  <= 0;
  set_b_data_signals_to_X();
  set_r_data_signals_to_X();
  while (vif.cb_drv_s.ARESETn !== 1) @(vif.cb_drv_s);

  fork
    do_write_cmd();
    do_write_data();
    do_write_rsp();
    do_read_data();
    do_read_cmd();
  join_none
endtask : run_phase


task axi_slave_driver::do_write_cmd();
  forever begin
    axi_tx tx;

    vif.cb_drv_s.AWREADY <= 1;
    @(vif.cb_drv_s);
    while (vif.cb_drv_s.AWVALID !== 1) @(vif.cb_drv_s);

    vif.cb_drv_s.AWREADY <= 0;
    tx = axi_tx::type_id::create("tx");
    tx.rwb             = 0;
    tx.id              = vif.cb_drv_s.AWID;
    tx.addr            = vif.cb_drv_s.AWADDR;
    tx.burst_len_m1    = vif.cb_drv_s.AWLEN;
    tx.burst_size_log2 = vif.cb_drv_s.AWSIZE;
    tx.burst_type      = vif.cb_drv_s.AWBURST;
    tx.lock            = vif.cb_drv_s.AWLOCK;
    tx.cache           = vif.cb_drv_s.AWCACHE;
    tx.prot            = vif.cb_drv_s.AWPROT;
    tx.qos             = vif.cb_drv_s.AWQOS;
    tx.region          = vif.cb_drv_s.AWREGION;
    m_write_cmd_q_from_id[tx.id].push_back(tx);
    update_write_resp_q(tx.id);
  end
endtask : do_write_cmd


// FIXME: handle multiple beats
task axi_slave_driver::do_write_data();
  forever begin
    int id;

    vif.cb_drv_s.WREADY <= 1;
    @(vif.cb_drv_s);
    while (vif.cb_drv_s.WVALID !==1) @(vif.cb_drv_s);

    vif.cb_drv_s.WREADY <= 0;
    id = vif.cb_drv_s.WID;
    if (!m_wdata_from_id.exists(id)) begin
      m_wdata_from_id[id] = axi_tx::type_id::create("wdata");
    end
    m_wdata_from_id[id].data.push_back(vif.cb_drv_s.WDATA);
    m_wdata_from_id[id].byte_en.push_back(vif.cb_drv_s.WSTRB);
    update_write_resp_q(id);
  end
endtask : do_write_data


task axi_slave_driver::do_write_rsp();
  forever begin
    axi_tx tx;
    int id;

    wait_on_queue(m_write_resp_q_from_id);
    id = get_available_id(m_write_resp_q_from_id);
    tx = m_write_resp_q_from_id[id].pop_front();
    mem[tx.addr] = tx.data[0];

    vif.cb_drv_s.BVALID <= 1;
    vif.cb_drv_s.BID    <= id;
    vif.cb_drv_s.BRESP  <= 0;
    @(vif.cb_drv_s);
    while (vif.cb_drv_s.BREADY !== 1) @(vif.cb_drv_s);

    vif.cb_drv_s.BVALID <= 0;
    set_b_data_signals_to_X();
  end
endtask : do_write_rsp


task axi_slave_driver::do_read_cmd();
  forever begin
    int id;
    axi_tx tx;

    vif.cb_drv_s.ARREADY <= 1;
    @(vif.cb_drv_s);
    while (vif.cb_drv_s.ARVALID !==1) @(vif.cb_drv_s);

    vif.cb_drv_s.ARREADY <= 0;
    tx = axi_tx::type_id::create("tx");
    tx.rwb             = 1;
    tx.id              = vif.cb_drv_s.ARID;
    tx.addr            = vif.cb_drv_s.ARADDR;
    tx.burst_len_m1    = vif.cb_drv_s.ARLEN;
    tx.burst_size_log2 = vif.cb_drv_s.ARSIZE;
    tx.burst_type      = vif.cb_drv_s.ARBURST;
    tx.lock            = vif.cb_drv_s.ARLOCK;
    tx.cache           = vif.cb_drv_s.ARCACHE;
    tx.prot            = vif.cb_drv_s.ARPROT;
    tx.qos             = vif.cb_drv_s.ARQOS;
    tx.region          = vif.cb_drv_s.ARREGION;
    m_read_cmd_q_from_id[tx.id].push_back(tx);
  end
endtask : do_read_cmd


// FIXME: handle multiple beats
task axi_slave_driver::do_read_data();
  forever begin
    axi_tx tx;
    int id;

    wait_on_queue(m_read_cmd_q_from_id);
    id = get_available_id(m_read_cmd_q_from_id);
    tx = m_read_cmd_q_from_id[id].pop_front();

    vif.cb_drv_s.RVALID <= 1;
    vif.cb_drv_s.RID    <= id;
    vif.cb_drv_s.RDATA  <= mem[tx.addr];
    vif.cb_drv_s.RRESP  <= 0;
    vif.cb_drv_s.RLAST  <= 1;
    @(vif.cb_drv_s);
    while (vif.cb_drv_s.RREADY !== 1) @(vif.cb_drv_s);

    vif.cb_drv_s.RVALID <= 0;
    set_r_data_signals_to_X();
  end
endtask : do_read_data


task axi_slave_driver::set_b_data_signals_to_X();
    vif.cb_drv_s.BID <= 'hx;
    vif.cb_drv_s.BRESP <= 'hx;
endtask : set_b_data_signals_to_X


task axi_slave_driver::set_r_data_signals_to_X();
    vif.cb_drv_s.RID <= 'hx;
    vif.cb_drv_s.RDATA <= {AXI_DATA_WIDTH{1'bx}};
    vif.cb_drv_s.RRESP <= 'hx;
    vif.cb_drv_s.RLAST <= 'hx;
endtask : set_r_data_signals_to_X


function void axi_slave_driver::update_write_resp_q(int id);
  if (!queue_is_empty(m_write_cmd_q_from_id, id) &&
    m_wdata_from_id.exists(id) && m_wdata_from_id[id].data.size() > 0) begin
    axi_tx tx;
    tx = m_write_cmd_q_from_id[id].pop_front();
    tx.data[0]    = m_wdata_from_id[id].data.pop_front();
    tx.byte_en[0] = m_wdata_from_id[id].byte_en.pop_front();
    m_write_resp_q_from_id[id].push_back(tx);
  end
endfunction


function bit axi_slave_driver::queue_is_empty(ref axi_tx q_from_id[int][$], int id);
  return !q_from_id.exists(id) || (q_from_id[id].size() == 0);
endfunction


`endif  // AXI_SLAVE_DRIVER_SV
