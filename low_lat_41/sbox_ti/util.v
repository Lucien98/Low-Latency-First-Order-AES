/* -----------------------------------------------------------------------------------------
  Masked AES hardware macro based on 2-share threshold implementation

  This module was extracted from AES_TI_core.v
  Original file name : AES_TI_core.v
  Original version   : 2.1
  Original author    : Rei Ueno
  Original date      : December 1, 2016
  Last update        : October 4, 2021
  Original copyright : (C) 2021 Tohoku University

  License and usage terms:

  This code is derived from the original work copyrighted by Tohoku University.

  Permission is hereby granted to copy, reproduce, redistribute or
  otherwise use this code as long as: there is no monetary profit gained
  specifically from the use or reproduction of this code, it is not sold,
  rented, traded or otherwise marketed, and this copyright notice is
  included prominently in any copy made.

  The original authors and copyright holders shall not be liable
  for any damages arising from the use of this code or its modifications.

  When you publish any results arising from the use of this code,
  please cite the original paper:

  Rei Ueno, Naofumi Homma, and Takafumi Aoki,
  "Towards More DPA-Resistant AES Hardware Architecture Based on Threshold Implementation,"
  In: Silvain Guilley (eds.) International Workshop on Constructive Side-Channel Analysis and Secure Design (COSADE),
  pp. 50--64, Lecture Note in Computer Science, Vol. 10348, Springer,
  doi: https://doi.org/10.1007/978-3-319-64647-3_4
----------------------------------------------------------------------------------------- */
module gf24mul_factoring (in0, in1, ff, f, h, l, out0);
  input [3:0] in0, in1;
  output [3:0] out0;
  input [1:0] ff;
  input f, h, l;
  wire [1:0] a0, a1, p0, p1, p2, b0;

  assign a1 = ff;
  assign a0 = in0[3:2] ^ in0[1:0];

  gf22mul_scl_factoring mulf0 (.in0(a0), .in1(a1), .f(f), .out0(p2));
  gf22mul_factoring mulf1 (.in0(in0[3:2]), .in1(in1[3:2]), .f(h), .out0(p1));
  gf22mul_factoring mulf2 (.in0(in0[1:0]), .in1(in1[1:0]), .f(l), .out0(p0));

  assign out0 = {p1^p2, p0^p2};
endmodule // gf24mul

module gf22mul_scl_factoring (in0, in1, f, out0);
  input [1:0] in0, in1;
  input f;
  output [1:0] out0;
  wire a0, a1, p0, p1, p2;

  assign {a1, a0} = {f, ^in0};
  assign {p2, p1, p0} = {~(a1&a0), ~(in1&in0)};
  assign out0 = {p2^p0, p1^p0};
endmodule // gf22mul

module gf22mul_factoring (in0, in1, f, out0);
  input [1:0] in0, in1;
  input f;
  output [1:0] out0;
  wire a0, a1, p0, p1, p2;

  assign {a1, a0} = {f, ^in0};
  assign {p2, p1, p0} = {~(a1&a0), ~(in1&in0)};
  assign out0 = {p2^p1, p2^p0};
endmodule // gf22mul


module SqSc (in0, out0);
  input [3:0] in0;
  output [3:0] out0;
  wire [1:0] a, a2, b;

  assign a = in0[3:2] ^ in0[1:0];
  assign a2 = {a[0], a[1]};
  assign b = {in0[1]^in0[0], in0[0]};
  assign out0 = {a2, b};
endmodule // SqSc

module gf24mul (in0, in1, out0);
  input [3:0] in0, in1;
  output [3:0] out0;
  wire [1:0] a0, a1, p0, p1, p2;

  assign a1 = in1[3:2] ^ in1[1:0];
  assign a0 = in0[3:2] ^ in0[1:0];

  gf22mul_scaling mul0 (.in0(a1), .in1(a0), .out0(p2));
  gf22mul mul1 (.in0(in0[3:2]), .in1(in1[3:2]), .out0(p1));
  gf22mul mul2 (.in0(in0[1:0]), .in1(in1[1:0]), .out0(p0));

  assign out0 = {p1^p2, p0^p2};
endmodule // gf24mul

module gf22mul_scaling (in0, in1, out0);
  input [1:0] in0, in1;
  output [1:0] out0;
  wire a0, a1, p0, p1, p2;

  assign {a1, a0} = {^in1, ^in0};
  assign {p2, p1, p0} = {~(a1&a0), ~(in1&in0)};
  assign out0 = {p2^p0, p1^p0};
endmodule // gf22mul

module gf22mul (in0, in1, out0);
  input [1:0] in0, in1;
  output [1:0] out0;
  wire a0, a1, p0, p1, p2;

  assign {a1, a0} = {^in1, ^in0};
  assign {p2, p1, p0} = {~(a1&a0), ~(in1&in0)};
  assign out0 = {p2^p1, p2^p0};
endmodule // gf22mul
