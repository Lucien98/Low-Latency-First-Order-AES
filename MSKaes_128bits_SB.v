
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
generate
for(i=0;i<16;i=i+1) begin: guards
    assign guardsS1[i] = sbox_in0S1[(i+1) % 16][7:4];
    // assign guardsS2[i] = RandomZw[i*rnd_busz +: rnd_busz];
    // assign guardsS2[i] = {sbox_in0S2[(i+1) % 16][7:4], sbox_in0S2[(i+2) % 16][7:0]};
end
endgenerate

/*Guards for Stage 2*/
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

/*Guards for Stage 3*/
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

// Create the SBOX
/*
generate
for(i=0;i<16;i=i+1) begin: sbox_isnt
    two_stage_sbox_guards sbox_unit(.in0(byte_in[i][7:0]), .in1(byte_in[i][15:8]), .in2(byte_in[i][23:16]), .in3(byte_in[i][31:24]), .out0(byte_out[i][7:0]), .out1(byte_out[i][15:8]), .out2(byte_out[i][23:16]), .out3(byte_out[i][31:24]), .in0S1(sbox_in0S1[i]), .in0S2(sbox_in0S2[i]), .in0S3(sbox_in0S3[i]), .r({RandomZw[i*rnd_busz +: rnd_busz], RandomBw[i*rnd_busb +: rnd_busb], guardsS3[i], guardsS2[i], guardsS1[i]}), .CLK(clk)
        );
end
endgenerate
*/
two_stage_sbox_guards sbox_unit_0 (
    .in0(byte_in[0][7:0]),
    .in1(byte_in[0][15:8]),
    .in2(byte_in[0][23:16]),
    .in3(byte_in[0][31:24]),
    .out0(byte_out[0][7:0]),
    .out1(byte_out[0][15:8]),
    .out2(byte_out[0][23:16]),
    .out3(byte_out[0][31:24]),
    .in0S1(sbox_in0S1[0]),
    .in0S2(sbox_in0S2[0]),
    .in0S3(sbox_in0S3[0]),
    .r({RandomZw[0*2 +: 2], RandomBw[0*2 +: 2], guardsS3[0], guardsS2[0], guardsS1[0]}),
    .CLK(clk)
);

two_stage_sbox_guards sbox_unit_1 (
    .in0(byte_in[1][7:0]),
    .in1(byte_in[1][15:8]),
    .in2(byte_in[1][23:16]),
    .in3(byte_in[1][31:24]),
    .out0(byte_out[1][7:0]),
    .out1(byte_out[1][15:8]),
    .out2(byte_out[1][23:16]),
    .out3(byte_out[1][31:24]),
    .in0S1(sbox_in0S1[1]),
    .in0S2(sbox_in0S2[1]),
    .in0S3(sbox_in0S3[1]),
    .r({RandomZw[1*2 +: 2], RandomBw[1*2 +: 2], guardsS3[1], guardsS2[1], guardsS1[1]}),
    .CLK(clk)
);

two_stage_sbox_guards sbox_unit_2 (
    .in0(byte_in[2][7:0]),
    .in1(byte_in[2][15:8]),
    .in2(byte_in[2][23:16]),
    .in3(byte_in[2][31:24]),
    .out0(byte_out[2][7:0]),
    .out1(byte_out[2][15:8]),
    .out2(byte_out[2][23:16]),
    .out3(byte_out[2][31:24]),
    .in0S1(sbox_in0S1[2]),
    .in0S2(sbox_in0S2[2]),
    .in0S3(sbox_in0S3[2]),
    .r({RandomZw[2*2 +: 2], RandomBw[2*2 +: 2], guardsS3[2], guardsS2[2], guardsS1[2]}),
    .CLK(clk)
);

two_stage_sbox_guards sbox_unit_3 (
    .in0(byte_in[3][7:0]),
    .in1(byte_in[3][15:8]),
    .in2(byte_in[3][23:16]),
    .in3(byte_in[3][31:24]),
    .out0(byte_out[3][7:0]),
    .out1(byte_out[3][15:8]),
    .out2(byte_out[3][23:16]),
    .out3(byte_out[3][31:24]),
    .in0S1(sbox_in0S1[3]),
    .in0S2(sbox_in0S2[3]),
    .in0S3(sbox_in0S3[3]),
    .r({RandomZw[3*2 +: 2], RandomBw[3*2 +: 2], guardsS3[3], guardsS2[3], guardsS1[3]}),
    .CLK(clk)
);

two_stage_sbox_guards sbox_unit_4 (
    .in0(byte_in[4][7:0]),
    .in1(byte_in[4][15:8]),
    .in2(byte_in[4][23:16]),
    .in3(byte_in[4][31:24]),
    .out0(byte_out[4][7:0]),
    .out1(byte_out[4][15:8]),
    .out2(byte_out[4][23:16]),
    .out3(byte_out[4][31:24]),
    .in0S1(sbox_in0S1[4]),
    .in0S2(sbox_in0S2[4]),
    .in0S3(sbox_in0S3[4]),
    .r({RandomZw[4*2 +: 2], RandomBw[4*2 +: 2], guardsS3[4], guardsS2[4], guardsS1[4]}),
    .CLK(clk)
);

two_stage_sbox_guards sbox_unit_5 (
    .in0(byte_in[5][7:0]),
    .in1(byte_in[5][15:8]),
    .in2(byte_in[5][23:16]),
    .in3(byte_in[5][31:24]),
    .out0(byte_out[5][7:0]),
    .out1(byte_out[5][15:8]),
    .out2(byte_out[5][23:16]),
    .out3(byte_out[5][31:24]),
    .in0S1(sbox_in0S1[5]),
    .in0S2(sbox_in0S2[5]),
    .in0S3(sbox_in0S3[5]),
    .r({RandomZw[5*2 +: 2], RandomBw[5*2 +: 2], guardsS3[5], guardsS2[5], guardsS1[5]}),
    .CLK(clk)
);

two_stage_sbox_guards sbox_unit_6 (
    .in0(byte_in[6][7:0]),
    .in1(byte_in[6][15:8]),
    .in2(byte_in[6][23:16]),
    .in3(byte_in[6][31:24]),
    .out0(byte_out[6][7:0]),
    .out1(byte_out[6][15:8]),
    .out2(byte_out[6][23:16]),
    .out3(byte_out[6][31:24]),
    .in0S1(sbox_in0S1[6]),
    .in0S2(sbox_in0S2[6]),
    .in0S3(sbox_in0S3[6]),
    .r({RandomZw[6*2 +: 2], RandomBw[6*2 +: 2], guardsS3[6], guardsS2[6], guardsS1[6]}),
    .CLK(clk)
);

two_stage_sbox_guards sbox_unit_7 (
    .in0(byte_in[7][7:0]),
    .in1(byte_in[7][15:8]),
    .in2(byte_in[7][23:16]),
    .in3(byte_in[7][31:24]),
    .out0(byte_out[7][7:0]),
    .out1(byte_out[7][15:8]),
    .out2(byte_out[7][23:16]),
    .out3(byte_out[7][31:24]),
    .in0S1(sbox_in0S1[7]),
    .in0S2(sbox_in0S2[7]),
    .in0S3(sbox_in0S3[7]),
    .r({RandomZw[7*2 +: 2], RandomBw[7*2 +: 2], guardsS3[7], guardsS2[7], guardsS1[7]}),
    .CLK(clk)
);

two_stage_sbox_guards sbox_unit_8 (
    .in0(byte_in[8][7:0]),
    .in1(byte_in[8][15:8]),
    .in2(byte_in[8][23:16]),
    .in3(byte_in[8][31:24]),
    .out0(byte_out[8][7:0]),
    .out1(byte_out[8][15:8]),
    .out2(byte_out[8][23:16]),
    .out3(byte_out[8][31:24]),
    .in0S1(sbox_in0S1[8]),
    .in0S2(sbox_in0S2[8]),
    .in0S3(sbox_in0S3[8]),
    .r({RandomZw[8*2 +: 2], RandomBw[8*2 +: 2], guardsS3[8], guardsS2[8], guardsS1[8]}),
    .CLK(clk)
);

two_stage_sbox_guards sbox_unit_9 (
    .in0(byte_in[9][7:0]),
    .in1(byte_in[9][15:8]),
    .in2(byte_in[9][23:16]),
    .in3(byte_in[9][31:24]),
    .out0(byte_out[9][7:0]),
    .out1(byte_out[9][15:8]),
    .out2(byte_out[9][23:16]),
    .out3(byte_out[9][31:24]),
    .in0S1(sbox_in0S1[9]),
    .in0S2(sbox_in0S2[9]),
    .in0S3(sbox_in0S3[9]),
    .r({RandomZw[9*2 +: 2], RandomBw[9*2 +: 2], guardsS3[9], guardsS2[9], guardsS1[9]}),
    .CLK(clk)
);

two_stage_sbox_guards sbox_unit_10 (
    .in0(byte_in[10][7:0]),
    .in1(byte_in[10][15:8]),
    .in2(byte_in[10][23:16]),
    .in3(byte_in[10][31:24]),
    .out0(byte_out[10][7:0]),
    .out1(byte_out[10][15:8]),
    .out2(byte_out[10][23:16]),
    .out3(byte_out[10][31:24]),
    .in0S1(sbox_in0S1[10]),
    .in0S2(sbox_in0S2[10]),
    .in0S3(sbox_in0S3[10]),
    .r({RandomZw[10*2 +: 2], RandomBw[10*2 +: 2], guardsS3[10], guardsS2[10], guardsS1[10]}),
    .CLK(clk)
);

two_stage_sbox_guards sbox_unit_11 (
    .in0(byte_in[11][7:0]),
    .in1(byte_in[11][15:8]),
    .in2(byte_in[11][23:16]),
    .in3(byte_in[11][31:24]),
    .out0(byte_out[11][7:0]),
    .out1(byte_out[11][15:8]),
    .out2(byte_out[11][23:16]),
    .out3(byte_out[11][31:24]),
    .in0S1(sbox_in0S1[11]),
    .in0S2(sbox_in0S2[11]),
    .in0S3(sbox_in0S3[11]),
    .r({RandomZw[11*2 +: 2], RandomBw[11*2 +: 2], guardsS3[11], guardsS2[11], guardsS1[11]}),
    .CLK(clk)
);

two_stage_sbox_guards sbox_unit_12 (
    .in0(byte_in[12][7:0]),
    .in1(byte_in[12][15:8]),
    .in2(byte_in[12][23:16]),
    .in3(byte_in[12][31:24]),
    .out0(byte_out[12][7:0]),
    .out1(byte_out[12][15:8]),
    .out2(byte_out[12][23:16]),
    .out3(byte_out[12][31:24]),
    .in0S1(sbox_in0S1[12]),
    .in0S2(sbox_in0S2[12]),
    .in0S3(sbox_in0S3[12]),
    .r({RandomZw[12*2 +: 2], RandomBw[12*2 +: 2], guardsS3[12], guardsS2[12], guardsS1[12]}),
    .CLK(clk)
);

two_stage_sbox_guards sbox_unit_13 (
    .in0(byte_in[13][7:0]),
    .in1(byte_in[13][15:8]),
    .in2(byte_in[13][23:16]),
    .in3(byte_in[13][31:24]),
    .out0(byte_out[13][7:0]),
    .out1(byte_out[13][15:8]),
    .out2(byte_out[13][23:16]),
    .out3(byte_out[13][31:24]),
    .in0S1(sbox_in0S1[13]),
    .in0S2(sbox_in0S2[13]),
    .in0S3(sbox_in0S3[13]),
    .r({RandomZw[13*2 +: 2], RandomBw[13*2 +: 2], guardsS3[13], guardsS2[13], guardsS1[13]}),
    .CLK(clk)
);

two_stage_sbox_guards sbox_unit_14 (
    .in0(byte_in[14][7:0]),
    .in1(byte_in[14][15:8]),
    .in2(byte_in[14][23:16]),
    .in3(byte_in[14][31:24]),
    .out0(byte_out[14][7:0]),
    .out1(byte_out[14][15:8]),
    .out2(byte_out[14][23:16]),
    .out3(byte_out[14][31:24]),
    .in0S1(sbox_in0S1[14]),
    .in0S2(sbox_in0S2[14]),
    .in0S3(sbox_in0S3[14]),
    .r({RandomZw[14*2 +: 2], RandomBw[14*2 +: 2], guardsS3[14], guardsS2[14], guardsS1[14]}),
    .CLK(clk)
);

two_stage_sbox_guards sbox_unit_15 (
    .in0(byte_in[15][7:0]),
    .in1(byte_in[15][15:8]),
    .in2(byte_in[15][23:16]),
    .in3(byte_in[15][31:24]),
    .out0(byte_out[15][7:0]),
    .out1(byte_out[15][15:8]),
    .out2(byte_out[15][23:16]),
    .out3(byte_out[15][31:24]),
    .in0S1(sbox_in0S1[15]),
    .in0S2(sbox_in0S2[15]),
    .in0S3(sbox_in0S3[15]),
    .r({RandomZw[15*2 +: 2], RandomBw[15*2 +: 2], guardsS3[15], guardsS2[15], guardsS1[15]}),
    .CLK(clk)
);


// Assign output

generate
for(i=0;i<16;i=i+1) begin: sbyte_out
    assign sh_state_out[8*d*i +: 8*d] = sh_byte_out[i];
end
endgenerate



endmodule
