`timescale 1ns/1ps
// Burst/in-flight regression for the round-based low-latency AES wrapper.
// It presents four independent plaintext/key pairs on four consecutive cycles
// and checks that the four recovered ciphertexts are returned in order on four
// consecutive cipher_valid cycles.
module tb_mskaes_burst4;
    parameter d = 2;
`ifndef LATENCY
`define LATENCY 3
`endif
    localparam LATENCY = `LATENCY;
    localparam T=2.0;
    localparam Td=T/2.0;
    localparam N=4;

    reg clk, nrst, valid_in;
    wire ready, cipher_valid;
    reg [127:0] umsk_plaintext, umsk_key;
    wire [128*d-1:0] sh_plaintext, sh_key, sh_ciphertext;
    reg prng_start_reseed;
    wire prng_out_valid, prng_busy;

    MSKcst #(.d(d),.count(128)) kshare(.cst(umsk_key), .out(sh_key));
    MSKcst #(.d(d),.count(128)) pshare(.cst(umsk_plaintext), .out(sh_plaintext));

    always #Td clk = ~clk;

    wrapper_aes128 #(.d(d),.LATENCY(LATENCY)) dut(
        .nrst(nrst), .clk(clk), .valid_in(valid_in), .ready(ready), .cipher_valid(cipher_valid),
        .sh_plaintext(sh_plaintext), .sh_key(sh_key), .sh_ciphertext(sh_ciphertext),
        .prng_seed(80'hD609C0895E8112153524), .prng_start_reseed(prng_start_reseed),
        .prng_out_ready(1'b1), .prng_out_valid(prng_out_valid), .prng_busy(prng_busy)
    );

    genvar gi;
    wire [127:0] rec_ciphertext;
    generate
      for (gi=0; gi<128; gi=gi+1) begin: bit_c
        assign rec_ciphertext[gi] = ^sh_ciphertext[d*gi +: d];
      end
    endgenerate

    reg [127:0] pt [0:N-1];
    reg [127:0] key [0:N-1];
    reg [127:0] exp [0:N-1];
    integer send_i;
    integer cycle;
    integer accepted_count;
    integer out_count;
    integer fail;
    integer first_out_cycle;
    integer last_out_cycle;

    always @(posedge clk) begin
        #0.1;
        if (nrst) begin
            cycle = cycle + 1;
            if (cipher_valid) begin
                $display("OUT cycle=%0d idx=%0d ct=%032x exp=%032x", cycle, out_count, rec_ciphertext, exp[out_count]);
                if (out_count >= N) begin
                    $display("BURST_FAIL too_many_outputs");
                    fail = 1;
                end else if (rec_ciphertext !== exp[out_count]) begin
                    $display("BURST_FAIL mismatch idx=%0d", out_count);
                    fail = 1;
                end
                if (out_count == 0) first_out_cycle = cycle;
                last_out_cycle = cycle;
                out_count = out_count + 1;
            end
        end
    end

    initial begin
        clk = 1'b1;
        nrst = 1'b1; valid_in = 1'b0; prng_start_reseed = 1'b0;
        umsk_plaintext = 128'h0; umsk_key = 128'h0;
        cycle = 0; accepted_count = 0; out_count = 0; fail = 0;
        first_out_cycle = -1; last_out_cycle = -1;
        pt[0]  = 128'h00000000000000000000000000000000;
        key[0] = 128'h00000000000000000000000000000000;
        exp[0] = 128'h2e2b34ca59fa4c883b2c8aefd44be966;
        pt[1]  = 128'h00112233445566778899aabbccddeeff;
        key[1] = 128'h000102030405060708090a0b0c0d0e0f;
        exp[1] = 128'hd0bfe1c79a57a7e74b276e90cca5a729;
        pt[2]  = 128'hffeeddccbbaa99887766554433221100;
        key[2] = 128'h0f0e0d0c0b0a09080706050403020100;
        exp[2] = 128'h5ac5b47080b7cdd830047b6ad8e0c469;
        pt[3]  = 128'h0123456789abcdeffedcba9876543210;
        key[3] = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        exp[3] = 128'hf60f5bad4fcdee54a61721f49ef50177;

        #0.1;
        nrst = 1'b0;
        #(3*T);
        nrst = 1'b1;
        #T;
        prng_start_reseed = 1'b1;
        #T;
        prng_start_reseed = 1'b0;
        #(30*T);

        // Present four consecutive inputs on successive negative edges so each
        // value is stable for the following accepting positive edge.  The ready
        // signal is sampled before that edge; it may deassert immediately after
        // the fourth accept when the first RCON token reaches feedback.
        for (send_i=0; send_i<N; send_i=send_i+1) begin
            @(negedge clk);
            umsk_plaintext = pt[send_i];
            umsk_key = key[send_i];
            valid_in = 1'b1;
            if (!ready) begin
                $display("BURST_FAIL not_ready_before_input idx=%0d cycle=%0d", send_i, cycle);
                fail = 1;
            end else begin
                accepted_count = accepted_count + 1;
                $display("ACCEPT_SCHEDULED cycle=%0d idx=%0d pt=%032x key=%032x", cycle+1, send_i, pt[send_i], key[send_i]);
            end
        end
        @(negedge clk);
        valid_in = 1'b0;
        umsk_plaintext = 128'h0;
        umsk_key = 128'h0;

        repeat (120) @(posedge clk);
        if (accepted_count != N) begin
            $display("BURST_FAIL accepted=%0d expected=%0d", accepted_count, N);
            fail = 1;
        end
        if (out_count != N) begin
            $display("BURST_FAIL outputs=%0d expected=%0d", out_count, N);
            fail = 1;
        end
        if ((first_out_cycle >= 0) && ((last_out_cycle - first_out_cycle + 1) != N)) begin
            $display("BURST_FAIL outputs_not_consecutive first=%0d last=%0d outputs=%0d", first_out_cycle, last_out_cycle, out_count);
            fail = 1;
        end
        if (!fail) begin
            $display("BURST_PASS accepted=%0d outputs=%0d first_out=%0d last_out=%0d", accepted_count, out_count, first_out_cycle, last_out_cycle);
        end else begin
            $display("BURST_FAIL_FINAL accepted=%0d outputs=%0d first_out=%0d last_out=%0d", accepted_count, out_count, first_out_cycle, last_out_cycle);
        end
        $finish;
    end
endmodule
