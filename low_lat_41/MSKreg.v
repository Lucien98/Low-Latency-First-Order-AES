// SPDX-FileCopyrightText: SIMPLE-Crypto Contributors <info@simple-crypto.dev>
// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright SIMPLE-Crypto Contributors.
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
// You may redistribute and modify this source and make products using it under
// the terms of the CERN-OHL-P v2 (https://ohwr.org/cern_ohl_p_v2.txt).
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
// OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE.
// Please see the CERN-OHL-P v2 for applicable conditions.

// Masked register.
`ifdef FULLVERIF

`endif
`ifndef DEFAULTSHARES
`define DEFAULTSHARES 2
`endif
module MSKreg #(parameter d=`DEFAULTSHARES, parameter count=1) (clk, in, out);

   input clk;
 input  [count*d-1:0] in;
 output [count*d-1:0] out;

reg [count*d-1:0] state;

always @(posedge clk)
    state <= in;

assign out = state;

endmodule
