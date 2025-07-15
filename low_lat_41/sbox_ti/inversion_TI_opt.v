/* -----------------------------------------------------------------------------------------
  Masked AES hardware macro based on 2-share threshold implementation

  This module was extracted and modified from AES_TI_core.v
  Original file name : AES_TI_core.v
  Original version   : 2.1
  Original author    : Rei Ueno
  Original date      : December 1, 2016
  Last update        : October 4, 2021
  Original copyright : (C) 2021 Tohoku University

  Modified module    : inversion_TI
  New file name      : inversion_TI_opt.v
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
module inversion_TI_opt (in0, in1, out0, out1, out2, out3, r, CLK);
  input [7:0] in0, in1;
  output [7:0] out0, out1, out2, out3;
  input [27:0] r;
  input CLK;
  reg [3:0] s0reg, s1reg, s2reg, s3reg, i0reg, i1reg, i2reg, i3reg, i4reg, i5reg, i6reg, i7reg,
            h00reg, h01reg, h10reg, h11reg, l00reg, l01reg, l10reg, l11reg;

  wire [3:0] s0, s1, s2, s3;
  GF16_sqscmul_wc_comb S1 (.in00(in0[3:0]), .in01(in1[3:0]), .in10(in0[7:4]), .in11(in1[7:4]),
             .out0(s0), .out1(s1), .out2(s2), .out3(s3), .r0(r[3:0]), .r1(r[27:24]));

  wire [3:0] i0, i1, i2, i3, i4, i5, i6, i7;
  GF16_inv_comb S2 (.in0(s0reg), .in1(s1reg), .in2(s2reg), .in3(s3reg),
             .out0(i0), .out1(i1), .out2(i2), .out3(i3), .out4(i4), .out5(i5), .out6(i6), .out7(i7),
             .r0(r[7:4]), .r1(r[11:8]), .r2(r[15:12]));

  wire [3:0] t0, t1, t2, t3, u0, u1, u2, u3;
  GF16_muls_wc_comb S3 (.inh0(h10reg), .inh1(h11reg), .inl0(l10reg), .inl1(l11reg),
             .in0(i0reg), .in1(i1reg), .in2(i2reg), .in3(i3reg),
             .in4(i4reg), .in5(i5reg), .in6(i6reg), .in7(i7reg),
             .out0(out0[7:4]), .out1(out1[7:4]), .out2(out2[7:4]), .out3(out3[7:4]),
             .out4(out0[3:0]), .out5(out1[3:0]), .out6(out2[3:0]), .out7(out3[3:0]),
             .r0(r[19:16]), .r1(r[23:20]));

  always @(posedge CLK) begin
    s0reg <= s0; s1reg <= s1; s2reg <= s2; s3reg <= s3;
    i0reg <= i0; i1reg <= i1; i2reg <= i2; i3reg <= i3; i4reg <= i4; i5reg <= i5; i6reg <= i6; i7reg <= i7;
    h00reg <= in0[7:4]; h01reg <= in1[7:4]; l00reg <= in0[3:0]; l01reg <= in1[3:0];
    h10reg <= h00reg; h11reg <= h01reg; l10reg <= l00reg; l11reg <= l01reg;
  end
endmodule // Sbox_TI
