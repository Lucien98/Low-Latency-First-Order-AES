
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


// Create internal prods
// contains the value x*01, x*02, x*03
wire [8*d-1:0] a0_ps [2:0];
wire [8*d-1:0] a1_ps [2:0];
wire [8*d-1:0] a2_ps [2:0];
wire [8*d-1:0] a3_ps [2:0];

// a0 products
assign a0_ps[0] = a0;
MSKprodMC #(.d(d))
a0prods(
    .sh_in(a0),
    .sh_inx2(a0_ps[1]),
    .sh_inx3(a0_ps[2])
);

// a1 products
assign a1_ps[0] = a1;
MSKprodMC #(.d(d))
a1prods(
    .sh_in(a1),
    .sh_inx2(a1_ps[1]),
    .sh_inx3(a1_ps[2])
);

// a2 products
assign a2_ps[0] = a2;
MSKprodMC #(.d(d))
a2prods(
    .sh_in(a2),
    .sh_inx2(a2_ps[1]),
    .sh_inx3(a2_ps[2])
);

// a3 products
assign a3_ps[0] = a3;
MSKprodMC #(.d(d))
a3prods(
    .sh_in(a3),
    .sh_inx2(a3_ps[1]),
    .sh_inx3(a3_ps[2])
);

// Create Xors
// XORs for the b0
wire [8*d-1:0] b0_x0, b0_x1;
MSKxor #(.d(d),.count(8))
xrb0_0(
    .ina(a0_ps[1]),
    .inb(a1_ps[2]),
    .out(b0_x0)
);

MSKxor #(.d(d),.count(8))
xrb0_1(
    .ina(b0_x0),
    .inb(a2_ps[0]),
    .out(b0_x1)
);

MSKxor #(.d(d),.count(8))
xrb0_2(
    .ina(b0_x1),
    .inb(a3_ps[0]),
    .out(b0)
);

// XORs for the b1
wire [8*d-1:0] b1_x0, b1_x1;
MSKxor #(.d(d),.count(8))
xrb1_0(
    .ina(a0_ps[0]),
    .inb(a1_ps[1]),
    .out(b1_x0)
);

MSKxor #(.d(d),.count(8))
xrb1_1(
    .ina(b1_x0),
    .inb(a2_ps[2]),
    .out(b1_x1)
);

MSKxor #(.d(d),.count(8))
xrb1_2(
    .ina(b1_x1),
    .inb(a3_ps[0]),
    .out(b1)
);

// XORs for the b2
wire [8*d-1:0] b2_x0, b2_x1;
MSKxor #(.d(d),.count(8))
xrb2_0(
    .ina(a0_ps[0]),
    .inb(a1_ps[0]),
    .out(b2_x0)
);

MSKxor #(.d(d),.count(8))
xrb2_1(
    .ina(b2_x0),
    .inb(a2_ps[1]),
    .out(b2_x1)
);

MSKxor #(.d(d),.count(8))
xrb2_2(
    .ina(b2_x1),
    .inb(a3_ps[2]),
    .out(b2)
);

// XORs for the b3
wire [8*d-1:0] b3_x0, b3_x1;
MSKxor #(.d(d),.count(8))
xrb3_0(
    .ina(a0_ps[2]),
    .inb(a1_ps[0]),
    .out(b3_x0)
);

MSKxor #(.d(d),.count(8))
xrb3_1(
    .ina(b3_x0),
    .inb(a2_ps[0]),
    .out(b3_x1)
);

MSKxor #(.d(d),.count(8))
xrb3_2(
    .ina(b3_x1),
    .inb(a3_ps[1]),
    .out(b3)
);

endmodule
