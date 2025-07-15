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
module Stage2_opt (in0, in1, out0, out1, ih0, ih1, il0, il1, h0, h1, l0, l1,
               r0, r1, r2, CLK);
  input [3:0] in0, in1, ih0, ih1, il0, il1;
  output [3:0] out0, out1, h0, h1, l0, l1;
  input [3:0] r0, r1, r2;
  input CLK;

  GF16_inv inv (.in0(in0), .in1(in1),
             .out0(out0), .out1(out1),
             .r0(r0), .r1(r1), .r2(r2), .CLK(CLK));

  // pipeline registers
  reg [3:0] h0reg, h1reg, l0reg, l1reg;
  always @(posedge CLK) begin
    h1reg <= ih1; h0reg <= ih0; l1reg <= il1; l0reg <= il0;
  end

  assign h1 = h1reg;
  assign h0 = h0reg;
  assign l1 = l1reg;
  assign l0 = l0reg;

endmodule // Stage2
