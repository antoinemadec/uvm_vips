# ⚡️ AXI VIP
🚧 Work in progress 🚧

[UVM](https://en.wikipedia.org/wiki/Universal_Verification_Methodology) Verification IP of the [AXI](https://developer.arm.com/documentation/ihi0022/e/AMBA-AXI3-and-AXI4-Protocol-Specification) protocol.  
Follows [Doulos' easier_uvm](https://www.doulos.com/knowhow/systemverilog/uvm/easier-uvm/) guidelines.

## 💡 Rationale
   - keep it simple
   - easy to reuse
   - follow standards
   - provide comprehensive test suite
   - error out when not supported

## ✨ Features
This VIP, was generated with [**uvm_code_gen**](https://github.com/antoinemadec/uvm_code_gen).  
It follows [Doulos' easier_uvm](https://www.doulos.com/knowhow/systemverilog/uvm/easier-uvm/) guidelines and implement the following:
  - VIP (agent, interface, sequence, coverage)
  - top-level environment
    - testbench
    - env (scoreboard, VIP, coverage)
    - virtual sequence
  - run script

## 🚀 Usage
TODO

## 🚧 TODO
  - finish AXI3
    - add support for
      - FIXED and WRAP burst type
      - lock, cache, prot, qos, region
    - narrow xfer
  - implement AXI4
  - more sequences
    - make command always busy
    - th_idx != id ?
  - code factorization (slave/monitor)
  - better naming convention ?
  - improve doc

## 🙏 Credits
  - [Doulos' easier_uvm](https://www.doulos.com/knowhow/systemverilog/uvm/easier-uvm/)
  - [marcoz001's axi_uvm](https://github.com/marcoz001/axi-uvm)
  - [uvm_code_gen](https://github.com/antoinemadec/uvm_code_gen)
