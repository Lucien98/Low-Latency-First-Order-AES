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
module GF16_inv (in0, in1,
               out0, out1,
               r0, r1, r2, CLK);
  input [3:0] in0, in1;
  output [3:0] out0, out1;
  input [3:0] r0, r1, r2;
  input CLK;

  wire [3:0] i0, i1, i2, i3, i4, i5, i6, i7;
  GF16_inv_comb comb (.in0(in0), .in1(in1),
             .out0(i0), .out1(i1), .out2(i2), .out3(i3), .out4(i4), .out5(i5), .out6(i6), .out7(i7),
             .r0(r0), .r1(r1), .r2(r2));

  reg [3:0] i0reg, i1reg, i2reg, i3reg, i4reg, i5reg, i6reg, i7reg;
  
  always @(posedge CLK) begin
    i0reg <= i0; i1reg <= i1; i2reg <= i2; i3reg <= i3;
    i4reg <= i4; i5reg <= i5; i6reg <= i6; i7reg <= i7;
  end

  assign out0 = i0reg ^ i2reg ^ i4reg ^ i6reg;
  assign out1 = i1reg ^ i3reg ^ i5reg ^ i7reg;
  

endmodule // Stage2
