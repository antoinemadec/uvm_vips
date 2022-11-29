`ifndef AXI_SEQ_ITEM_SV
`define AXI_SEQ_ITEM_SV

class axi_tx extends uvm_sequence_item;

  `uvm_object_utils(axi_tx)

  // transaction attributes
  rand bit rwb;
  rand bit [AXI_ID_WIDTH-1:0] id;
  rand bit [AXI_ADDR_WIDTH-1:0] addr;
  rand bit [AXI_DATA_WIDTH-1:0] data[$];
  rand bit [(AXI_DATA_WIDTH>>3)-1:0] byte_en[$];
  rand bit [7:0] burst_len_m1;
  rand bit [2:0] burst_size_log2;
  rand bit [1:0] burst_type;
  rand bit [1:0] lock;  // AXI3: 2 bits; AXI4: 1 bit
  rand bit [3:0] cache;
  rand bit [2:0] prot;
  rand bit [3:0] qos;  // AXI4 only
  rand bit [3:0] region;  // AXI4 only
  rand bit [1:0] resp;

  // delays
  extern function int rate_to_delay(int rate);
  rand int rate_aw;
  rand int rate_w;
  rand int rate_b;
  rand int rate_ar;
  rand int rate_r;
  int delay_aw;
  int delay_w;
  int delay_b;
  int delay_ar;
  int delay_r;

  // uvm functions
  extern function new(string name = "");
  extern function void do_copy(uvm_object rhs);
  extern function bit do_compare(uvm_object rhs, uvm_comparer comparer);
  extern function void do_print(uvm_printer printer);
  extern function void do_record(uvm_recorder recorder);
  extern function void do_pack(uvm_packer packer);
  extern function void do_unpack(uvm_packer packer);
  extern function string convert2string();

  // monitor/driver attributes
  bit write_cmd_has_been_sent = 0;
  bit write_data_has_been_sent = 0;

  // constraints
  constraint main_c {
    data.size() == burst_len_m1 + 1;
    byte_en.size() == burst_len_m1 + 1;
    // FIXME: support 1 beat of 32b for now @0x0
    addr == 0;
    // FIXME: to be implemented
    lock == 0;
    cache == 0;
    prot == 0;
    qos == 0;
    region == 0;
    resp == 0;
  }

  constraint delay_c {
    rate_aw inside {[1:100]};
    rate_w  inside {[1:100]};
    rate_b  inside {[1:100]};
    rate_ar inside {[1:100]};
    rate_r  inside {[1:100]};
  }

  function void post_randomize();
    delay_aw = rate_to_delay(rate_aw);
    delay_w = rate_to_delay(rate_w);
    delay_b = rate_to_delay(rate_b);
    delay_ar = rate_to_delay(rate_ar);
    delay_r = rate_to_delay(rate_r);
  endfunction

endclass : axi_tx


function axi_tx::new(string name = "");
  super.new(name);
endfunction : new


function void axi_tx::do_copy(uvm_object rhs);
  axi_tx rhs_;
  if (!$cast(rhs_, rhs)) `uvm_fatal(get_type_name(), "Cast of rhs object failed")
  super.do_copy(rhs);
  rwb = rhs_.rwb;
  id = rhs_.id;
  addr = rhs_.addr;
  data = rhs_.data;
  byte_en = rhs_.byte_en;
  burst_len_m1 = rhs_.burst_len_m1;
  burst_size_log2 = rhs_.burst_size_log2;
  burst_type = rhs_.burst_type;
  lock = rhs_.lock;
  cache = rhs_.cache;
  prot = rhs_.prot;
  qos = rhs_.qos;
  region = rhs_.region;
  resp = rhs_.resp;
  rate_aw = rhs_.rate_aw;
  rate_w = rhs_.rate_w;
  rate_b = rhs_.rate_b;
  rate_ar = rhs_.rate_ar;
  rate_r = rhs_.rate_r;
  delay_aw = rhs_.delay_aw;
  delay_w = rhs_.delay_w;
  delay_b = rhs_.delay_b;
  delay_ar = rhs_.delay_ar;
  delay_r = rhs_.delay_r;
endfunction : do_copy


function bit axi_tx::do_compare(uvm_object rhs, uvm_comparer comparer);
  bit result;
  axi_tx rhs_;
  if (!$cast(rhs_, rhs)) `uvm_fatal(get_type_name(), "Cast of rhs object failed")
  result = super.do_compare(rhs, comparer);
  result &= comparer.compare_field("rwb", rwb, rhs_.rwb, $bits(rwb));
  result &= comparer.compare_field("id", id, rhs_.id, $bits(id));
  result &= comparer.compare_field("addr", addr, rhs_.addr, $bits(addr));
  foreach (data[i]) result &= comparer.compare_field("data", data[i], rhs_.data[i], $bits(data[i]));
  foreach (byte_en[i])
    result &= comparer.compare_field("byte_en", byte_en[i], rhs_.byte_en[i], $bits(byte_en[i]));
  result &= comparer.compare_field(
      "burst_len_m1", burst_len_m1, rhs_.burst_len_m1, $bits(burst_len_m1)
  );
  result &= comparer.compare_field(
      "burst_size_log2", burst_size_log2, rhs_.burst_size_log2, $bits(burst_size_log2)
  );
  result &= comparer.compare_field("burst_type", burst_type, rhs_.burst_type, $bits(burst_type));
  result &= comparer.compare_field("lock", lock, rhs_.lock, $bits(lock));
  result &= comparer.compare_field("cache", cache, rhs_.cache, $bits(cache));
  result &= comparer.compare_field("prot", prot, rhs_.prot, $bits(prot));
  result &= comparer.compare_field("qos", qos, rhs_.qos, $bits(qos));
  result &= comparer.compare_field("region", region, rhs_.region, $bits(region));
  result &= comparer.compare_field("resp", resp, rhs_.resp, $bits(resp));
  return result;
endfunction : do_compare


function void axi_tx::do_print(uvm_printer printer);
  if (printer.knobs.sprint == 0) `uvm_info(get_type_name(), convert2string(), UVM_MEDIUM)
  else printer.m_string = convert2string();
endfunction : do_print


function void axi_tx::do_record(uvm_recorder recorder);
  super.do_record(recorder);
  `uvm_record_field("rwb", rwb)
  `uvm_record_field("id", id)
  `uvm_record_field("addr", addr)
  foreach (data[i]) `uvm_record_field({"data_", $sformatf("%0d", i)}, data[i])
  foreach (byte_en[i]) `uvm_record_field({"byte_en_", $sformatf("%0d", i)}, byte_en[i])
  `uvm_record_field("burst_len_m1", burst_len_m1)
  `uvm_record_field("burst_size_log2", burst_size_log2)
  `uvm_record_field("burst_type", burst_type)
  `uvm_record_field("lock", lock)
  `uvm_record_field("cache", cache)
  `uvm_record_field("prot", prot)
  `uvm_record_field("qos", qos)
  `uvm_record_field("region", region)
  `uvm_record_field("resp", resp)
endfunction : do_record


function void axi_tx::do_pack(uvm_packer packer);
  super.do_pack(packer);
  `uvm_pack_int(rwb)
  `uvm_pack_int(id)
  `uvm_pack_int(addr)
  `uvm_pack_sarray(data)
  `uvm_pack_sarray(byte_en)
  `uvm_pack_int(burst_len_m1)
  `uvm_pack_int(burst_size_log2)
  `uvm_pack_int(burst_type)
  `uvm_pack_int(lock)
  `uvm_pack_int(cache)
  `uvm_pack_int(prot)
  `uvm_pack_int(qos)
  `uvm_pack_int(region)
  `uvm_pack_int(resp)
endfunction : do_pack


function void axi_tx::do_unpack(uvm_packer packer);
  super.do_unpack(packer);
  `uvm_unpack_int(rwb)
  `uvm_unpack_int(id)
  `uvm_unpack_int(addr)
  `uvm_unpack_sarray(data)
  `uvm_unpack_sarray(byte_en)
  `uvm_unpack_int(burst_len_m1)
  `uvm_unpack_int(burst_size_log2)
  `uvm_unpack_int(burst_type)
  `uvm_unpack_int(lock)
  `uvm_unpack_int(cache)
  `uvm_unpack_int(prot)
  `uvm_unpack_int(qos)
  `uvm_unpack_int(region)
  `uvm_unpack_int(resp)
endfunction : do_unpack


function string axi_tx::convert2string();
  string s;
  $sformat(s, "%s\n", super.convert2string());
  $sformat(s, {"%s\n", "rwb = 'h%0h  'd%0d\n", "id = 'h%0h  'd%0d\n", "addr = 'h%0h  'd%0d\n",
               "data = %p\n", "byte_en = %p\n", "burst_len_m1 = 'h%0h  'd%0d\n",
               "burst_size_log2 = 'h%0h  'd%0d\n", "burst_type = 'h%0h  'd%0d\n",
               "lock = 'h%0h  'd%0d\n", "cache = 'h%0h  'd%0d\n", "prot = 'h%0h  'd%0d\n",
               "qos = 'h%0h  'd%0d\n", "region = 'h%0h  'd%0d\n", "resp = 'h%0h  'd%0d\n"},
           get_full_name(), rwb, rwb, id, id, addr, addr, data, byte_en, burst_len_m1,
           burst_len_m1, burst_size_log2, burst_size_log2, burst_type, burst_type, lock, lock,
           cache, cache, prot, prot, qos, qos, region, region, resp, resp);
  return s;
endfunction : convert2string


function int axi_tx::rate_to_delay(int rate);
  int delay;
  int r;
  if ((rate > 100) || (rate < 0)) begin
    `uvm_fatal(get_type_name(), $sformatf("rate=%0d is invalid.", rate))
  end
  delay = 0;
  r = $urandom_range(100, 1);
  while (r > rate) begin
    r = $urandom_range(100, 1);
    delay++;
  end
  return delay;
endfunction : rate_to_delay


`endif  // AXI_SEQ_ITEM_SV
