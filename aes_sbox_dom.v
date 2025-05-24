module aes_sbox_dom
#
(
    parameter d=2
)
(
    clk,
    sboxIn,
    RandomZw,
    RandomBw,
    sboxOut
);

`include "design.vh"

    input clk;
    input [8*d-1:0] sboxIn;
    input [rnd_busz-1:0] RandomZw;

    input [rnd_busb-1:0] RandomBw;
    output [8*d-1:0] sboxOut;

    wire [8*d-1 : 0] _XxDI;
    wire [8*d-1 : 0] _QxDO;

    genvar j;
    genvar i;
    for (j= 0; j < 8; j=j+1) begin
	    for (i = 0; i < d; i=i+1) begin
            assign _XxDI[i*8+j] = sboxIn[j*d+i];
            assign sboxOut[j*d+i] = _QxDO[i*8+j];
        end
    end
    // wire [7:0] out;
    // assign out = _QxDO[15:8] ^ _QxDO[7:0];

    // wire [7:0] in;
    // assign in = _XxDI[15:8] ^ _XxDI[7:0];

    aes_sbox #(.PIPELINED(1), .SHARES(d))
    inst_aes_box (
        .ClkxCI(clk),
        ._XxDI(_XxDI),
        .RandomZ(RandomZw),
        .RandomB(RandomBw),
        ._QxDO(_QxDO)
    );
endmodule
