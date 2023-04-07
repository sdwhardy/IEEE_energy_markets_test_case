########################### Create topology.m ########################
#loads files and calls main function 
function topology_df(rt_ex, relax, _ac)
	ac_cable_df = DataFrames.DataFrame(XLSX.readtable(rt_ex*"input.xlsx", "CABLES_AC_SET_UP"))
	dc_cable_df = DataFrames.DataFrame(XLSX.readtable(rt_ex*"input.xlsx", "CABLES_DC_SET_UP"))
	rem_df = DataFrames.DataFrame(XLSX.readtable(rt_ex*"input.xlsx", "REMAINDER"))
	ppf_mainACDCStorage2mfile(rem_df,ac_cable_df,dc_cable_df,rt_ex, relax, _ac)
end

#ACDC network with storage main logic to create topology.m file
function ppf_mainACDCStorage2mfile(r_df,ac_df, dc_df, cdir,relax, _ac)
	base_mva=100
	matfile = open(cdir*"topology.m","w")#open the .mat file
	ppf_header(matfile,base_mva)#print top function data
	ppf_Buss(matfile,r_df)#prints the bus data
	ppf_Gens(matfile,r_df)#prints all generator (OWPP) data
	ppf_acbranches(matfile,ac_df,relax, _ac)
	ppf_costs(matfile,r_df)
	ppf_BussDC(matfile,r_df)#prints the bus data
	ppf_BussDC_ne_blank(matfile)#prints the bus data
	#ppf_dcbranches_blank(matfile)
	ppf_dcbranches(matfile,dc_df, relax)
	ppf_convs(matfile,r_df)
	ppf_dc_blank_conv_ne(matfile)
	ppf_storage(matfile,r_df)
	close(matfile)#close the .mat file
end

function ppf_header(mf,base_mva)
	println(mf, "%TNEP optimizor input file")
	println(mf, "")
	println(mf, "function mpc = owpp_tnep_map")
	println(mf, "mpc.version = '2';")
	print(mf, "mpc.baseMVA = ")
	print(mf, base_mva)
	println(mf, ";")
	println(mf, "")
end

function ppf_Buss(mf,r_df)
	println(mf,"%% bus data
	%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin
	mpc.bus = [")
	for r in r_df[!,:bus]
		println(mf,r)
	end
	println(mf,"];")
end

function ppf_Gens(mf,r_df)
	println(mf,"%% generator data
	%	bus	Pg	Qg	Qmax	Qmin	Vg	mBase	status	Pmax	Pmin	Pc1	Pc2	Qc1min	Qc1max	Qc2min	Qc2max	ramp_agc	ramp_10	ramp_30	ramp_q	apf
	mpc.gen = [")

	load_gen=filter!(x->!ismissing(x),vcat(r_df[!,:load],r_df[!,:gen]))
	#load_gen_cost=filter!(x->!ismissing(x),vcat(r_df[:load_cost],r_df[:gen_cost]))
	for r in load_gen
		println(mf,r)
	end
	println(mf,"];")

	println(mf,"%%Additional generator fields, type=0(wind generator), type=1(onshore market ie load and generator created)
	%column_names% 		type invest
	mpc.gen_type = [")

	gen_type=filter!(x->!ismissing(x),r_df[!,:gen_type])
	for r in gen_type
		if (r[1]!='2')
			println(mf,r);end
	end

	println(mf,"];")
end


function ppf_acbranches(mf,ac_df, relax, _AC)
	clms=filter!(x->x!="Row",names(ac_df))
	cables=[]
	for c in clms
		cables=vcat(cables,ac_df[!,Symbol(c)])
	end
	cables=filter!(x->!ismissing(x),cables)
	println(mf,"
	%% branch data
	%	fbus	tbus	r	       x	    b	  rateA	rateB	rateC	ratio	angle	status	angmin	angmax
	mpc.branch = [")
	for r in cables
		rv=split(r," ")
		filter!(x->x!="",rv)
		if (relax)
			println(mf,rv[1]*"	"*rv[2]*"	"*"0.010   0.100   0.00   0  0  0  0  0  "*_AC*" -60  60;")
		else
			println(mf,rv[1]*"	"*rv[2]*"	"*"0.010   0.100   0.00   0  0  0  0  0  0 -60  60;")
		end
	end
	println(mf,"];")

	println(mf,"%%Additional generator fields, type=0(wind generator), type=1(onshore market ie load and generator created)
	%column_names% 		cost
	mpc.branch_cost = [")

	for r in cables
		println(mf,"1.14;")
	end
	println(mf,"];")

	println(mf,"
	%candidate branch data
	%column_names%	f_bus	t_bus	br_r	br_x	br_b	rate_a	rate_b	rate_c	tap	shift	br_status	angmin	angmax	mva	construction_cost
	mpc.ne_branch = [")

	for r in cables
		rv=split(r," ")
		filter!(x->x!="",rv)
		if (relax)
			println(mf,rv[1]*"	"*rv[2]*"	"*rv[3]*"	"*rv[4]*"	"*rv[5]*"	"*rv[6]*"	"*rv[7]*"	"*rv[8]*"	"*rv[9]*"	"*rv[10]*"	"*"0"*"	"*rv[12]*"	"*rv[13]*"	"*rv[14]*"	"*rv[15])
		else
			println(mf,rv[1]*"	"*rv[2]*"	"*rv[3]*"	"*rv[4]*"	"*rv[5]*"	"*rv[6]*"	"*rv[7]*"	"*rv[8]*"	"*rv[9]*"	"*rv[10]*"	"*_AC*"	"*rv[12]*"	"*rv[13]*"	"*rv[14]*"	"*rv[15])
		end
	end
	println(mf,"];")
end


function ppf_costs(mf,r_df)
	println(mf,"%%-----  OPF Data  -----%%
	%% generator cost data
	%	1	startup	shutdown	n	x1	y1	...	xn	yn
	%	2	startup	shutdown	n	c(n-1)	...	c0
	mpc.gencost = [")


	load_gen_cost=filter!(x->!ismissing(x),vcat(r_df[!,:load_cost],r_df[!,:gen_cost]))
	for r in load_gen_cost
		println(mf,r)
	end
	println(mf,"];")
end


function ppf_BussDC(mf,r_df)
	println(mf,"%% existing dc bus data
	%column_names%   busdc_i grid    Pdc     Vdc     basekVdc    Vdcmax  Vdcmin Cdc
	mpc.busdc = [")
	for r in r_df[!,:bus_dc]
		println(mf,r)
	end
	println(mf,"];")
end


function ppf_BussDC_ne_blank(mf)
	println(mf,"%% All Candidate equipment has equivalent existing infrastructure field as well ie  mpc.branchdc_ne <->  mpc.branchdc similar to AC
	%% Candidate DC buses here - refer to MATACDC 1.0 User’s Manual for description of fields
	%% candidate dc bus data
	%column_names%   busdc_i grid    Pdc     Vdc     basekVdc    Vdcmax  Vdcmin  Cdc
	mpc.busdc_ne = [
	10000              4       0       1       300         1.1     0.9     0;
	];")
end


function ppf_dcbranches(mf,dc_df, relax)
	clms=filter!(x->x!="Row",names(dc_df))
	cables=[]
	for c in clms
		cables=vcat(cables,dc_df[!,Symbol(c)])
	end
	cables=filter!(x->!ismissing(x),cables)
	println(mf,"%% existing dc branches
	%column_names%   fbusdc  tbusdc  r      l        c   rateA   rateB rateC cost status
	mpc.branchdc = [")
	for r in cables
		rv=split(r," ")
		filter!(x->x!="",rv)
		if (relax)
			println(mf,rv[1]*"	"*rv[2]*"	"*"0.0	0.00	 0.00  0	 		0	 0 0.125	 1;")
		else
			println(mf,rv[1]*"	"*rv[2]*"	"*"0.0	0.00	 0.00  0	 		0	 0 0.125	 0;")
		end
	end
	println(mf,"];")
	println(mf,"%% Candidate Branches here - refer to MATACDC 1.0 Users Manual for description of fields
	 %% candidate branches
	 %column_names%   fbusdc  tbusdc  r      l        c   rateA   rateB   rateC status cost
	 mpc.branchdc_ne = [")

	for r in cables
		println(mf,r)
	end
	println(mf,"];")
end


function ppf_convs(mf,r_df)
	println(mf,"
	%% existing converters
	%column_names%   busdc_i busac_i type_dc type_ac P_g   Q_g  islcc  	Vtar 		rtf  xtf  transformer tm   bf  filter    rc      xc  reactor   basekVac Vmmax   Vmmin   Imax     status   LossA  LossB  LossCrec LossCinv   droop   Pdcset     Vdcset  dVdcset Pacmax Pacmin Qacmax   Qacmin cost
	mpc.convdc = [")

	for r in r_df[!,:conv_dc]
		println(mf,r)
	end
	println(mf,"];")
end

function ppf_dc_blank_conv_ne(mf)
	println(mf,"
	%trans, filter, reactor, vmin vmax same as conv
	%% candidate converters
	%column_names%   busdc_i busac_i type_dc type_ac P_g   Q_g  islcc  Vtar    rtf   xtf  transformer tm   bf 	filter    rc     xc  reactor   basekVac Vmmax   Vmmin   Imax    status   LossA LossB  LossCrec LossCinv  droop     Pdcset    Vdcset  dVdcset Pacmax Pacmin Qacmax Qacmin cost
	mpc.convdc_ne = [
	                1000       2      1       1    400000    0   	0     1.0   0.001  0.1       0 			 1 	0.08 		0 		0.001   0.09 		0  				220    1.1     0.9    100000      1     	 0     0        0       0      0.0050    -52.7     1.0079     0  		1  -1   1    -1   1000000;
	];")
end


function ppf_storage(mf,r_df)
	println(mf, " % hours
	 mpc.time_elapsed = 1.0

	 %% storage data
	 % storage_bus   ps   qs energy energy_rating charge_rating discharge_rating charge_efficiency discharge_efficiency thermal_rating    qmin   qmax    r    x p_loss q_loss status
	 mpc.storage = [")
	 	for r in r_df[!,:storage]
			if !(ismissing(r))
			#println(r)
 	   		println(mf,r);end
    	end
	println(mf,"];")



	println(mf, "%% cost 36.6
	 %% storage additional data
	 %column_names% max_energy_absorption stationary_energy_inflow stationary_energy_outflow self_discharge_rate cost
	 mpc.storage_extra = [")
		 for r in r_df[!,:storage_extra]
			if !(ismissing(r))
				#println(r)
			 println(mf,r);end
		 end
	 println(mf,"];")

	 println(mf, "%% storage data
	 %column_names%   storage_bus ps 	qs 	energy  energy_rating charge_rating  discharge_rating  charge_efficiency  discharge_efficiency  thermal_rating  qmin  	qmax  	r  		x  p_loss  	q_loss  status eq_cost inst_cost co2_cost 	max_energy_absorption 	stationary_energy_inflow 	stationary_energy_outflow 	self_discharge_rate	 	cost_abs 	cost_inj on_off
	 mpc.ne_storage = [
	 1	 0.0 0.0 0.0 6400.0	1280.0 1600.0 0.9 0.9 16000	-3200.0	4480.0 0.1 0.0 0.0	0.0	 0 	100000 	100000	100000 	32000000 0 	0 1e-4 0 0 1;
	 											 											];")
end















