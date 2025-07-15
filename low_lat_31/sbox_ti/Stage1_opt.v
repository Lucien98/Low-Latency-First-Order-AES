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
module Stage1_opt (in00, in01, in10, in11, out0, out1, h0, h1, l0, l1, r0, r1, CLK);
  input [3:0] in00, in01, in10, in11; // in0 = in00 + in01, in1 = in10 + in11
  output [3:0] out0, out1, h0, h1, l0, l1;
  input [3:0] r0, r1; // fresh masks
  input CLK;

  GF16_sqscmul sqscmul (.in00(in00), .in01(in01), .in10(in10), .in11(in11),
             .out0(out0), .out1(out1), .r0(r0), .r1(r1), .CLK(CLK));

  // pipeline registers
  reg [3:0] h0reg, h1reg, l0reg, l1reg;
  always @(posedge CLK) begin
    h1reg <= in11; h0reg <= in10; l1reg <= in01; l0reg <= in00;
  end

  assign h1 = h1reg;
  assign h0 = h0reg;
  assign l1 = l1reg;
  assign l0 = l0reg;
endmodule // Stage1
