`include "blind.vh"
localparam blind_n_rnd = _blind_nrnd(d);
localparam rnd_bus0 = 2*d*(d-1);
localparam rnd_bus1 = 1*d*(d-1) + 2*blind_n_rnd;
localparam rnd_bus2 = 2*d*(d-1) + 4*blind_n_rnd;
localparam rnd_bus3 = 4*d*(d-1);

function integer _n_rndz(input integer d);
begin
if (d==1) _n_rndz = 1; // Hack to avoid 0-width signals.
else if (d==2) _n_rndz = 11;
else _n_rndz = 11;
end
endfunction

localparam n_random_z = d*(d-1);
localparam coeff = _n_rndz(d);
localparam rnd_busz = coeff*n_random_z;
localparam rnd_busb = 20*blind_n_rnd;


