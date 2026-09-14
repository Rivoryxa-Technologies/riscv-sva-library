# riscv-sva-library

Reusable SystemVerilog Assertion (SVA) checkers for RTL and SoC verification.

These are checker modules you `bind` into a design (or instantiate in a
testbench) to catch protocol and structural bugs early, without rewriting the
same properties for every block. This repository currently demonstrates lint only. Simulation and formal use
require a compatible frontend, a DUT, and tests that show each checker can fail.

> **Verified:** lints clean under Verilator (`verilator --lint-only -sv`).

## Checkers

| Module | What it checks |
| --- | --- |
| `vr_handshake_check` | valid/ready: valid held until ready, payload stable mid transfer |
| `req_ack_check` | every request is acknowledged within a bound; no spurious ack |
| `onehot_check` | one hot (or one hot zero) encoding on a bus |
| `fifo_safety_check` | no push when full, no pop when empty |
| `cdc_2ff_check` | two flop synchronizer pipeline consistency |

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

Enable assertion checking in a compatible simulator and validate each checker
with passing and deliberately violating stimulus before relying on it. Plain
Yosys does not support all temporal SVA syntax used here. No executable
simulation or formal regression is provided in this repository.

## Notes

The CDC checker is a lightweight structural aid, not a replacement for a
dedicated CDC signoff tool.

## What Rivoryxa delivers with this

These checkers are the public, generic end of our assertion work. On client cores we write design specific SVA and immediate assertions for control FSMs, debug and single step logic, interrupt delivery, CSR access, and bus handshakes, and we prove them with SymbiYosys rather than only simulating them. Each assertion ships paired with a reachability cover, and each proof ships with its log.

See the [Rivoryxa profile](https://github.com/Rivoryxa-Technologies) for our full service list, or reach us on [LinkedIn](https://www.linkedin.com/company/rivoryxa-technologies/).

## Rechecked scope, 15 September 2026

`verilator --lint-only --assert -sv -Wno-MULTITOP rtl_assertions.sv` exits zero
with Verilator 5.050 on macOS arm64. `-Wno-MULTITOP` permits the intentional
collection of independent checker modules. This is lint, not proof that any
assertion detects a defect. No runtime or unbounded proof is claimed.

The request/ack checker assumes `req` remains high until `ack`: its no-spurious
ack property is `ack |-> req`, not an outstanding-request scoreboard. The FIFO
checker forbids requests while full/empty; do not bind it unchanged to an
interface whose contract permits and rejects such requests. The CDC checker
checks sampled pipeline behavior, not physical synchronizer implementation.
