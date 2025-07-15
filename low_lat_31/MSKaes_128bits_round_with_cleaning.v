
module MSKaes_128bits_round_with_cleaning
#
(
    parameter d = 2,
    parameter LATENCY = 4
)
(
    clk,
    sh_state_in,
    sh_key_in,
    sh_RCON,
    sh_state_out,
    sh_key_out,
    sh_state_SR_out,
    // sh_state_AK_out,
    RandomZw,
    RandomBw,
    cleaning_on
);

`include "design.vh"

// Ports
input clk;
input [128*d-1:0] sh_state_in;
input [80*d-1:0] sh_key_in;
input [8*d-1:0] sh_RCON;
output [128*d-1:0] sh_state_out;
output [80*d-1:0] sh_key_out;
output [128*d-1:0] sh_state_SR_out;
// output [128*d-1:0] sh_state_AK_out;

input [20*rnd_busz-1:0] RandomZw;

input [20*rnd_busb-1:0] RandomBw;

input cleaning_on;

// Constant 0
wire [80*d-1:0] sh_zero;

MSKcst #(.d(d), .count(80))
cst_sh_zero(
    .cst(80'h0),
    .out(sh_zero)
);

// KS logic
wire [80*d-1:0] sh_key_in_cleaned;
MSKmux #(.d(d), .count(80))
mux_clean_key(
    .sel(cleaning_on),
    .in_true(sh_zero),
    .in_false(sh_key_in),
    .out(sh_key_in_cleaned)
);


MSKaes_128bits_KS_round #(.d(d/2), .LATENCY(LATENCY))
KS_mod(
    .clk(clk),
    .sh_key_in(sh_key_in_cleaned),
    .sh_key_out(sh_key_out),
    .sh_RCON_in(sh_RCON),
    .RandomZw(RandomZw[0 +: 4*rnd_busz]),
    .RandomBw(RandomBw[0 +: 4*rnd_busb])
);


wire [128*d-1:0] sh_postSB; 
MSKaes_128bits_SB #(.d(d))
SB_unit(
    .clk(clk),
    .sh_state_in(sh_state_in/*sh_postAK_cleaned*/),
    .sh_state_out(sh_postSB),
    .RandomZw(RandomZw[4*rnd_busz +: 16*rnd_busz]),
    .RandomBw(RandomBw[4*rnd_busb +: 16*rnd_busb])
);

// SR 
wire [128*d-1:0] sh_postSR;
MSKaes_128bits_SR #(.d(d))
SR_unit(
    .sh_state_in(sh_postSB),
    .sh_state_out(sh_postSR)
);

// MC
MSKaes_128bits_MC #(.d(d))
MC_unit(
    .sh_state_in(sh_postSR),
    .sh_state_out(sh_state_out)
);

assign sh_state_SR_out = sh_postSR;
// assign sh_state_AK_out = sh_postAK;

endmodule
