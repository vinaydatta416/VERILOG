module jk_ff_tb;

  reg clock;
  reg reset;
  reg j, k;
  wire q;

  jk_ff dut (
    .clk(clock),
    .rst(reset),
    .j(j),
    .k(k),
    .q(q)
  );

  initial begin
    clock = 0;
    forever #5 clock = ~clock;
  end

  covergroup cg_jk_ff @(posedge clock);
    coverpoint j {
      bins j_0 = {0};
      bins j_1 = {1};
    }

    coverpoint k {
      bins k_0 = {0};
      bins k_1 = {1};
    }

    coverpoint q {
      bins q_0 = {0};
      bins q_1 = {1};
    }

    cp_jk_combo : cross j, k {
      bins jk_00 = binsof(j) intersect {0} && binsof(k) intersect {0};
      bins jk_01 = binsof(j) intersect {0} && binsof(k) intersect {1};
      bins jk_10 = binsof(j) intersect {1} && binsof(k) intersect {0};
      bins jk_11 = binsof(j) intersect {1} && binsof(k) intersect {1};
    }

    cp_jkq : cross j, k, q;
  endgroup

  cg_jk_ff cov = new();

  class jk_input;
    rand bit j;
    rand bit k;

    constraint allow_all {
    }
  endclass

  jk_input in = new();

  initial begin
    $dumpfile("jk.vcd");
    $dumpvars(0, jk_ff_tb);
    $monitor("Time=%0t | clk=%b | rst=%b | j=%b | k=%b | q=%b", $time, clock, reset, j, k, q);
    reset = 0; j = 0; k = 0;
    #10 reset = 1;
    repeat (20) begin
      void'(in.randomize());
      j = in.j;
      k = in.k;
      #10;
    end
    $display("Functional Coverage = %0.2f%%", cov.get_coverage());
    $finish;
  end

  property no_change;
    @(posedge clock) disable iff(!reset)
    (!$past(j) && !$past(k)) |=> q == $past(q);
  endproperty

  property set;
    @(posedge clock) disable iff(!reset)
    ($past(j) && !$past(k)) |=> q;
  endproperty

  property resett;
    @(posedge clock) disable iff(!reset)
    (!$past(j) && $past(k)) |=> !q;
  endproperty

  property toggle;
    @(posedge clock) disable iff(!reset)
    ($past(j) && $past(k)) |=> q == ~$past(q);
  endproperty

  always @(posedge clock) begin
    if (reset) begin
      if (!$isunknown($past(j)) && !$isunknown($past(k))) begin
        if (!$past(j) && !$past(k)) begin
          if (q == $past(q)) $info("PASS: no_change");
          else $fatal("FAIL: no_change");
        end
        if ($past(j) && !$past(k)) begin
          if (q == 1) $info("PASS: set");
          else $fatal("FAIL: set");
        end
        if (!$past(j) && $past(k)) begin
          if (q == 0) $info("PASS: resett");
          else $fatal("FAIL: resett");
        end
        if ($past(j) && $past(k)) begin
          if (q == ~$past(q)) $info("PASS: toggle");
          else $fatal("FAIL: toggle");
        end
      end
    end
  end

endmodule

module jk_ff(input logic clk, rst, j, k, output logic q);
  always_ff @(posedge clk or negedge rst)
    if (!rst)
      q <= 0;
    else begin
      case ({j,k})
        2'b00: q <= q;
        2'b01: q <= 0;
        2'b10: q <= 1;
        2'b11: q <= ~q;
      endcase
    end
endmodule



//================================================================

module mux_tb;

  reg clk;
  reg [7:0] in;
  reg [2:0] sel;
  wire out;

  mux dut (
    .in(in),
    .sel(sel),
    .out(out)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  covergroup cg_mux @(posedge clk);
    coverpoint sel { bins sel_vals[] = {[0:7]}; }
    coverpoint in;
    cp_sel_in: cross sel, in;
  endgroup

  cg_mux cov = new();

  class mux_input;
    rand bit [7:0] in_data;
    rand bit [2:0] sel_data;
  endclass

  mux_input minput = new();

  initial begin
    $dumpfile("mux.vcd");
    $dumpvars(0, mux_tb);
    $display("Time\tclk\tin\t\t sel\tout\texpected");

    repeat (20) begin
      void'(minput.randomize());
      in = minput.in_data;
      sel = minput.sel_data;
      #1;
      $display("%0t\t%b\t%b\t%0d\t%b\t%b", $time, clk, in, sel, out, in[sel]);
      if (out !== in[sel])
        $display("Assertion FAIL at time %0t: out=%b expected=%b", $time, out, in[sel]);
      else
        $display("Assertion PASS at time %0t: out=%b matches expected=%b", $time, out, in[sel]);
      #9;
    end

    $display("Functional Coverage = %0.2f%%", cov.get_coverage());
    $finish;
  end

endmodule


module mux(in,sel,out);
  input [7:0] in;
  input [2:0] sel;
  output reg out;

  always @(*) begin
    case (sel)
      3'b000: out = in[0];
      3'b001: out = in[1];
      3'b010: out = in[2];
      3'b011: out = in[3];
      3'b100: out = in[4];
      3'b101: out = in[5];
      3'b110: out = in[6];
      3'b111: out = in[7];
      default: out = 0;
    endcase
  end
endmodule
