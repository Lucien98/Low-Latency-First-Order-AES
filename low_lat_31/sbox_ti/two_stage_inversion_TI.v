// 
// Copyright (C) 2025 Feng Zhou
// 
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
// 
module two_stage_inversion_TI (in0, in1, out0, out1, out2, out3, r, CLK);
  input [7:0] in0, in1;
  output [7:0] out0, out1, out2, out3;
  input [27:0] r;
  input CLK;

  wire [3:0] s0, s1, h0_0, h1_0, l0_0, l1_0;

  wire [3:0] h0_1, h1_1, l0_1, l1_1;

  wire [3:0] i0, i1;
  Stage1_opt S1 (.in00(in0[3:0]), .in01(in1[3:0]), .in10(in0[7:4]), .in11(in1[7:4]),
             .out0(s0), .out1(s1), .h0(h0_0), .h1(h1_0), .l0(l0_0), .l1(l1_0), .r0(r[3:0]), .r1(r[27:24]), .CLK(CLK));

  Stage2_opt S2 (.in0(s0), .in1(s1), .ih0(h0_0), .ih1(h1_0), .il0(l0_0), .il1(l1_0),
             .out0(i0), .out1(i1), .h0(h0_1), .h1(h1_1), .l0(l0_1), .l1(l1_1),
             .r0(r[7:4]), .r1(r[11:8]), .r2(r[15:12]), .CLK(CLK));

  GF16_muls_wc_comb comb (.inh0(h0_1), .inh1(h1_1), .inl0(l0_1), .inl1(l1_1),
             .in0(i0), .in1(i1),
             .out0(out0[3:0]), .out1(out1[3:0]), .out2(out2[3:0]), .out3(out3[3:0]),
             .out4(out0[7:4]), .out5(out1[7:4]), .out6(out2[7:4]), .out7(out3[7:4]),
             .r0(r[19:16]), .r1(r[23:20]));

endmodule // two_stage_inversion_TI
