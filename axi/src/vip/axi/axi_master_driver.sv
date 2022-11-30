`ifndef AXI_MASTER_DRIVER_SV
`define AXI_MASTER_DRIVER_SV

class axi_master_driver extends axi_driver;

  `uvm_component_utils(axi_master_driver)

  axi_tx m_write_cmd_q_from_id[int][$];
  axi_tx m_write_data_q_from_id[int][$];
  axi_tx m_write_resp_q_from_id[int][$];
  axi_tx m_read_cmd_q_from_id[int][$];
  axi_tx m_read_data_q_from_id[int][$];

  // cannot predict which ID RDATA and BRESP are going to use,
  // instead, we save the delays of the latest command
  int m_delay_b;
  int m_delay_r;

  extern function new(string name, uvm_component parent);

  // run phase funtions
  extern task run_phase(uvm_phase phase);
  extern task get_tx_items();
  extern task do_write_cmd();
  extern task do_write_data();
  extern task do_write_rsp();
  extern task do_read_data();
  extern task do_read_cmd();

  // utils
  extern task set_aw_data_signals_to_X();
  extern task set_w_data_signals_to_X();
  extern task set_ar_data_signals_to_X();
  extern function void check_write_tx_has_been_issued(axi_tx tx);

endclass : axi_master_driver


function axi_master_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


task axi_master_driver::run_phase(uvm_phase phase);
  `uvm_info(get_type_name(), "run_phase", UVM_HIGH)

  // init
  vif.cb_drv_m.AWVALID <= 0;
  vif.cb_drv_m.WVALID  <= 0;
  vif.cb_drv_m.BREADY  <= 0;
  vif.cb_drv_m.ARVALID <= 0;
  vif.cb_drv_m.RREADY  <= 0;
  set_aw_data_signals_to_X();
  set_w_data_signals_to_X();
  set_ar_data_signals_to_X();
  while (vif.cb_drv_m.ARESETn !== 1) @(vif.cb_drv_m);

  fork
    get_tx_items();
    do_write_cmd();
    do_write_data();
    do_write_rsp();
    do_read_data();
    do_read_cmd();
  join_none
endtask : run_phase


task axi_master_driver::get_tx_items();
  forever begin
    axi_tx req_copy;
    seq_item_port.get(req);
    `uvm_info(get_type_name(), {"req item\n", req.sprint}, UVM_DEBUG)
    req_copy = axi_tx::type_id::create("req_copy");
    req_copy.set_id_info(req);
    req_copy.do_copy(req);
    if (req.rwb == 0) begin
      m_write_cmd_q_from_id[req.id].push_back(req_copy);
      m_write_data_q_from_id[req.id].push_back(req_copy);
    end else begin
      m_read_cmd_q_from_id[req.id].push_back(req_copy);
    end
  end
endtask : get_tx_items


task axi_master_driver::do_write_cmd();
  forever begin
    int id;
    axi_tx tx;

    wait_on_queues(m_write_cmd_q_from_id);
    id = get_available_id(m_write_cmd_q_from_id);
    tx = m_write_cmd_q_from_id[id].pop_front();
    repeat (tx.delay_aw) @(vif.cb_drv_m);

    vif.cb_drv_m.AWVALID  <= 1;
    vif.cb_drv_m.AWID     <= id;
    vif.cb_drv_m.AWADDR   <= tx.addr;
    vif.cb_drv_m.AWLEN    <= tx.burst_len_m1;
    vif.cb_drv_m.AWSIZE   <= tx.burst_size_log2;
    vif.cb_drv_m.AWBURST  <= tx.burst_type;
    vif.cb_drv_m.AWLOCK   <= tx.lock;
    vif.cb_drv_m.AWCACHE  <= tx.cache;
    vif.cb_drv_m.AWPROT   <= tx.prot;
    vif.cb_drv_m.AWQOS    <= tx.qos;
    vif.cb_drv_m.AWREGION <= tx.region;
    @(vif.cb_drv_m);
    while (vif.cb_drv_m.AWREADY !== 1) @(vif.cb_drv_m);

    vif.cb_drv_m.AWVALID <= 0;
    set_aw_data_signals_to_X();
    tx.write_cmd_has_been_sent = 1;
    check_write_tx_has_been_issued(tx);
  end
endtask : do_write_cmd


task axi_master_driver::do_write_data();
  forever begin
    int id;
    axi_tx tx;

    wait_on_queues(m_write_data_q_from_id);
    id = get_available_id(m_write_data_q_from_id);
    tx = m_write_data_q_from_id[id][0];
    repeat (tx.delay_w) @(vif.cb_drv_m);

    vif.cb_drv_m.WVALID <= 1;
    vif.cb_drv_m.WID    <= id;
    vif.cb_drv_m.WDATA  <= tx.data.pop_front();
    vif.cb_drv_m.WSTRB  <= tx.byte_en.pop_front();
    vif.cb_drv_m.WLAST  <= (tx.data.size() == 0);
    @(vif.cb_drv_m);
    while (vif.cb_drv_m.WREADY !== 1) @(vif.cb_drv_m);

    vif.cb_drv_m.WVALID <= 0;
    set_w_data_signals_to_X();
    if (tx.data.size() == 0) begin
      tx.write_data_has_been_sent = 1;
      void'(m_write_data_q_from_id[id].pop_front());
      check_write_tx_has_been_issued(tx);
    end
  end
endtask : do_write_data


task axi_master_driver::do_write_rsp();
  forever begin
    axi_tx tx;

    wait_on_queues(m_write_resp_q_from_id);
    repeat (m_delay_b) @(vif.cb_drv_m);

    vif.cb_drv_m.BREADY <= 1;
    @(vif.cb_drv_m);
    while (vif.cb_drv_m.BVALID !== 1) @(vif.cb_drv_m);

    vif.cb_drv_m.BREADY <= 0;
    tx = m_write_resp_q_from_id[vif.cb_drv_m.BID].pop_front();
    tx.resp[0] = vif.cb_drv_m.BRESP;
    seq_item_port.put(tx);
  end
endtask : do_write_rsp


task axi_master_driver::do_read_cmd();
  forever begin
    int id;
    axi_tx tx;

    wait_on_queues(m_read_cmd_q_from_id);
    id = get_available_id(m_read_cmd_q_from_id);
    tx = m_read_cmd_q_from_id[id].pop_front();
    m_delay_r = tx.delay_r;
    repeat (tx.delay_ar) @(vif.cb_drv_m);

    vif.cb_drv_m.ARVALID  <= 1;
    vif.cb_drv_m.ARID     <= id;
    vif.cb_drv_m.ARADDR   <= tx.addr;
    vif.cb_drv_m.ARLEN    <= tx.burst_len_m1;
    vif.cb_drv_m.ARSIZE   <= tx.burst_size_log2;
    vif.cb_drv_m.ARBURST  <= tx.burst_type;
    vif.cb_drv_m.ARLOCK   <= tx.lock;
    vif.cb_drv_m.ARCACHE  <= tx.cache;
    vif.cb_drv_m.ARPROT   <= tx.prot;
    vif.cb_drv_m.ARQOS    <= tx.qos;
    vif.cb_drv_m.ARREGION <= tx.region;
    @(vif.cb_drv_m);
    while (vif.cb_drv_m.ARREADY !== 1) @(vif.cb_drv_m);

    vif.cb_drv_m.ARVALID <= 0;
    set_ar_data_signals_to_X();
    m_read_data_q_from_id[tx.id].push_back(tx);
  end
endtask : do_read_cmd


task axi_master_driver::do_read_data();
  forever begin
    int id;
    axi_tx tx;

    wait_on_queues(m_read_data_q_from_id);
    repeat (m_delay_r) @(vif.cb_drv_m);

    vif.cb_drv_m.RREADY <= 1;
    @(vif.cb_drv_m);
    while (vif.cb_drv_m.RVALID !== 1) @(vif.cb_drv_m);

    vif.cb_drv_m.RREADY <= 0;
    id = vif.cb_drv_m.RID;
    tx = m_read_data_q_from_id[id][0];
    tx.data.push_back(vif.cb_drv_m.RDATA);
    tx.byte_en.push_back({AXI_STRB_WIDTH{1'b1}});
    tx.resp.push_back(vif.cb_drv_m.RRESP);
    if (vif.cb_drv_m.RLAST) begin
      void'(m_read_data_q_from_id[id].pop_front());
      seq_item_port.put(tx);
    end
  end
endtask : do_read_data


task axi_master_driver::set_aw_data_signals_to_X();
  vif.cb_drv_m.AWID     <= {AXI_ID_WIDTH{1'bx}};
  vif.cb_drv_m.AWADDR   <= {AXI_ADDR_WIDTH{1'bx}};
  vif.cb_drv_m.AWLEN    <= 'hx;
  vif.cb_drv_m.AWSIZE   <= 'hx;
  vif.cb_drv_m.AWBURST  <= 'hx;
  vif.cb_drv_m.AWLOCK   <= 'hx;
  vif.cb_drv_m.AWCACHE  <= 'hx;
  vif.cb_drv_m.AWPROT   <= 'hx;
  vif.cb_drv_m.AWQOS    <= 'hx;
  vif.cb_drv_m.AWREGION <= 'hx;
endtask : set_aw_data_signals_to_X


task axi_master_driver::set_w_data_signals_to_X();
  vif.cb_drv_m.WID   <= {AXI_ID_WIDTH{1'bx}};
  vif.cb_drv_m.WDATA <= {AXI_DATA_WIDTH{1'bx}};
  vif.cb_drv_m.WSTRB <= {AXI_STRB_WIDTH{1'bx}};
  vif.cb_drv_m.WLAST <= 'hx;
endtask : set_w_data_signals_to_X


task axi_master_driver::set_ar_data_signals_to_X();
  vif.cb_drv_m.ARID     <= {AXI_ID_WIDTH{1'bx}};
  vif.cb_drv_m.ARADDR   <= {AXI_ADDR_WIDTH{1'bx}};
  vif.cb_drv_m.ARLEN    <= 'hx;
  vif.cb_drv_m.ARSIZE   <= 'hx;
  vif.cb_drv_m.ARBURST  <= 'hx;
  vif.cb_drv_m.ARLOCK   <= 'hx;
  vif.cb_drv_m.ARCACHE  <= 'hx;
  vif.cb_drv_m.ARPROT   <= 'hx;
  vif.cb_drv_m.ARQOS    <= 'hx;
  vif.cb_drv_m.ARREGION <= 'hx;
endtask : set_ar_data_signals_to_X


function void axi_master_driver::check_write_tx_has_been_issued(axi_tx tx);
  if (tx.write_cmd_has_been_sent && tx.write_data_has_been_sent) begin
    m_write_resp_q_from_id[tx.id].push_back(tx);
    m_delay_b = tx.delay_b;
  end
endfunction : check_write_tx_has_been_issued

`endif  // AXI_MASTER_DRIVER_SV
