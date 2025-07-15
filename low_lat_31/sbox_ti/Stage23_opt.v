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
module Stage23_opt (in0, in1, h0, h1, l0, l1, out0, out1, r, CLK);
  input [3:0] in0, in1, h0, h1, l0, l1;
  output [7:0] out0, out1;
  input [19:0] r;
  input CLK;

  wire [3:0] h0_1, h1_1, l0_1, l1_1;

  wire [3:0] i0, i1;

  Stage2_opt S2 (.in0(in0), .in1(in1), .ih0(h0), .ih1(h1), .il0(l0), .il1(l1),
             .out0(i0), .out1(i1), .h0(h0_1), .h1(h1_1), .l0(l0_1), .l1(l1_1),
             .r0(r[3:0]), .r1(r[7:4]), .r2(r[11:8]), .CLK(CLK));

  Stage3_opt S3 (.inh0(h0_1), .inh1(h1_1), .inl0(l0_1), .inl1(l1_1),
             .in0(i0), .in1(i1),
             .out0(out0), .out1(out1),
             .r0(r[15:12]), .r1(r[19:16]), .CLK(CLK));

endmodule // Sbox_TI
