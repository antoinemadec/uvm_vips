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
    - fork threads
    - all bursts
    - narrow xfer
    - add slave auto mode
  - implement AXI4
  - improve doc

## 🙏 Credits
  - [Doulos' easier_uvm](https://www.doulos.com/knowhow/systemverilog/uvm/easier-uvm/)
  - [marcoz001's axi_uvm](https://github.com/marcoz001/axi-uvm)
  - [uvm_code_gen](https://github.com/antoinemadec/uvm_code_gen)
