`ifndef AXI_SLAVE_DRIVER_SV
`define AXI_SLAVE_DRIVER_SV

class axi_slave_driver extends axi_driver;

  `uvm_component_utils(axi_slave_driver)

  extern function new(string name, uvm_component parent);

  bit [7:0] m_mem[*];

  // tx: received from the sequencer
  axi_tx m_write_cmd_delays[$];
  axi_tx m_write_data_delays[$];
  axi_tx m_read_cmd_delays[$];

  // tx: for internal storage
  axi_tx m_write_cmd_q_from_id[int][$];
  axi_tx m_wdata_from_id[int];
  axi_tx m_write_resp_q_from_id[int][$];
  axi_tx m_read_cmd_q_from_id[int][$];

  // run phase funtions
  extern task run_phase(uvm_phase phase);
  extern task get_tx_items();
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
  extern function void write_tx_in_mem(axi_tx tx);
  extern function bit [AXI_DATA_WIDTH-1:0] read_nth_data_of_tx_in_mem(axi_tx tx);

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
    get_tx_items();
    do_write_cmd();
    do_write_data();
    do_write_rsp();
    do_read_data();
    do_read_cmd();
  join_none
endtask : run_phase


task axi_slave_driver::get_tx_items();
  forever begin
    axi_tx req_copy;
    seq_item_port.get(req);
    `uvm_info(get_type_name(), {"req item\n", req.sprint}, UVM_DEBUG)
    req_copy = axi_tx::type_id::create("req_copy");
    req_copy.set_id_info(req);
    req_copy.do_copy(req);
    if (req.rwb == 0) begin
      m_write_cmd_delays.push_back(req_copy);
      m_write_data_delays.push_back(req_copy);
    end else begin
      m_read_cmd_delays.push_back(req_copy);
    end
  end
endtask : get_tx_items


task axi_slave_driver::do_write_cmd();
  forever begin
    axi_tx tx;

    wait (m_write_cmd_delays.size() > 0);
    tx = m_write_cmd_delays.pop_front();
    repeat (tx.rate_to_delay(tx.rate_aw)) @(vif.cb_drv_s);

    vif.cb_drv_s.AWREADY <= 1;
    @(vif.cb_drv_s);
    while (vif.cb_drv_s.AWVALID !== 1) @(vif.cb_drv_s);

    vif.cb_drv_s.AWREADY <= 0;
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
    tx.data            = {};
    tx.byte_en         = {};
    tx.resp            = {};
    m_write_cmd_q_from_id[tx.id].push_back(tx);
    update_write_resp_q(tx.id);
  end
endtask : do_write_cmd


task axi_slave_driver::do_write_data();
  forever begin
    int id;
    axi_tx tx;

    wait (m_write_data_delays.size() > 0);
    tx = m_write_data_delays[0];
    repeat (tx.rate_to_delay(tx.rate_w)) @(vif.cb_drv_s);

    vif.cb_drv_s.WREADY <= 1;
    @(vif.cb_drv_s);
    while (vif.cb_drv_s.WVALID !== 1) @(vif.cb_drv_s);

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
    int id;
    axi_tx tx;

    wait_on_queues(m_write_resp_q_from_id);
    id = get_available_id(m_write_resp_q_from_id);
    tx = m_write_resp_q_from_id[id].pop_front();
    repeat (tx.rate_to_delay(tx.rate_b)) @(vif.cb_drv_s);
    write_tx_in_mem(tx);

    vif.cb_drv_s.BVALID <= 1;
    vif.cb_drv_s.BID    <= id;
    vif.cb_drv_s.BRESP  <= 0;
    @(vif.cb_drv_s);
    while (vif.cb_drv_s.BREADY !== 1) @(vif.cb_drv_s);

    vif.cb_drv_s.BVALID <= 0;
    set_b_data_signals_to_X();
    seq_item_port.put(tx);
  end
endtask : do_write_rsp


task axi_slave_driver::do_read_cmd();
  forever begin
    int id;
    axi_tx tx;

    wait (m_read_cmd_delays.size() > 0);
    tx = m_read_cmd_delays.pop_front();
    repeat (tx.rate_to_delay(tx.rate_ar)) @(vif.cb_drv_s);

    vif.cb_drv_s.ARREADY <= 1;
    @(vif.cb_drv_s);
    while (vif.cb_drv_s.ARVALID !== 1) @(vif.cb_drv_s);

    vif.cb_drv_s.ARREADY <= 0;
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
    tx.data            = {};
    tx.byte_en         = {};
    tx.resp            = {};
    m_read_cmd_q_from_id[tx.id].push_back(tx);
  end
endtask : do_read_cmd


// FIXME: handle multiple beats
task axi_slave_driver::do_read_data();
  forever begin
    bit is_last;
    bit [AXI_DATA_WIDTH-1:0] rdata;
    int id;
    axi_tx tx;

    wait_on_queues(m_read_cmd_q_from_id);
    id = get_available_id(m_read_cmd_q_from_id);
    tx = m_read_cmd_q_from_id[id][0];
    repeat (tx.rate_to_delay(tx.rate_r)) @(vif.cb_drv_s);
    rdata = read_nth_data_of_tx_in_mem(tx);
    tx.data.push_back(rdata);
    is_last = (tx.data.size() == (tx.burst_len_m1 + 1));

    vif.cb_drv_s.RVALID <= 1;
    vif.cb_drv_s.RID    <= id;
    vif.cb_drv_s.RDATA  <= rdata;
    vif.cb_drv_s.RRESP  <= 0;
    vif.cb_drv_s.RLAST  <= is_last;
    @(vif.cb_drv_s);
    while (vif.cb_drv_s.RREADY !== 1) @(vif.cb_drv_s);

    vif.cb_drv_s.RVALID <= 0;
    set_r_data_signals_to_X();
    if (is_last) begin
      void'(m_read_cmd_q_from_id[id].pop_front());
      seq_item_port.put(tx);
    end
  end
endtask : do_read_data


task axi_slave_driver::set_b_data_signals_to_X();
  vif.cb_drv_s.BID   <= 'hx;
  vif.cb_drv_s.BRESP <= 'hx;
endtask : set_b_data_signals_to_X


task axi_slave_driver::set_r_data_signals_to_X();
  vif.cb_drv_s.RID   <= 'hx;
  vif.cb_drv_s.RDATA <= {AXI_DATA_WIDTH{1'bx}};
  vif.cb_drv_s.RRESP <= 'hx;
  vif.cb_drv_s.RLAST <= 'hx;
endtask : set_r_data_signals_to_X


function void axi_slave_driver::update_write_resp_q(int id);
  // verilog_format: off  // better alignment than the tool's
  if (!queue_is_empty(m_write_cmd_q_from_id, id) &&
    m_wdata_from_id.exists(id) && m_wdata_from_id[id].data.size() > 0) begin
  // verilog_format: on
    axi_tx tx;
    tx = m_write_cmd_q_from_id[id][0];
    while (m_wdata_from_id[id].data.size() != 0) begin
      tx.data.push_back(m_wdata_from_id[id].data.pop_front());
      tx.byte_en.push_back(m_wdata_from_id[id].byte_en.pop_front());
      if (tx.data.size() == (tx.burst_len_m1 + 1)) begin
        void'(m_write_cmd_q_from_id[id].pop_front());
        void'(m_write_data_delays.pop_front());
        m_write_resp_q_from_id[id].push_back(tx);
        break;
      end
    end
  end
endfunction


function bit axi_slave_driver::queue_is_empty(ref axi_tx q_from_id[int][$], int id);
  return !q_from_id.exists(id) || (q_from_id[id].size() == 0);
endfunction


function void axi_slave_driver::write_tx_in_mem(axi_tx tx);
  foreach (tx.data[beat_idx]) begin
    bit [AXI_ADDR_WIDTH-1:0] addr;
    addr = tx.get_nth_addr(beat_idx);
    for (int byte_idx = 0; byte_idx < AXI_STRB_WIDTH; byte_idx++) begin
      if (tx.byte_en[beat_idx][byte_idx]) begin
        m_mem[addr+byte_idx] = (tx.data[beat_idx] >> byte_idx * 8) & 8'hff;
      end
    end
  end
endfunction


function bit [AXI_DATA_WIDTH-1:0] axi_slave_driver::read_nth_data_of_tx_in_mem(axi_tx tx);
  bit [AXI_ADDR_WIDTH-1:0] addr;
  bit [AXI_DATA_WIDTH-1:0] rdata;
  addr = tx.get_nth_addr(tx.data.size());
  for (int byte_idx = 0; byte_idx < AXI_STRB_WIDTH; byte_idx++) begin
    rdata[byte_idx*8+:8] = m_mem[addr+byte_idx];
  end
  return rdata;
endfunction


`endif  // AXI_SLAVE_DRIVER_SV
