module top_tb;

  timeunit 1ns; timeprecision 1ps;

  `include "uvm_macros.svh"

  import uvm_pkg::*;

  import top_test_pkg::*;
  import top_pkg::top_config;

  top_config top_env_config;

  // test harness
  top_th th ();

  initial begin
    bit coverage_enable;
    coverage_enable = $test$plusargs("coverage_enable") ? 1 : 0;

    top_env_config  = new("top_env_config", coverage_enable);
    if (!top_env_config.randomize())
      `uvm_fatal("top_tb", "Failed to randomize top-level configuration object")

    top_env_config.m_axi_master_config.vif = th.axi_master_if;
    top_env_config.m_axi_slave_config.vif  = th.axi_slave_if;

    uvm_config_db#(top_config)::set(null, "uvm_test_top", "config", top_env_config);
    uvm_config_db#(top_config)::set(null, "uvm_test_top.m_env", "config", top_env_config);

    run_test();
  end

endmodule
