
module MSKaes_128bits_KS_round
#
(
    parameter d = 2,
    parameter LATENCY = 4
)
(
    // Global
    clk,
    // Data
    sh_key_in,
    sh_key_out,
    sh_RCON_in, //expected to be valid at the last cycle of the round
    // Randomness
    RandomZw,
    RandomBw
);

`include "design.vh"

// IOs
input clk;

input [160*d-1:0] sh_key_in;
output [160*d-1:0] sh_key_out;
input [8*d-1:0] sh_RCON_in;

input [4*rnd_busz-1:0] RandomZw;

input [4*rnd_busb-1:0] RandomBw;

// wire [128*d-1:0] sh_key_in_comp;

genvar i;
genvar j;
genvar k;

wire [160*d-1:0] sh_key_in_back;
assign sh_key_in_back[96*d-1:0] = sh_key_in[96*d-1:0];
MSKlin_map #(.d(d), .count(8), .matrix_sel(3))
lin_map_key(
    .sh_state_in(sh_key_in[12*8*d +: 8*8*d]),
    .sh_state_out(sh_key_in_back[12*8*d +: 8*8*d])
    );

wire [128*d-1:0] sh_key_back;

assign sh_key_back[  0+:64] = sh_key_in_back[  0+:64] ^ sh_key_in_back[256+:64];
assign sh_key_back[ 64+:64] = sh_key_in_back[ 64+:64] ^ sh_key_in_back[256+:64];
assign sh_key_back[128+:64] = sh_key_in_back[128+:64] ^ sh_key_in_back[256+:64];
assign sh_key_back[192+:64] = sh_key_in_back[192+:64] ^ sh_key_in_back[256+:64];

// todo: comment
wire [127:0] rec_key;
generate
for(i=0;i<128;i=i+1) begin: bit_c
    assign rec_key[i] = ^sh_key_back[d*i +: d];
end
endgenerate


wire [128*d-1:0] shblk_key_in;

shbit2shblk #(.d(d),.width(128))
switch_encoding_kin(
    .shbit(sh_key_back),
    .shblk(shblk_key_in)
);

wire [8*d*2-1:0] sh_lcol_SB [3:0];

// Byte matrix representation
wire [8*d-1:0] sh_byte_in [15:0];
wire [8*d-1:0] sh_byte_out [15:0];
generate
for(i=0;i<16;i=i+1) begin: kbyte_in
    assign sh_byte_in[i] = sh_key_back[8*d*i +: 8*d];
    assign sh_key_out[8*d*i +: 8*d] = sh_byte_out[i];
end
endgenerate

assign sh_key_out[128*d +: 32*d] = {sh_lcol_SB[0][16+:16], sh_lcol_SB[3][16+:16],sh_lcol_SB[2][16+:16],sh_lcol_SB[1][16+:16]};

wire [8*d*2-1:0] byte_in[3:0];
wire [8*d*2-1:0] byte_out[3:0];

// todo: comment
/*
wire [7:0] rec_byte_in[3:0];
wire [7:0] rec_byte_out[3:0];

generate
for(i=0;i<8;i=i+1) begin: rec_bit
    for (j = 0; j < 4; j=j+1) begin: rec_byte
        assign rec_byte_in[j][i] = (^sh_key_in[(12+j)*d*8+d*i +: d]) ^ (^sh_key_in[(16+j)*d*8+d*i +: d]);
        assign rec_byte_out[j][i] = (^sh_lcol_SB[j][2*i +: d]) ^ (^sh_lcol_SB[j][16 + 2*i +: d]) ;
    end
end
endgenerate

wire [7:0] rec_byteblk_in[3:0];
wire [7:0] rec_byteblk_out[3:0];

for (i = 0; i < 4; i=i+1) begin: rec_blk
    assign rec_byteblk_in[i] = byte_in[i][7:0] ^ byte_in[i][15:8] ^ byte_in[i][23:16] ^ byte_in[i][31:24];
    assign rec_byteblk_out[i] = byte_out[i][7:0] ^ byte_out[i][15:8] ^ byte_out[i][23:16] ^ byte_out[i][31:24];
end
*/


for (k = 0; k < 4; k=k+1) begin
    for (j = 0; j < 8; j=j+1) begin
        for (i = 0; i < d; i=i+1) begin
            assign byte_in[k][i*8+j] = sh_key_in[j*d+i + (12+k)*d*8]; // share00 and share11
            assign byte_in[k][16 + i*8+j] = sh_key_in[j*d+i + (16+k)*d*8]; // share01 and share10
            assign sh_lcol_SB[k][j*d+i] = byte_out[k][i*8+j]; // share00 and share11
            assign sh_lcol_SB[k][16 + j*d+i] = byte_out[k][16 + i*8+j]; // share01 and share10
        end
    end
end


wire [ 3:0] guardsS1[3:0];
wire [11:0] guardsS2[3:0];
wire [ 7:0] guardsS3[3:0];

generate
for(i=0;i<4;i=i+1) begin: guards
    assign guardsS1[i] = shblk_key_in[(i+1+4)*8*d +: 4];
    assign guardsS2[i] = {shblk_key_byte_pipeline[(i+1+4) % 16][0][7:4], shblk_key_byte_pipeline[(i+2+4) % 16][0][7:0]};
    // assign guardsS2[i] = RandomZw[i*rnd_busz +: rnd_busz];
    assign guardsS3[i] = shblk_key_byte_pipeline[(i+4) % 16][1][7:0];
end
endgenerate


// Sbox for the key scheduling
generate
for(i=0;i<4;i=i+1) begin: sbox_isnt
    two_stage_sbox sbox_unit(.in0(byte_in[i][7:0]), .in1(byte_in[i][23:16]), .in2(byte_in[i][31:24]), .in3(byte_in[i][15:8]), .out0(byte_out[i][7:0]), .out1(byte_out[i][23:16]), .out2(byte_out[i][31:24]), .out3(byte_out[i][15:8]), .r({RandomZw[i*rnd_busz +: rnd_busz], RandomBw[i*rnd_busb +: rnd_busb], guardsS3[i], guardsS2[i], guardsS1[i]}), .CLK(clk)
        );

/*
    aes_sbox_dom #(.d(d))
    sbox_unit(
        .clk(clk),
        .sboxIn(sh_key_in[(12+i)*8*d +: 8*d]),
        .RandomZw(RandomZw[i*rnd_busz +: rnd_busz]),
        .RandomBw(RandomBw[i*rnd_busb +: rnd_busb]),
        .sboxOut(sh_lcol_SB[i])
    );
*/    
end
endgenerate

// From Sbox rotation and RCON addition
wire [8*d-1:0] sh_lcol_SB_RCON [3:0];
MSKxor #(.d(d), .count(8))
xor_rcon(
    .ina(sh_RCON_in),
    .inb(sh_lcol_SB[1][0 +: 8*d]),
    .out(sh_lcol_SB_RCON[0])
);
assign sh_lcol_SB_RCON[1] = sh_lcol_SB[2][0 +: 8*d];
assign sh_lcol_SB_RCON[2] = sh_lcol_SB[3][0 +: 8*d];
assign sh_lcol_SB_RCON[3] = sh_lcol_SB[0][0 +: 8*d];


// genvar j;

// 2d array to store the pipelined results
wire [8*d-1:0] sh_key_byte_pipeline [15:0][LATENCY-1:0];
wire [8*d-1:0] sh_key_byte_delayed [15:0];

wire [8*d-1:0] shblk_key_byte_pipeline [15:0][LATENCY-1:0];

generate
for(i = 0; i < 16; i = i + 1) begin: se_bytes
    for(j = 0; j < LATENCY; j = j + 1) begin: se_stage
        shbit2shblk #(.d(d),.width(8))
        switch_encoding_pipelinedkey(
            .shbit(sh_key_byte_pipeline[i][j]),
            .shblk(shblk_key_byte_pipeline[i][j])
        );
    end
end
endgenerate



generate
for(i = 0; i < 16; i = i + 1) begin: key_byte_pipeline
    for(j = 0; j < LATENCY; j = j + 1) begin: stage
        wire [8*d-1:0] D, Q;

        MSKreg #(.d(d), .count(8)) reg_stage (
            .clk(clk),
            .in(D),
            .out(Q)
        );

        if (j == 0) begin
            assign D = sh_byte_in[i];
        end else begin
            assign D = key_byte_pipeline[i].stage[j-1].Q;
        end

        assign sh_key_byte_pipeline[i][j] = Q;  // store results for every pipeline cycle
    end
    assign sh_key_byte_delayed[i] =  stage[LATENCY-1].Q;;
end
endgenerate


// Create the pipeline for the key with the parametrized latency
/*
genvar j;
wire [8*d-1:0] sh_key_byte_delayed [15:0];
generate
for(i=0;i<16;i=i+1) begin: key_byte_pipeline
    for(j=0;j<LATENCY;j=j+1) begin: stage
        wire [8*d-1:0] D,Q;
        MSKreg #(.d(d),.count(8))
        reg_stage(
            .clk(clk),
            .in(D),
            .out(Q)
        );
        if (j==0) begin
            assign D = sh_byte_in[i];
        end else begin
            assign D = stage[j-1].Q;
        end
    end
    assign sh_key_byte_delayed[i] = stage[LATENCY-1].Q;
end
endgenerate
*/

//// Compute the new first column
MSKxor #(.d(d), .count(8))
xor_00(
    .ina(sh_lcol_SB_RCON[0]),
    .inb(sh_key_byte_delayed[0]),
    .out(sh_byte_out[0])
);

MSKxor #(.d(d), .count(8))
xor_10(
    .ina(sh_lcol_SB_RCON[1]),
    .inb(sh_key_byte_delayed[1]),
    .out(sh_byte_out[1])
);

MSKxor #(.d(d), .count(8))
xor_20(
    .ina(sh_lcol_SB_RCON[2]),
    .inb(sh_key_byte_delayed[2]),
    .out(sh_byte_out[2])
);

MSKxor #(.d(d), .count(8))
xor_30(
    .ina(sh_lcol_SB_RCON[3]),
    .inb(sh_key_byte_delayed[3]),
    .out(sh_byte_out[3])
);

//// Compute the other one
generate
for(i=0;i<3;i=i+1) begin: column_add
    for(j=0;j<4;j=j+1) begin: byte_add
        MSKxor #(.d(d), .count(8))
        xor_col(
            .ina(sh_byte_out[4*i+j]),
            .inb(sh_key_byte_delayed[4*(i+1)+j]),
            .out(sh_byte_out[4*(i+1)+j])
        );
    end
end
endgenerate
endmodule
