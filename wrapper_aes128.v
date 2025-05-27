
/*
    CAUTION:
    this module is only inteded to evaluate the cost of the MSK128_bits togheter with a PRNG

*/ 

// Masked AES implementation using HPC masking scheme and 128-bit
// architecture.
`ifndef DEFAULTSHARES
`define DEFAULTSHARES 4
`endif
`ifndef DEFAULTLATENCY
`define DEFAULTLATENCY 2
`endif

module wrapper_aes128
#
(
    parameter d = `DEFAULTSHARES,
    parameter PRNG_MAX_UNROLL = 512,
    parameter LATENCY = `DEFAULTLATENCY
)
(
    // Global
    nrst,
    clk,
    valid_in,
    ready,
    cipher_valid,
    // Data
    sh_plaintext,
    sh_key,
    sh_ciphertext,
    // PRNG interface
    prng_seed,
    prng_start_reseed,
    prng_out_ready,
    prng_out_valid,
    prng_busy
);

`include "design.vh"

//// IOs
// AES
input nrst;
input clk;
input valid_in;
output ready;
output cipher_valid;
input [128*d/2-1:0] sh_plaintext;
input [128*d/2-1:0] sh_key;
output [128*d/2-1:0] sh_ciphertext;
// PRNG
input [79:0] prng_seed;
input prng_start_reseed;
input prng_out_ready;
output prng_out_valid;
output prng_busy;


wire [20*rnd_busz-1:0] RandomZw;
wire [20*rnd_busb-1:0] RandomBw;

// Inner AES core
MSKaes_128bits_round_based
`ifndef CORE_SYNTHESIZED
#(
    .d(d),
    .LATENCY(LATENCY)
)
`endif
aes_core(
    .nrst(nrst),
    .clk(clk),
    .valid_in(valid_in),
    .ready(ready),
    .cipher_valid(cipher_valid),
    .sh_plaintext(sh_plaintext),
    .sh_key(sh_key),
    .sh_ciphertext(sh_ciphertext),
    .RandomZw(RandomZw),
    .RandomBw(RandomBw)
);

/* =========== PRNG =========== */
localparam NINIT=4*288;
localparam RND_AM = 20*(rnd_busz + rnd_busb);
wire [RND_AM-1:0] rnd; 

prng_top #(.RND(RND_AM),.NINIT(NINIT),.MAX_UNROLL(PRNG_MAX_UNROLL))
prng_unit(
    .rst(~nrst),
    .clk(clk),
    .seed(prng_seed),
    .start_reseed(prng_start_reseed),
    .out_ready(prng_out_ready),
    .out_valid(prng_out_valid),
    .out_rnd(rnd),
    .busy(prng_busy)
);

assign RandomZw = rnd[0 +: 20*rnd_busz];
assign RandomBw = rnd[20*rnd_busz +: 20*rnd_busb];

endmodule
