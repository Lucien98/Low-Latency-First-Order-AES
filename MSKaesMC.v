
module MSKaesMC
#
(
    parameter d = 2
)
(
    
    input [8*d-1:0] a0,
    
    input [8*d-1:0] a1,
    
    input [8*d-1:0] a2,
    
    input [8*d-1:0] a3,
    
    output [8*d-1:0] b0,
    
    output [8*d-1:0] b1,
    
    output [8*d-1:0] b2,
    
    output [8*d-1:0] b3
);


wire [8*d-1:0] row1, row2, row3, row4;
wire [8*d-1:0] mixed_row1, mixed_row2, mixed_row3, mixed_row4;

shbit2shblk #(.d(d),.width(8))
switch_encoding_row1 (
    .shbit(a0),
    .shblk(row1)
);
shbit2shblk #(.d(d),.width(8))
switch_encoding_row2 (
    .shbit(a1),
    .shblk(row2)
);
shbit2shblk #(.d(d),.width(8))
switch_encoding_row3 (
    .shbit(a2),
    .shblk(row3)
);
shbit2shblk #(.d(d),.width(8))
switch_encoding_row4 (
    .shbit(a3),
    .shblk(row4)
);
genvar i;
/*
generate
    for ( i = 0; i < d; i=i+1) begin
        aes_mixcolumn inst_col1_mixcolumn_share1(row1[i*8+:8], row2[i*8+:8], row3[i*8+:8], row4[i*8+:8], mixed_row1[i*8+:8], mixed_row2[i*8+:8], mixed_row3[i*8+:8], mixed_row4[i*8+:8]);
    end
endgenerate
*/

generate
    if (d == 2) begin
        aes_mixcolumn inst_col1_mixcolumn_share0(
            row1[7:0],  row2[7:0],  row3[7:0],  row4[7:0],
            mixed_row1[7:0], mixed_row2[7:0], mixed_row3[7:0], mixed_row4[7:0]
        );
        aes_mixcolumn inst_col1_mixcolumn_share1(
            row1[15:8], row2[15:8], row3[15:8], row4[15:8],
            mixed_row1[15:8], mixed_row2[15:8], mixed_row3[15:8], mixed_row4[15:8]
        );
    end
    else if (d == 3) begin
        aes_mixcolumn inst_col1_mixcolumn_share0(
            row1[7:0],  row2[7:0],  row3[7:0],  row4[7:0],
            mixed_row1[7:0], mixed_row2[7:0], mixed_row3[7:0], mixed_row4[7:0]
        );
        aes_mixcolumn inst_col1_mixcolumn_share1(
            row1[15:8], row2[15:8], row3[15:8], row4[15:8],
            mixed_row1[15:8], mixed_row2[15:8], mixed_row3[15:8], mixed_row4[15:8]
        );
        aes_mixcolumn inst_col1_mixcolumn_share2(
            row1[23:16], row2[23:16], row3[23:16], row4[23:16],
            mixed_row1[23:16], mixed_row2[23:16], mixed_row3[23:16], mixed_row4[23:16]
        );
    end
    else if (d == 4) begin
        aes_mixcolumn inst_col1_mixcolumn_share0(
            row1[7:0],  row2[7:0],  row3[7:0],  row4[7:0],
            mixed_row1[7:0], mixed_row2[7:0], mixed_row3[7:0], mixed_row4[7:0]
        );
        aes_mixcolumn inst_col1_mixcolumn_share1(
            row1[15:8], row2[15:8], row3[15:8], row4[15:8],
            mixed_row1[15:8], mixed_row2[15:8], mixed_row3[15:8], mixed_row4[15:8]
        );
        aes_mixcolumn inst_col1_mixcolumn_share2(
            row1[23:16], row2[23:16], row3[23:16], row4[23:16],
            mixed_row1[23:16], mixed_row2[23:16], mixed_row3[23:16], mixed_row4[23:16]
        );
        aes_mixcolumn inst_col1_mixcolumn_share3(
            row1[31:24], row2[31:24], row3[31:24], row4[31:24],
            mixed_row1[31:24], mixed_row2[31:24], mixed_row3[31:24], mixed_row4[31:24]
        );
    end
endgenerate


shblk2shbit #(.d(d),.width(8))
switch_encoding_mixed_row1 (
    .shblk(mixed_row1),
    .shbit(b0)
);
shblk2shbit #(.d(d),.width(8))
switch_encoding_mixed_row2 (
    .shblk(mixed_row2),
    .shbit(b1)
);
shblk2shbit #(.d(d),.width(8))
switch_encoding_mixed_row3 (
    .shblk(mixed_row3),
    .shbit(b2)
);
shblk2shbit #(.d(d),.width(8))
switch_encoding_mixed_row4 (
    .shblk(mixed_row4),
    .shbit(b3)
);


endmodule
