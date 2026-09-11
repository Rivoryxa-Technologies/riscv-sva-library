# riscv-sva-library

Reusable SystemVerilog Assertion (SVA) checkers for RTL and SoC verification.

These are drop-in checker modules you `bind` into a design (or instantiate in a
testbench) to catch protocol and structural bugs early, without rewriting the
same properties for every block. Each one works in simulation and can be handed
to a formal tool for exhaustive proof.

> **Verified:** lints clean under Verilator (`verilator --lint-only -sv`).

## Checkers

| Module | What it checks |
| --- | --- |
| `vr_handshake_check` | valid/ready: valid held until ready, payload stable mid-transfer |
| `req_ack_check` | every request is acknowledged within a bound; no spurious ack |
| `onehot_check` | one-hot (or one-hot-zero) encoding on a bus |
| `fifo_safety_check` | no push-on-full, no pop-on-empty |
| `cdc_2ff_check` | two-flop synchronizer pipeline consistency |

## Using them

Bind a checker onto your DUT without touching the RTL:

```systemverilog
bind my_fifo fifo_safety_check u_fifo_chk (
  .clk   (clk),
  .rst_n (rst_n),
  .push  (wr_en),
  .pop   (rd_en),
  .full  (full),
  .empty (empty)
);
```

The assertions fire during simulation on any violation, and the same
properties can be reused as targets in a formal flow.

## Notes

The CDC checker is a lightweight structural aid, not a replacement for a
dedicated CDC signoff tool.

## What Rivoryxa delivers with this

These checkers are the public, generic end of our assertion work. On client cores we write design-specific SVA and immediate assertions for control FSMs, debug and single-step logic, interrupt delivery, CSR access, and bus handshakes (OBI on the CORE-V cores), and we prove them with SymbiYosys rather than only simulating them. Each assertion ships paired with a reachability cover, and each proof ships with its log.

See the [Rivoryxa profile](https://github.com/Rivoryxa-Technologies) for our full service list, or reach us on [LinkedIn](https://www.linkedin.com/company/rivoryxa-technologies/).
