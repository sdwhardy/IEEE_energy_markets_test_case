%TNEP optimizor input file

function mpc = owpp_tnep_map
mpc.version = '2';
mpc.baseMVA = 100;

%% bus data
	%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin
	mpc.bus = [
1 3 0 0 0 0 1 1 0 220 1 1.1 0.9;
2 2 0 0 0 0 1 1 0 220 1 1.1 0.9;
3 2 0 0 0 0 1 1 0 220 1 1.1 0.9;
4 2 0 0 0 0 1 1 0 220 1 1.1 0.9;
5 2 0 0 0 0 1 1 0 220 1 1.1 0.9;
];
%% generator data
	%	bus	Pg	Qg	Qmax	Qmin	Vg	mBase	status	Pmax	Pmin	Pc1	Pc2	Qc1min	Qc1max	Qc2min	Qc2max	ramp_agc	ramp_10	ramp_30	ramp_q	apf
	mpc.gen = [
3 0 0 0 0 1 100 1 3.5 0 0 0 0 0 0 0 0 0 0 0 1;
4 0 0 0 0 1 100 1 1 0 0 0 0 0 0 0 0 0 0 0 1;
5 0 0 0 0 1 100 1 1 0 0 0 0 0 0 0 0 0 0 0 1;
];
%%Additional generator fields, type=0(wind generator), type=1(onshore market ie load and generator created)
	%column_names% 		type invest
	mpc.gen_type = [
0 1
1 0
1 0
];

	%% branch data
	%	fbus	tbus	r	       x	    b	  rateA	rateB	rateC	ratio	angle	status	angmin	angmax
	mpc.branch = [
1	2	0.010   0.100   0.00   0  0  0  0  0  1 -60  60;
1	3	0.010   0.100   0.00   0  0  0  0  0  1 -60  60;
2	3	0.010   0.100   0.00   0  0  0  0  0  1 -60  60;
];
%%Additional generator fields, type=0(wind generator), type=1(onshore market ie load and generator created)
	%column_names% 		cost
	mpc.branch_cost = [
1.14;
1.14;
1.14;
];

	%%candidate branch data
	%column_names%	f_bus	t_bus	br_r	br_x	br_b	rate_a	rate_b	rate_c	tap	shift	br_status	angmin	angmax	mva	construction_cost mm
	mpc.ne_branch = [
1	2	0.004 0.04 0 1000 1000 1000 0 0 0 -60 60 100 10 1000.0;
1	3	0.004 0.04 0 1000 1000 1000 0 0 0 -60 60 100 10 1000.0;
2	3	0.004 0.04 0 1000 1000 1000 0 0 0 -60 60 100 10 1000.0;
];
%%-----  OPF Data  -----%%
	%% generator cost data
	%	1	startup	shutdown	n	x1	y1	...	xn	yn
	%	2	startup	shutdown	n	c(n-1)	...	c0
	mpc.gencost = [
2 0 0 2 0 0
2 0 0 2 0 0
2 0 0 2 0 0
];
%% existing dc bus data
	%column_names%   busdc_i grid    Pdc     Vdc     basekVdc    Vdcmax  Vdcmin Cdc
	mpc.busdc = [
1 1 0 1 300 1.1 0.9 0;
2 2 0 1 300 1.1 0.9 0;
3 3 0 1 300 1.1 0.9 0;
4 4 0 1 300 1.1 0.9 0;
5 5 0 1 300 1.1 0.9 0;
];
%% All Candidate equipment has equivalent existing infrastructure field as well ie  mpc.branchdc_ne <->  mpc.branchdc similar to AC
	%% Candidate DC buses here - refer to MATACDC 1.0 User’s Manual for description of fields
	%% candidate dc bus data
	%column_names%   busdc_i grid    Pdc     Vdc     basekVdc    Vdcmax  Vdcmin  Cdc
	mpc.busdc_ne = [
	10000              4       0       1       300         1.1     0.9     0;
	];
%% existing dc branches
	%column_names%   fbusdc  tbusdc  r      l        c   rateA   rateB rateC cost status
	mpc.branchdc = [
1	2	0.0	0.00	 0.00  0	 		0	 0 0.125	 1;
1	3	0.0	0.00	 0.00  0	 		0	 0 0.125	 1;
2	3	0.0	0.00	 0.00  0	 		0	 0 0.125	 1;
];
%% Candidate Branches here - refer to MATACDC 1.0 Users Manual for description of fields
	 %% candidate branches
	 %column_names%   fbusdc  tbusdc  r      l        c   rateA   rateB   rateC status cost
	 mpc.branchdc_ne = [
1 2 0 0 0 10000 10000 10000 1 0;
1 3 0 0 0 10000 10000 10000 1 0;
2 3 0 0 0 10000 10000 10000 1 0;
];

	%% existing converters
	%column_names%   busdc_i busac_i type_dc type_ac P_g   Q_g  islcc  	Vtar 		rtf  xtf  transformer tm   bf  filter    rc      xc  reactor   basekVac Vmmax   Vmmin   Imax     status   LossA  LossB  LossCrec LossCinv   droop   Pdcset     Vdcset  dVdcset Pacmax Pacmin Qacmax   Qacmin cost
	mpc.convdc = [
1 1 2 3 400000 0 0 1 0.001 0.1 0 1 0.08 0 0.001 0.09 0 220 1.1 0.9 100000 1 0 0 0 0 0.005 -52.7 1.0079 0 40000 -40000 40000 -40000 19.25;
2 2 3 2 400000 0 0 1 0.001 0.1 0 1 0.08 0 0.001 0.09 0 220 1.1 0.9 100000 1 0 0 0 0 0.005 -52.7 1.0079 0 40000 -40000 40000 -40000 19.25;
3 3 3 2 400000 0 0 1 0.001 0.1 0 1 0.08 0 0.001 0.09 0 220 1.1 0.9 100000 1 0 0 0 0 0.005 -52.7 1.0079 0 40000 -40000 40000 -40000 51.5;
4 4 3 2 400000 0 0 1 0.001 0.1 0 1 0.08 0 0.001 0.09 0 220 1.1 0.9 100000 1 0 0 0 0 0.005 -52.7 1.0079 0 40000 -40000 40000 -40000 19.25;
5 5 3 2 400000 0 0 1 0.001 0.1 0 1 0.08 0 0.001 0.09 0 220 1.1 0.9 100000 1 0 0 0 0 0.005 -52.7 1.0079 0 40000 -40000 40000 -40000 19.25;
];

	%trans, filter, reactor, vmin vmax same as conv
	%% candidate converters
	%column_names%   busdc_i busac_i type_dc type_ac P_g   Q_g  islcc  Vtar    rtf   xtf  transformer tm   bf 	filter    rc     xc  reactor   basekVac Vmmax   Vmmin   Imax    status   LossA LossB  LossCrec LossCinv  droop     Pdcset    Vdcset  dVdcset Pacmax Pacmin Qacmax Qacmin cost
	mpc.convdc_ne = [
	                1000       2      1       1    400000    0   	0     1.0   0.001  0.1       0 			 1 	0.08 		0 		0.001   0.09 		0  				220    1.1     0.9    100000      1     	 0     0        0       0      0.0050    -52.7     1.0079     0  		1  -1   1    -1   1000000;
	];
 % hours
	 mpc.time_elapsed = 1.0

	 %% storage data
	 % storage_bus   ps   qs energy energy_rating charge_rating discharge_rating charge_efficiency discharge_efficiency thermal_rating    qmin   qmax    r    x p_loss q_loss status
	 mpc.storage = [
1 0 0 0 0 0 0 0.9 0.9 0 0 0 0 0 0 0 1;
2 0 0 0 0 0 0 0.9 0.9 0 0 0 0 0 0 0 1;
3 0 0 0 0 0 0 0.9 0.9 0 0 0 0 0 0 0 1;
4 0 0 0 0 0 0 0.9 0.9 0 0 0 0 0 0 0 1;
5 0 0 0 0 0 0 0.9 0.9 0 0 0 0 0 0 0 1;
];
%% cost 36.6
	 %% storage additional data
	 %column_names% max_energy_absorption stationary_energy_inflow stationary_energy_outflow self_discharge_rate cost
	 mpc.storage_extra = [
0 0 0 0.0001 39;
0 0 0 0.0001 39;
0 0 0 0.0001 39;
0 0 0 0.0001 39;
0 0 0 0.0001 39;
];
%% storage data
	 %column_names%   storage_bus ps 	qs 	energy  energy_rating charge_rating  discharge_rating  charge_efficiency  discharge_efficiency  thermal_rating  qmin  	qmax  	r  		x  p_loss  	q_loss  status eq_cost inst_cost co2_cost 	max_energy_absorption 	stationary_energy_inflow 	stationary_energy_outflow 	self_discharge_rate	 	cost_abs 	cost_inj on_off
	 mpc.ne_storage = [
	 1	 0.0 0.0 0.0 6400.0	1280.0 1600.0 0.9 0.9 16000	-3200.0	4480.0 0.1 0.0 0.0	0.0	 0 	100000 	100000	100000 	32000000 0 	0 1e-4 0 0 1;
	 											 											];
