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
module GF16_sqscmul (in00, in01, in10, in11, out0, out1, r0, r1, CLK);
  input [3:0] in00, in01, in10, in11; // in0 = in00 + in01, in1 = in10 + in11
  output [3:0] out0, out1;
  input [3:0] r0, r1; // fresh masks
  input CLK;

  wire [3:0] s0, s1, s2, s3;
  GF16_sqscmul_comb comb (.in00(in00), .in01(in01), .in10(in10), .in11(in11),
             .out0(s0), .out1(s1), .out2(s2), .out3(s3), .r0(r0), .r1(r1));

  // Sequential
  reg [3:0] s0reg, s1reg, s2reg, s3reg;
  always @(posedge CLK) begin
    s0reg <= s0; s1reg <= s1; s2reg <= s2; s3reg <= s3;
  end

  // Compression layer
  assign out0 = s0reg ^ s1reg;
  assign out1 = s2reg ^ s3reg;

endmodule // GF16_sqscmul
