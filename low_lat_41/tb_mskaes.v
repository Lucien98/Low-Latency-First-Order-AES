`timescale 1ns/1ps
`ifndef DEFAULTSHARES
`define DEFAULTSHARES 3
`endif
module tb_mskaes 
#
(
    parameter d = 2//`DEFAULTSHARES
)
();

`ifndef LATENCY
`define LATENCY 3
`endif 

localparam LATENCY = `LATENCY;

localparam T=2.0;
localparam Td = T/2.0;


reg clk, nrst, valid_in;
wire ready;
wire cipher_valid;

reg [127:0] umsk_plaintext;
reg [127:0] umsk_key;
wire [128*d-1:0] sh_plaintext;
wire [128*d-1:0] sh_key;
wire [128*d-1:0] sh_ciphertext;
wire [128*d-1:0] shblk_dout;
wire [128*d-1:0] shblk_kin;

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

reg prng_start_reseed;
wire prng_out_valid;

// Clock
always@(*) #Td clk<=~clk;

    wrapper_aes128 #(.d(d),.LATENCY(LATENCY))
    dut(
        .nrst(nrst),
        .clk(clk),
        .valid_in(valid_in),
        .ready(ready),
        .cipher_valid(cipher_valid),
        .sh_plaintext(sh_plaintext),
        .sh_key(sh_key),
        .sh_ciphertext(sh_ciphertext),
        .prng_seed(80'hD609C0895E8112153524),
        .prng_start_reseed(prng_start_reseed),
        .prng_out_ready(1'b1),
        .prng_out_valid(prng_out_valid)
    );

shbit2shblk #(.d(d),.width(128))
switch_encoding_dout(
    .shbit(sh_ciphertext),
    .shblk(shblk_dout)
);

shbit2shblk #(.d(d),.width(128))
switch_encoding_kin(
    .shbit(sh_key),
    .shblk(shblk_kin)
);



genvar i;
wire [127:0] rec_ciphertext;
generate
for(i=0;i<128;i=i+1) begin: bit_c
    assign rec_ciphertext[i] = ^sh_ciphertext[d*i +: d];
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
    //$dumpfile(`DUMPFILE);
    $dumpvars(0,tb_mskaes);

    // Init
    clk = 1;
    nrst = 1;
    valid_in = 0;
    umsk_plaintext = 128'h0;//340737e0a29831318d305a88a8f64332;
    umsk_key = 128'h0;//593847FB7C86CF74A3E54BD76988A510;//3c4fcf098815f7aba6d2ae2816157e2b;

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
    #(30*T);
    // while (!prng_out_valid) begin
    //     #T;
    // end

    // Start a run
    valid_in = 1;
    #T;
    valid_in = 0;
    #T;
    while(!cipher_valid) begin
        #T;
    end

    if (rec_ciphertext == 128'h2e2b34ca59fa4c883b2c8aefd44be966) begin //320b6a19978511dcfb09dc021d842539 6584F7DBB46FAA4EE051B044691E256D 
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
