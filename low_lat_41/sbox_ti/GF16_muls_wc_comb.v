/* -----------------------------------------------------------------------------------------
  Masked AES hardware macro based on 2-share threshold implementation

  This module was extracted and modified from AES_TI_core.v
  Original file name : AES_TI_core.v
  Original version   : 2.1
  Original author    : Rei Ueno
  Original date      : December 1, 2016
  Last update        : October 4, 2021
  Original copyright : (C) 2021 Tohoku University

  Modified module    : Stage3
  New file name      : GF16_muls_wc_comb.v
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
module correction_term (in00, in01, in10, in11, ct0, ct1, ct2, ct3);
  input [3:0] in00, in01, in10, in11;
  output [3:0] ct0, ct1, ct2, ct3;
  wire a0,b0,c0,d0,e0,f0,g0,h0;
  wire a1,b1,c1,d1,e1,f1,g1,h1;
  assign {h0, g0, f0, e0} = in10;
  assign {h1, g1, f1, e1} = in11;
  assign {d0, c0, b0, a0} = in00;
  assign {d1, c1, b1, a1} = in01;

  // assign ct0 = {c0^d0^e0^h0, a0, b0, a0^b0};
  // assign ct1 = {c0^d0^f1^g1, a0^h1, b0^g1, a0^b0^f1};
  // assign ct2 = {c1^d1^e0^h0, a1, b1, a1^b1};
  // assign ct3 = {c1^d1^f1^g1, a1^h1, b1^g1, a1^b1^f1};
  assign ct0 = {g0^h0^a0^d0, e0, f0, e0^f0};
  assign ct1 = {g0^h0^b1^c1, e0^d1, f0^c1, e0^f0^b1};
  assign ct2 = {g1^h1^a0^d0, e1, f1, e1^f1};
  assign ct3 = {g1^h1^b1^c1, e1^d1, f1^c1, e1^f1^b1};

endmodule

module GF16_muls_wc_comb (inh0, inh1, inl0, inl1, in0, in1,
               out0, out1, out2, out3, out4, out5, out6, out7, r0, r1);
  input [3:0] inh0, inh1, inl0, inl1,
              in0, in1;
  output [3:0] out0, out1, out2, out3, out4, out5, out6, out7;
  input [3:0] r0, r1;
  wire [3:0] a0, a1, z0, z1, z2, z3, z4, z5, z6, z7;

  wire [3:0] c00, c01, c02, c03, c10, c11, c12, c13;

  // Compression
  assign a0 = in0;
  assign a1 = in1;

  correction_term cterm0(.in00(inl0), .in01(inl1), .in10(a0), .in11(a1), .ct0(c00), .ct1(c01), .ct2(c02), .ct3(c03));
  correction_term cterm1(.in00(inh0), .in01(inh1), .in10(a0), .in11(a1), .ct0(c10), .ct1(c11), .ct2(c12), .ct3(c13));

  wire [1:0] ff0, ff1;
  wire f0, f1, h0, l0, h1, l1;
  assign ff0 = a0[3:2] ^ a0[1:0];
  assign f0 = ^ff0;
  assign {h0, l0} = {a0[3]^a0[2], a0[1]^a0[0]};

  assign ff1 = a1[3:2] ^ a1[1:0];
  assign f1 = ^ff1;
  assign {h1, l1} = {a1[3]^a1[2], a1[1]^a1[0]};

  gf24mul_factoring mulf0 (.in0(inl0), .in1(a0), .ff(ff0), .f(f0), .h(h0), .l(l0), .out0(z0));
  gf24mul_factoring mulf1 (.in0(inl0), .in1(a1), .ff(ff1), .f(f1), .h(h1), .l(l1), .out0(z1));
  gf24mul_factoring mulf2 (.in0(inl1), .in1(a0), .ff(ff0), .f(f0), .h(h0), .l(l0), .out0(z2));
  gf24mul_factoring mulf3 (.in0(inl1), .in1(a1), .ff(ff1), .f(f1), .h(h1), .l(l1), .out0(z3));

  gf24mul_factoring mulf4 (.in0(inh0), .in1(a0), .ff(ff0), .f(f0), .h(h0), .l(l0), .out0(z4));
  gf24mul_factoring mulf5 (.in0(inh0), .in1(a1), .ff(ff1), .f(f1), .h(h1), .l(l1), .out0(z5));
  gf24mul_factoring mulf6 (.in0(inh1), .in1(a0), .ff(ff0), .f(f0), .h(h0), .l(l0), .out0(z6));
  gf24mul_factoring mulf7 (.in0(inh1), .in1(a1), .ff(ff1), .f(f1), .h(h1), .l(l1), .out0(z7));

  /*
   // not uniform
    assign out4 = z0 ^ inh0 ^ a0;
    assign out5 = z1 ^ inh0;
    assign out6 = z2 ^ inh0 ^ a0;
    assign out7 = z3 ^ inh0;

    assign out0 = z4 ^ inl0 ^ a0;
    assign out1 = z5 ^ inl0;
    assign out2 = z6 ^ inl0 ^ a0;
    assign out3 = z7 ^ inl0;
  */
  assign out4 = z0 ^ r0 ^ inl0;
  assign out5 = z2 ^ r0;
  assign out6 = z1 ^ r0 ^ inl0;
  assign out7 = z3 ^ r0;

  assign out0 = z4 ^ r1 ^ inh0;
  assign out1 = z6 ^ r1;
  assign out2 = z5 ^ r1 ^ inh0;
  assign out3 = z7 ^ r1;

  // assign out4 = z0 ^ inh0 ^ inl0;
  // assign out5 = z2 ^ inh0;
  // assign out6 = z1 ^ inh0 ^ inl0;
  // assign out7 = z3 ^ inh0;

  // assign out0 = z4 ^ inl0 ^ inh0;
  // assign out1 = z6 ^ inl0;
  // assign out2 = z5 ^ inl0 ^ inh0;
  // assign out3 = z7 ^ inl0;
endmodule // Stage3
