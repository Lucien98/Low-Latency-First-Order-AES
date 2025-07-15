
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
// wire [7:0] umsk_byte_in[15:0];
//(*mark_debug="true"*)
// wire [7:0] umsk_byte_out[15:0];

wire [8*d-1:0] byte_in[15:0];
wire [8*d-1:0] byte_out[15:0];

genvar i;
genvar j;
genvar k;

for (k = 0; k < 16; k=k+1) begin
    for (j = 0; j < 8; j=j+1) begin
        for (i = 0; i < d; i=i+1) begin
            assign byte_in[k][i*8+j] = sh_byte_in[k][j*d+i];
            assign sh_byte_out[k][j*d+i] = byte_out[k][i*8+j];
        end
    end
end
/*generate
for(i=0;i<16;i=i+1) begin: umsk_byte
    for (j = 0; j < 8; j=j+1) begin
        assign umsk_byte_in[i][j] = ^sh_byte_in[i][j*d +: d];
        assign umsk_byte_out[i][j] = ^sh_byte_out[i][j*d +: d];
    end
end
endgenerate
*/
generate
for(i=0;i<16;i=i+1) begin: sbyte_in
    assign sh_byte_in[i] = sh_state_in[8*d*i +: 8*d];
end
endgenerate


wire [7:0] sbox_in0S1[15:0];
wire [7:0] sbox_in0S2[15:0];
wire [7:0] sbox_in0S3[15:0];

wire [ 3:0] guardsS1[15:0];
wire [11:0] guardsS2[15:0];
wire [ 7:0] guardsS3[15:0];


// assign guardsS1[0] = sbox_in0S1[1][3:0];
// assign guardsS2[0] = {sbox_in0S2[1][3:0], sbox_in0S2[2][7:0]}

// assign guardsS1[1] = sbox_in0S1[2][3:0];
// assign guardsS2[1] = {sbox_in0S2[2][3:0], sbox_in0S2[3][7:0]}

/*Guards for Stage 1*/
// generate
// for(i=0;i<16;i=i+1) begin: guards
//     assign guardsS1[i] = sbox_in0S1[(i+1) % 16][3:0];
//     // assign guardsS2[i] = RandomZw[i*rnd_busz +: rnd_busz];
//     // assign guardsS2[i] = {sbox_in0S2[(i+1) % 16][7:4], sbox_in0S2[(i+2) % 16][7:0]};
// end
// endgenerate
generate
for (i = 0; i < 16; i = i + 1) begin: guards
    if (i != 3 && i != 7 && i != 11 && i != 15) begin
        assign guardsS1[i] = sbox_in0S1[(i + 1) % 16][3:0];
        assign guardsS2[i] = {sbox_in0S2[(i + 1) % 16][7:4], sbox_in0S2[(i + 2) % 16][7:0]};
        assign guardsS3[i] = sbox_in0S3[(i+3) % 16];
    end
end
endgenerate
assign guardsS1[ 3] = sbox_in0S1[ 1][3:0];
assign guardsS1[ 7] = sbox_in0S1[ 1][3:0];
assign guardsS1[11] = sbox_in0S1[ 0][3:0];
assign guardsS1[15] = sbox_in0S1[ 4][3:0];

assign guardsS2[ 3] = {sbox_in0S2[ 1][7:4], sbox_in0S2[ 2]};
assign guardsS2[ 7] = {sbox_in0S2[ 1][7:4], sbox_in0S2[ 6]};
assign guardsS2[11] = {sbox_in0S2[ 0][7:4], sbox_in0S2[ 5]};
assign guardsS2[15] = {sbox_in0S2[ 4][7:4], sbox_in0S2[ 9]};

assign guardsS3[ 3] = sbox_in0S3[ 8];
assign guardsS3[ 7] = sbox_in0S3[12];
assign guardsS3[11] = sbox_in0S3[10];
assign guardsS3[15] = sbox_in0S3[14];


/*Guards for Stage 2*/
/*
assign guardsS2[ 0] = {sbox_in0S2[ 8], sbox_in0S2[12][3:0]};
assign guardsS2[ 5] = {sbox_in0S2[13], sbox_in0S2[ 1][3:0]};
assign guardsS2[10] = {sbox_in0S2[ 2], sbox_in0S2[ 6][3:0]};
assign guardsS2[15] = {sbox_in0S2[ 7], sbox_in0S2[11][3:0]};

assign guardsS2[ 4] = {sbox_in0S2[12], sbox_in0S2[ 0][3:0]};
assign guardsS2[ 9] = {sbox_in0S2[ 1], sbox_in0S2[ 5][3:0]};
assign guardsS2[14] = {sbox_in0S2[ 6], sbox_in0S2[10][3:0]};
assign guardsS2[ 3] = {sbox_in0S2[11], sbox_in0S2[15][3:0]};

assign guardsS2[ 8] = {sbox_in0S2[ 0], sbox_in0S2[ 4][3:0]};
assign guardsS2[13] = {sbox_in0S2[ 5], sbox_in0S2[ 9][3:0]};
assign guardsS2[ 2] = {sbox_in0S2[10], sbox_in0S2[14][3:0]};
assign guardsS2[ 7] = {sbox_in0S2[15], sbox_in0S2[ 3][3:0]};

assign guardsS2[12] = {sbox_in0S2[ 4], sbox_in0S2[ 8][3:0]};
assign guardsS2[ 1] = {sbox_in0S2[ 9], sbox_in0S2[13][3:0]};
assign guardsS2[ 6] = {sbox_in0S2[14], sbox_in0S2[ 2][3:0]};
assign guardsS2[11] = {sbox_in0S2[ 3], sbox_in0S2[ 7][3:0]};
*/
/*Guards for Stage 3*/
/*
assign guardsS3[ 0] = sbox_in0S3[ 4];
assign guardsS3[ 5] = sbox_in0S3[ 9];
assign guardsS3[10] = sbox_in0S3[14];
assign guardsS3[15] = sbox_in0S3[ 3];

assign guardsS3[ 4] = sbox_in0S3[8];
assign guardsS3[ 9] = sbox_in0S3[13];
assign guardsS3[14] = sbox_in0S3[ 2];
assign guardsS3[ 3] = sbox_in0S3[ 7];

assign guardsS3[ 8] = sbox_in0S3[12];
assign guardsS3[13] = sbox_in0S3[ 1];
assign guardsS3[ 2] = sbox_in0S3[ 6];
assign guardsS3[ 7] = sbox_in0S3[11];

assign guardsS3[12] = sbox_in0S3[0];
assign guardsS3[ 1] = sbox_in0S3[5];
assign guardsS3[ 6] = sbox_in0S3[10];
assign guardsS3[11] = sbox_in0S3[15];
*/
// Create the SBOX
generate
for(i=0;i<16;i=i+1) begin: sbox_isnt
    two_stage_sbox_guards sbox_unit(.in0(byte_in[i][7:0]), .in1(byte_in[i][15:8]), .in2(byte_in[i][23:16]), .in3(byte_in[i][31:24]), .out0(byte_out[i][7:0]), .out1(byte_out[i][15:8]), .out2(byte_out[i][23:16]), .out3(byte_out[i][31:24]), .in0S1(sbox_in0S1[i]), .in0S2(sbox_in0S2[i]), .in0S3(sbox_in0S3[i]), .r({RandomZw[i*rnd_busz +: 2], RandomBw[i*rnd_busb +: 2], guardsS3[i], RandomZw[i*rnd_busz +: 6], RandomBw[i*rnd_busb +: 6], guardsS1[i]}), .CLK(clk)
    // two_stage_sbox_guards sbox_unit(.in0(byte_in[i][7:0]), .in1(byte_in[i][15:8]), .in2(byte_in[i][23:16]), .in3(byte_in[i][31:24]), .out0(byte_out[i][7:0]), .out1(byte_out[i][15:8]), .out2(byte_out[i][23:16]), .out3(byte_out[i][31:24]), .in0S1(sbox_in0S1[i]), .in0S2(sbox_in0S2[i]), .in0S3(sbox_in0S3[i]), .r({RandomZw[i*rnd_busz +: rnd_busz], RandomBw[i*rnd_busb +: rnd_busb], guardsS3[i], guardsS2[i], guardsS1[i]}), .CLK(clk)
        );
   /* aes_sbox_dom #(.d(d))
    sbox_unit(
        .clk(clk),
        .sboxIn(sh_byte_in[i]),
        .RandomZw(RandomZw[i*rnd_busz +: rnd_busz]),
        .RandomBw(RandomBw[i*rnd_busb +: rnd_busb]),
        .sboxOut(sh_byte_out[i])
    );*/
end
endgenerate
// Assign output

generate
for(i=0;i<16;i=i+1) begin: sbyte_out
    assign sh_state_out[8*d*i +: 8*d] = sh_byte_out[i];
end
endgenerate



endmodule
