/* -----------------------------------------------------------------------------------------
  Masked AES hardware macro based on 2-share threshold implementation

  This module was extracted and modified from AES_TI_core.v
  Original file name : AES_TI_core.v
  Original version   : 2.1
  Original author    : Rei Ueno
  Original date      : December 1, 2016
  Last update        : October 4, 2021
  Original copyright : (C) 2021 Tohoku University

  Modified module    : Stage1
  New file name      : GF16_sqscmul_wc_comb.v
  Modifications      : 1. Rename the module; 2. Reduce the number of required random bits; 3. Add correction terms taken from AESTIScheme <https://github.com/GitHub-lancel/AESTIScheme>.
  Modified by        : Feng Zhou
  Modification date  : June 4, 2025

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
module GF16_sqscmul_wc_comb (in00, in01, in10, in11, out0, out1, out2, out3, r0, r1);
  input [3:0] in00, in01, in10, in11; // in0 = in00 + in01, in1 = in10 + in11
  output [3:0] out0, out1, out2, out3;
  input [3:0] r0, r1; // fresh masks
  wire [3:0] p0, p1, p2, p3;
  wire a0,b0,c0,d0,e0,f0,g0,h0;
  wire a1,b1,c1,d1,e1,f1,g1,h1;
  wire [3:0] ct0, ct1, ct2, ct3;

  assign {h0, g0, f0, e0} = in10;
  assign {h1, g1, f1, e1} = in11;
  assign {d0, c0, b0, a0} = in00;
  assign {d1, c1, b1, a1} = in01;

  wire s_a0b0 = a0 ^ b0;
  wire s_a1b1 = a1 ^ b1;
  wire s_g1h1 = g1 ^ h1;

  assign ct0 = {b0, a0, d0, 1'b0};
  // assign c1 = {a0^b0^c0^h1, a0^b0^d0^g1, a0^b0^d0^f1, a0^e1};
  // assign c2 = {a1^b1^c1^e0^g0, a1^b1^d1^f0^h0, a1^b1^e0^f0, d1^e0};
  // assign c3 = {b1^e1^g1^h1, a1^f1^g1^h1, e1, a1^d1};
  assign ct1 = {s_a0b0^c0^h1, s_a0b0^d0^g1, s_a0b0^d0^f1, a0^e1};
  assign ct2 = {s_a1b1^c1^e0^g0, s_a1b1^d1^f0^h0, s_a1b1^e0^f0, d1^e0};
  assign ct3 = {b1^e1^s_g1h1, a1^f1^s_g1h1, e1, a1^d1};

  gf24mul mul0 (.in0(in00), .in1(in10), .out0(p0));
  gf24mul mul1 (.in0(in00), .in1(in11), .out0(p1));
  gf24mul mul2 (.in0(in01), .in1(in10), .out0(p2));
  gf24mul mul3 (.in0(in01), .in1(in11), .out0(p3));

  // SqSc SqSc0 (.in0(in00^in10), .out0(s0));
  // SqSc SqSc1 (.in0(in01^in11), .out0(s1));

  assign out0 = p0 ^ r0 ^ ct0 ^ r1;
  assign out1 = p1 ^ r0 ^ ct1;
  assign out2 = p2 ^ r0 ^ ct2;
  assign out3 = p3 ^ r0 ^ ct3 ^ r1;
endmodule // Stage1
