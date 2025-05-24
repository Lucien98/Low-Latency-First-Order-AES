
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

input [128*d-1:0] sh_key_in;
output [128*d-1:0] sh_key_out;
input [8*d-1:0] sh_RCON_in;

input [4*rnd_busz-1:0] RandomZw;

input [4*rnd_busb-1:0] RandomBw;

wire [128*d-1:0] sh_key_back;
assign sh_key_back[0 +: 12*8*d] = sh_key_in[0 +: 12*8*d];

wire [128*d-1:0] shblk_key_in;

shbit2shblk #(.d(d),.width(128))
switch_encoding_kin(
    .shbit(sh_key_in),
    .shblk(shblk_key_in)
);



MSKlin_map #(.d(d), .count(4), .matrix_sel(3))
lin_map_key(
    .sh_state_in(sh_key_in[12*8*d +: 4*8*d]),
    .sh_state_out(sh_key_back[12*8*d +: 4*8*d])
    );


// Byte matrix representation
genvar i;
//(*mark_debug="true"*)
wire [8*d-1:0] sh_byte_in [15:0];
wire [8*d-1:0] sh_byte_out [15:0];
generate
for(i=0;i<16;i=i+1) begin: kbyte_in
    assign sh_byte_in[i] = sh_key_back[8*d*i +: 8*d];
    assign sh_key_out[8*d*i +: 8*d] = sh_byte_out[i];
end
endgenerate

wire [15:0] byte_in[3:0];
wire [15:0] byte_out[3:0];

genvar j;
genvar k;

for (k = 0; k < 4; k=k+1) begin
    for (j = 0; j < 8; j=j+1) begin
        for (i = 0; i < d; i=i+1) begin
            assign byte_in[k][i*8+j] = sh_key_in[j*d+i + (12+k)*d*8];
            assign sh_lcol_SB[k][j*d+i] = byte_out[k][i*8+j];
        end
    end
end


wire [ 3:0] guardsS1[3:0];
wire [11:0] guardsS2[3:0];
wire [ 7:0] guardsS3[3:0];

generate
for(i=0;i<4;i=i+1) begin: guards
    assign guardsS1[i] = shblk_key_in[(i+1)*8*d +: 8];//sh_key_byte_pipeline[(i+1) % 16][0][3:0];
    assign guardsS2[i] = {shblk_key_byte_pipeline[(i+1) % 16][0][7:4], shblk_key_byte_pipeline[(i+2) % 16][0][7:0]};
    assign guardsS3[i] = shblk_key_byte_pipeline[(i+3) % 16][1][3:0];
end
endgenerate


// Sbox for the key scheduling
wire [8*d-1:0] sh_lcol_SB [3:0];
generate
for(i=0;i<4;i=i+1) begin: sbox_isnt
    three_stage_sbox sbox_unit(.in0(byte_in[i][7:0]), .in1(byte_in[i][15:8]), .out0(byte_out[i][7:0]), .out1(byte_out[i][15:8]), .r({RandomZw[i*rnd_busz +: rnd_busz], RandomBw[i*rnd_busb +: rnd_busb], guardsS3[i], guardsS2[i], guardsS1[i]}), .CLK(clk)
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
    .inb(sh_lcol_SB[1]),
    .out(sh_lcol_SB_RCON[0])
);
assign sh_lcol_SB_RCON[1] = sh_lcol_SB[2];
assign sh_lcol_SB_RCON[2] = sh_lcol_SB[3];
assign sh_lcol_SB_RCON[3] = sh_lcol_SB[0];


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
