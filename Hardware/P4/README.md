# Hardware Implementation

## Testbed Setup

Our testbed consists of a Wedge 100BF-32X switch (with Intel Tofino ASIC) with 32 x 100 Gbps ports, along with a network traffic generator that equips an 18-core Intel Xeon W-2295 3.00 GHz CPU, 256 GB RAM, and an Intel XL710 Dual Port 40G QSFP+ Converged Network Adapter. We utilize the Tcpreplay to replay the real-world CAIDA traces.

## Description

We have fully implemented Expiration Filter with about 400 lines of codes in P4 language, including all the register actions and metadata in the data plane, and compiled it to the Tofino switch by Intel P4 Studio Software Development Environment (SDE). Meanwhile, the table entries of the switch are configured in control plane of the switch using Bfrt Python while the communication between data and control planes is realized through PCIe-based P4Runtime API.


We allocated about 500 KB for the hardware implementation and set the space occupation ratio between the filter and the sketch as 0.2. We use registers to implement the bucket arrays of k=3 stages and CM sketch, where registers are a kind of stateful object. Due to implementation limitations, each register contains an 8-bit index field and an 8-bit counter field. We leverage the SALU (Stateful ALU) in each stage to look up and update the entries in the registers. We count the leading zeros of the generated random binary strings using a longest-prefix-match table implemented with TCAM.
