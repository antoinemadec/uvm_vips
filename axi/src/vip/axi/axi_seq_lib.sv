`ifndef AXI_SEQ_LIB_SV
`define AXI_SEQ_LIB_SV


typedef struct {
  bit [AXI_ADDR_WIDTH-1:0] addr_min;
  bit [AXI_ADDR_WIDTH-1:0] addr_max;
  int tx_nb;
} thread_struct_t;


// unique transaction
class axi_default_seq extends uvm_sequence #(axi_tx);
  `uvm_object_utils(axi_default_seq)

  axi_config  m_config;

  rand axi_tx m_tx;

  function new(string name = "");
    super.new(name);
    m_tx = axi_tx::type_id::create("m_tx");
  endfunction : new


  task body();
    `uvm_info(get_type_name(), "Default sequence starting", UVM_HIGH)

    start_item(m_tx);
    finish_item(m_tx);
    get_response(rsp, m_tx.get_transaction_id());

    `uvm_info(get_type_name(), "Default sequence completed", UVM_HIGH)
  endtask : body
endclass : axi_default_seq


// run transactions on parallel threads
// TODO: decoralate ID from th idx ?
//
// attributes:
//  - m_threads_q: define threads to be run
class axi_master_threads_seq extends uvm_sequence #(axi_tx);
  `uvm_object_utils(axi_master_threads_seq)

  axi_config m_config;

  thread_struct_t m_threads_q[$];

  function new(string name = "");
    super.new(name);
  endfunction : new


  task run_one_thread(thread_struct_t th, int id);
    `uvm_info(get_type_name(), $sformatf("thread: id=%0d; addr in [0x%x:0x%x]; tx_nb=%0d", id,
                                         th.addr_min, th.addr_max, th.tx_nb), UVM_LOW)

    repeat (th.tx_nb) begin
      axi_tx tx;
      tx = axi_tx::type_id::create("tx");
      start_item(tx);
      if (!tx.randomize() with {
            addr >= th.addr_min;
            addr <= th.addr_max;
            id == local:: id;
          })
        `uvm_fatal(get_type_name(), "Failed to randomize tx")
      finish_item(tx);
      get_response(rsp, tx.get_transaction_id());
    end
  endtask


  task body();
    foreach (m_threads_q[i]) begin
      automatic thread_struct_t th;
      automatic int id;
      th = m_threads_q[i];
      id = i;
      fork
        run_one_thread(th, id);
      join_none
    end
    wait fork;
  endtask : body
endclass : axi_master_threads_seq


// forever running slave
//
// attributes:
//  - m_outstandig_tx[0]: nb of max READ outstanding commands
//  - m_outstandig_tx[1]: nb of max WRITE outstanding commands
class axi_forever_slave_seq extends uvm_sequence #(axi_tx);
  `uvm_object_utils(axi_forever_slave_seq)

  axi_config m_config;

  int m_outstandig_tx[2] = {256, 256};

  function new(string name = "");
    super.new(name);
  endfunction : new


  task run_one_tx(bit rwb);
    axi_tx tx;
    tx = axi_tx::type_id::create("tx");
    start_item(tx);
    if (!tx.randomize() with {
          rwb == local:: rwb;
          // unused
          data.size() == 0;
          byte_en.size() == 0;
        })
      `uvm_fatal(get_type_name(), "Failed to randomize tx")
    finish_item(tx);
    get_response(rsp, tx.get_transaction_id());
  endtask


  task body();
    `uvm_info(get_type_name(),
              $sformatf("Forever slave sequence starting (outstanding read=%0d/write=%0d)",
                        m_outstandig_tx[1], m_outstandig_tx[0]), UVM_LOW)

    for (int rwb = 0; rwb < 2; rwb++) begin
      for (int out_idx = 0; out_idx < m_outstandig_tx[rwb]; out_idx++) begin
        automatic bit rwb_auto;
        rwb_auto = rwb;
        fork
          forever begin
            run_one_tx(rwb_auto);
          end
        join_none
      end
    end

    wait fork;
  endtask : body
endclass : axi_forever_slave_seq


`endif  // AXI_SEQ_LIB_SV
