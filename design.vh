`include "blind.vh"
localparam blind_n_rnd = _blind_nrnd(d);
localparam rnd_bus0 = 2*d*(d-1);
localparam rnd_bus1 = 1*d*(d-1) + 2*blind_n_rnd;
localparam rnd_bus2 = 2*d*(d-1) + 4*blind_n_rnd;
localparam rnd_bus3 = 4*d*(d-1);

localparam n_random_z = d*(d-1);
localparam rnd_busz = coeff*n_random_z;
`ifdef RAND_OPT
localparam rnd_busb = 8*blind_n_rnd;
`else
localparam rnd_busb = 18*blind_n_rnd;
`endif

