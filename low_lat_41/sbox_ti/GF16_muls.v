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
module GF16_muls (inh0, inh1, inl0, inl1, in0, in1,
               out00, out01, out10, out11, r0, r1, CLK);
  input [3:0] inh0, inh1, inl0, inl1,
              in0, in1;
  output [3:0] out00, out01, out10, out11; // out0 ^ out1, out
  input [3:0] r0, r1;
  input CLK;
  wire [3:0] s0, s1, s2, s3, s4, s5, s6, s7;
  GF16_muls_wc_comb comb (.inh0(inh0), .inh1(inh1), .inl0(inl0), .inl1(inl1),
             .in0(in0), .in1(in1),
             .out0(s0), .out1(s1), .out2(s2), .out3(s3),
             .out4(s4), .out5(s5), .out6(s6), .out7(s7),
             .r0(r0), .r1(r1));

  reg [3:0] s0reg, s1reg, s2reg, s3reg, s4reg, s5reg, s6reg, s7reg;

  always @(posedge CLK) begin
    s0reg <= s0; s1reg <= s1; s2reg <= s2; s3reg <= s3;
    s4reg <= s4; s5reg <= s5; s6reg <= s6; s7reg <= s7;
  end

  // Compression layer
  assign out00 = s0reg ^ s1reg;
  assign out01 = s2reg ^ s3reg;
  assign out10 = s4reg ^ s5reg;
  assign out11 = s6reg ^ s7reg;


endmodule // GF16_muls
