
module MSKaes_128bits_SB
#
(
    parameter d = 2
)
(
    // Global
    clk,
    // nrst,
    // Values
    sh_state_in,
    sh_state_out,
    // Randomness
    RandomZw,
    RandomBw
);

`include "design.vh"

// IOs
input clk;
// input nrst;

input [128*d-1:0] sh_state_in;
output [128*d-1:0] sh_state_out;

input [16*rnd_busz-1:0] RandomZw;

input [16*rnd_busb-1:0] RandomBw;
// Byte matrix representation
//(*mark_debug="true"*)
wire [8*d-1:0] sh_byte_in [15:0];
//(*mark_debug="true"*)
wire [8*d-1:0] sh_byte_out [15:0];

//(*mark_debug="true"*)
wire [7:0] umsk_byte_in[15:0];
//(*mark_debug="true"*)
wire [7:0] umsk_byte_out[15:0];


genvar i;
genvar j;
generate
for(i=0;i<16;i=i+1) begin: umsk_byte
    for (j = 0; j < 8; j=j+1) begin
        assign umsk_byte_in[i][j] = ^sh_byte_in[i][j*d +: d];
        assign umsk_byte_out[i][j] = ^sh_byte_out[i][j*d +: d];
    end
end
endgenerate
generate
for(i=0;i<16;i=i+1) begin: byte_in
    assign sh_byte_in[i] = sh_state_in[8*d*i +: 8*d];
end
endgenerate

// Create the SBOX
generate
for(i=0;i<16;i=i+1) begin: sbox_isnt
    aes_sbox_dom #(.d(d))
    sbox_unit(
        .clk(clk),
        .sboxIn(sh_byte_in[i]),
        .RandomZw(RandomZw[i*rnd_busz +: rnd_busz]),
        .RandomBw(RandomBw[i*rnd_busb +: rnd_busb]),
        .sboxOut(sh_byte_out[i])
    );
end
endgenerate
// Assign output

generate
for(i=0;i<16;i=i+1) begin: byte_out
    assign sh_state_out[8*d*i +: 8*d] = sh_byte_out[i];
end
endgenerate



endmodule
