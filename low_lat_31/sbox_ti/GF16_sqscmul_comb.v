/* -----------------------------------------------------------------------------------------
  Masked AES hardware macro based on 2-share threshold implementation

  This module was extracted and modified from AES_TI_core.v
  Original file name : AES_TI_core.v
  Original version   : 2.1
  Original author    : Rei Ueno
  Original date      : December 1, 2016
  Last update        : October 4, 2021
  Original copyright : (C) 2021 Tohoku University

  Modified module    : Stage2
  New file name      : GF16_inv_comb.v
  Modifications      : 1. Rename the module; 2. Reduce the number of required random bits
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
module GF16_sqscmul_comb (in00, in01, in10, in11, out0, out1, out2, out3, r0, r1);
  input [3:0] in00, in01, in10, in11; // in0 = in00 + in01, in1 = in10 + in11
  output wire [3:0] out0, out1, out2, out3;
  input [3:0] r0, r1; // fresh masks
  wire [3:0] p0, p1, p2, p3, s0, s1;

  gf24mul mul0 (.in0(in00), .in1(in10), .out0(p0));
  gf24mul mul1 (.in0(in00), .in1(in11), .out0(p1));
  gf24mul mul2 (.in0(in01), .in1(in10), .out0(p2));
  gf24mul mul3 (.in0(in01), .in1(in11), .out0(p3));

  SqSc SqSc0 (.in0(in00^in10), .out0(s0));
  SqSc SqSc1 (.in0(in01^in11), .out0(s1));

  assign out0 = p0 ^ r0 ^ s0;
  assign out1 = p1 ^ r0 ^ r1;
  assign out2 = p2 ^ r0 ^ r1;
  assign out3 = p3 ^ r0 ^ s1;
endmodule // GF16_sqscmul_comb
