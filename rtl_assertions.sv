// rtl_assertions.sv
// Reusable SystemVerilog Assertion (SVA) checkers for RTL verification.
// Bind these into a DUT, or instantiate them directly in a testbench.
//
// Rivoryxa Technologies

// ---------------------------------------------------------------------------
// valid/ready handshake: once valid is asserted it must stay asserted, and the
// payload must stay stable, until ready is seen. Catches premature de-assert
// and mid-transfer data changes.
// ---------------------------------------------------------------------------
module vr_handshake_check #(
  parameter int WIDTH = 32
)(
  input logic             clk,
  input logic             rst_n,
  input logic             valid,
  input logic             ready,
  input logic [WIDTH-1:0] data
);
  // valid must remain high until the cycle ready is high
  property p_valid_stable;
    @(posedge clk) disable iff (!rst_n)
      (valid && !ready) |=> valid;
  endproperty
  a_valid_stable: assert property (p_valid_stable)
    else $error("VR: valid deasserted before ready");

  // data must be stable while valid is high and not yet accepted
  property p_data_stable;
    @(posedge clk) disable iff (!rst_n)
      (valid && !ready) |=> $stable(data);
  endproperty
  a_data_stable: assert property (p_data_stable)
    else $error("VR: data changed before handshake completed");
endmodule

// ---------------------------------------------------------------------------
// request/acknowledge: every req must eventually get an ack within a bound,
// and ack only appears in response to an outstanding req.
// ---------------------------------------------------------------------------
module req_ack_check #(
  parameter int MAX_LATENCY = 32
)(
  input logic clk,
  input logic rst_n,
  input logic req,
  input logic ack
);
  property p_req_gets_ack;
    @(posedge clk) disable iff (!rst_n)
      $rose(req) |-> ##[1:MAX_LATENCY] ack;
  endproperty
  a_req_gets_ack: assert property (p_req_gets_ack)
    else $error("REQACK: req not acknowledged within MAX_LATENCY");

  property p_no_spurious_ack;
    @(posedge clk) disable iff (!rst_n)
      ack |-> req;
  endproperty
  a_no_spurious_ack: assert property (p_no_spurious_ack)
    else $error("REQACK: ack asserted without an outstanding req");
endmodule

// ---------------------------------------------------------------------------
// one-hot: signal must have exactly one bit set (optionally allow all-zero).
// ---------------------------------------------------------------------------
module onehot_check #(
  parameter int WIDTH      = 8,
  parameter bit ALLOW_ZERO = 1
)(
  input logic             clk,
  input logic             rst_n,
  input logic [WIDTH-1:0] sig
);
  property p_onehot;
    @(posedge clk) disable iff (!rst_n)
      ALLOW_ZERO ? $onehot0(sig) : $onehot(sig);
  endproperty
  a_onehot: assert property (p_onehot)
    else $error("ONEHOT: signal not one-hot: 0x%0h", sig);
endmodule

// ---------------------------------------------------------------------------
// FIFO safety: no push when full, no pop when empty.
// ---------------------------------------------------------------------------
module fifo_safety_check (
  input logic clk,
  input logic rst_n,
  input logic push,
  input logic pop,
  input logic full,
  input logic empty
);
  a_no_overflow: assert property (
    @(posedge clk) disable iff (!rst_n) !(push && full))
    else $error("FIFO: push while full (overflow)");

  a_no_underflow: assert property (
    @(posedge clk) disable iff (!rst_n) !(pop && empty))
    else $error("FIFO: pop while empty (underflow)");
endmodule

// ---------------------------------------------------------------------------
// CDC synchronizer: the second flop of a two-flop synchronizer must equal the
// previous value of the first flop. A lightweight structural check to use
// alongside a proper CDC signoff tool.
// ---------------------------------------------------------------------------
module cdc_2ff_check (
  input logic clk_dst,
  input logic rst_n,
  input logic sync_ff1,
  input logic sync_ff2
);
  property p_pipe;
    @(posedge clk_dst) disable iff (!rst_n)
      1'b1 |=> (sync_ff2 == $past(sync_ff1));
  endproperty
  a_pipe: assert property (p_pipe)
    else $error("CDC: two-flop synchronizer stage mismatch");
endmodule
