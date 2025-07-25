
module MSKaes_128bits_AK
#
(
    parameter d = 2
)
(
    sh_state_in,
    sh_key_in,
    sh_state_out
);

// IOs

input [128*d-1:0] sh_state_in;

input [128*d-1:0] sh_key_in;

wire  [128*d-1:0] sh_postAK;

output [128*d-1:0] sh_state_out;

MSKxor #(.d(d), .count(128))
xor_add_AK(
    .ina(sh_state_in),
    .inb(sh_key_in),
    // .out(sh_postAK)
    .out(sh_state_out)
);

endmodule
