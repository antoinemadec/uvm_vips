`ifndef TOP_SCOREBOARD
`define TOP_SCOREBOARD

`uvm_analysis_imp_decl(_from_axi_master)
`uvm_analysis_imp_decl(_from_axi_slave)

class top_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(top_scoreboard)

  uvm_analysis_imp_from_axi_master #(axi_tx, top_scoreboard) axi_master_export;
  uvm_analysis_imp_from_axi_slave #(axi_tx, top_scoreboard) axi_slave_export;

  top_config m_config;

  bit [7:0] m_mem[*];

  function new(string name, uvm_component parent);
    super.new(name, parent);
    if (!uvm_config_db#(top_config)::get(this, "", "config", m_config))
      `uvm_fatal(get_type_name(), "Unable to get top_config")
    axi_master_export = new("axi_master_export", this);
    axi_slave_export  = new("axi_slave_export", this);
  endfunction : new


  function void write_tx_in_mem(axi_tx tx);
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


  function void compare_read_tx_to_mem(axi_tx tx);
    foreach (tx.data[beat_idx]) begin
      bit [AXI_ADDR_WIDTH-1:0] addr;
      addr = tx.get_nth_addr(beat_idx);
      for (int byte_idx = 0; byte_idx < AXI_STRB_WIDTH; byte_idx++) begin
        bit [7:0] expected_byte;
        bit [7:0] actual_byte;
        expected_byte = m_mem[addr+byte_idx];
        actual_byte   = tx.data[beat_idx][byte_idx*8+:8];
        if (expected_byte !== actual_byte) begin
          `uvm_fatal(get_type_name(), $sformatf("[0x%x] expected data=0x%x but read 0x%x",
                                                addr + byte_idx, expected_byte, actual_byte))
        end
      end
    end
  endfunction


  virtual function void write_from_axi_master(input axi_tx pkt);
    for (int i = 0; i <= pkt.burst_len_m1; i++) begin
      `uvm_info(get_type_name(), pkt.print_nth_beat(i), UVM_LOW)
    end
    if (pkt.rwb) begin
      compare_read_tx_to_mem(pkt);
    end else begin
      write_tx_in_mem(pkt);
    end
  endfunction : write_from_axi_master


  virtual function void write_from_axi_slave(input axi_tx pkt);
    for (int i = 0; i <= pkt.burst_len_m1; i++) begin
      `uvm_info(get_type_name(), pkt.print_nth_beat(i), UVM_HIGH)
    end
  endfunction : write_from_axi_slave


endclass : top_scoreboard


`endif  //  `ifndef TOP_SCOREBOARD
