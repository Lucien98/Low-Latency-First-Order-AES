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
`timescale 1ns/1ps
module tb_inversion_twostage ();
    localparam T=2.0;
	localparam Td = T/2.0;

    // General signals
	reg CLK;

    reg [7:0] in0, in1;
    wire [7:0] out0, out1, out2, out3;
    reg [63:0] r;
    wire [7:0] X = in0 ^ in1;
    wire [7:0] Q = out0 ^ out1 ^ out2 ^ out3;

    two_stage_inversion_TI inv(
    	.in0 (in0),
    	.in1 (in1),
    	.out0(out0),
    	.out1(out1),
    	.out2(out2),
    	.out3(out3),
    	.r   (r),
    	.CLK (CLK)
    );

    // Create clock
	always@(*) #Td CLK<=~CLK;

	initial begin
        CLK = 0;
        in0 = 0;
        in1 = 0;
		#T;
        
        for (integer i = 0; i < 256; i = i + 1) begin
            in1 = i;
            for (integer j = 0; j < 256; j = j + 1) begin
                in0 = j;
                r = $random;
                #T;
            end
        end
        #T;
        
    end


endmodule