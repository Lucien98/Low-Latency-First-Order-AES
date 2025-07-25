`timescale 1ns/1ps
module tb_mskaes_aeshpc 
();

`ifndef SHARES
`define SHARES 2
`endif

localparam d = `SHARES;

localparam T=2.0;
localparam Td = T/2.0;

`include "MSKand_hpc2.vh"

reg clk, nrst, valid_in;
wire ready;
wire cipher_valid;

reg [127:0] umsk_plaintext;
reg [127:0] umsk_key;
wire [128*d-1:0] sh_plaintext;
wire [128*d-1:0] sh_key;
wire [128*d-1:0] sh_ciphertext;

// Sharing key
MSKcst #(.d(d),.count(128))
kshare(
    .cst(umsk_key),
    .out(sh_key)
);


MSKcst #(.d(d),.count(128))
pshare(
    .cst(umsk_plaintext),
    .out(sh_plaintext)
);

localparam rnd0 = 9*hpc2rnd;
localparam rnd2 = 3*hpc2rnd;
localparam rnd3 = 4*hpc2rnd;
localparam rnd4 = 18*hpc2rnd;

reg [20*rnd0-1:0] rnd_bus0;
reg [20*rnd2-1:0] rnd_bus2;
reg [20*rnd3-1:0] rnd_bus3;
reg [20*rnd4-1:0] rnd_bus4;

reg prng_start_reseed;
wire prng_out_valid;

// Clock
always@(*) #Td clk<=~clk;

// Dut
`ifdef behavioral
MSKaes_128bits_round_based 
#(.d(d))
dut(
    .nrst(nrst),
    .clk(clk),
    .valid_in(valid_in),
    .ready(ready),
    .cipher_valid(cipher_valid),
    .sh_plaintext(sh_plaintext),
    .sh_key(sh_key),
    .sh_ciphertext(sh_ciphertext),
    .rnd_bus0(rnd_bus0),
    .rnd_bus2(rnd_bus2),
    .rnd_bus3(rnd_bus3),
    .rnd_bus4(rnd_bus4)
);
assign prng_out_valid = 1'b1;
`endif

genvar i;
wire [127:0] rec_ciphertext;
generate
for(i=0;i<128;i=i+1) begin: bit_c
    assign rec_ciphertext[i] = ^sh_ciphertext[d*i +: d];
end
endgenerate

// Randomness
integer seed = 0;
generate 
for (i=0;i<20*rnd0;i=i+1) begin: rnd_b_b0
    always@(posedge clk) rnd_bus0[i] <= $random(seed);
end
for (i=0;i<20*rnd2;i=i+1) begin: rnd_b_b2
    always@(posedge clk) rnd_bus2[i] <= $random(seed);
end
for (i=0;i<20*rnd3;i=i+1) begin: rnd_b_b3
    always@(posedge clk) rnd_bus3[i] <= $random(seed);
end
for (i=0;i<20*rnd4;i=i+1) begin: rnd_b_b4
    always@(posedge clk) rnd_bus4[i] <= $random(seed);
end
endgenerate

reg [15:0] counter_simu;
always@(posedge clk)
if(valid_in) begin
    counter_simu <= 1;
end else begin
    counter_simu <= counter_simu + 1;
end

////////
////////
integer f;
integer cnt;
initial begin
`ifndef RES_FILE
    `define RES_FILE "/tmp/__res_simu.txt"
`endif
    // File to write result
    f = $fopen(`RES_FILE,"w");
    $fwrite(f,"...progress...");

    // Dumping 
    //$dumpfile(`VCD_PATH);
    $dumpvars(0,tb_mskaes_aeshpc);

    // Init
    clk = 1;
    nrst = 1;
    valid_in = 0;
    umsk_plaintext = 128'h340737e0a29831318d305a88a8f64332;
    umsk_key = 128'h3c4fcf098815f7aba6d2ae2816157e2b;
    rnd_bus0 = 0;
    rnd_bus2 = 0;
    rnd_bus3 = 0;
    rnd_bus4 = 0;
    prng_start_reseed = 0;
    $display("Ciruit initialized (%d shares).",d);

    #0.1;
    // Reset sequence
    nrst = 0;
    #(3*T);
    nrst = 1;
    #T;
    $display("Circuit reset.");

    prng_start_reseed = 1;
    #T;
    prng_start_reseed = 0;
    while (!prng_out_valid) begin
        #T;
    end

    // Start a run
    valid_in = 1;
    #T;
    valid_in = 0;
    #T;
    while(!cipher_valid) begin
        #T;
    end

    if (rec_ciphertext == 128'h320b6a19978511dcfb09dc021d842539) begin
        $display("SUCCESS");
    end else begin
        $display("FAILURE");
        $finish;
    end
    $display("Finish (%d cycles)",counter_simu);
    $fwrite(f,"SUCCESS"); 
    $fclose(f);

    for(cnt=0;cnt<10;cnt=cnt+1) begin
        #T;
    end

    $finish;

end




endmodule
