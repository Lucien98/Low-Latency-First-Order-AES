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
module Stage3_opt (inh0, inh1, inl0, inl1, in0, in1,
               out0, out1, r0, r1, CLK);
  input [3:0] inh0, inh1, inl0, inl1, in0, in1;
  // output [3:0] out00, out01, out10, out11;
  output [7:0] out0, out1;
  input [3:0] r0, r1;
  input CLK;

  GF16_muls muls (.inh0(inh0), .inh1(inh1), .inl0(inl0), .inl1(inl1),
             .in0(in0), .in1(in1),
             .out00(out0[3:0]), .out01(out1[3:0]), .out10(out0[7:4]), .out11(out1[7:4]),
             .r0(r0), .r1(r1), .CLK(CLK));

endmodule // Stage3_opt
