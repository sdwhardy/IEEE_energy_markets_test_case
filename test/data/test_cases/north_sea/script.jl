################## loads external packages ##############################
using Gurobi, JuMP, DataFrames, FileIO, CSV, Dates, OrderedCollections, PlotlyJS, XLSX
import Cordoba_self; const _CBD = Cordoba_self#Cordoba package backend - under development
import PowerModelsACDC; const _PMACDC = PowerModelsACDC
import PowerModels; const _PM = PowerModels
##################### File parameters #################################

s = Dict(
    "rt_ex"=>pwd()*"\\test\\data\\input\\north_sea\\",#folder path if directly
    "scenario_data_file"=>"C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\scenario_data_4EU.jld2",
    ################# temperal parameters #################
    "test"=>true,#if true smallest (2 hour) problem variation is built for testing
    "scenario_planning_horizon"=>30,
    "scenario_names"=>["NT2025","NT2030","NT2040","DE2030","DE2040","GA2030","GA2040"],#["NT","DE","GA"]#,"NT2030","NT2040","DE2030","DE2040","GA2030","GA2040"
    "k"=>4,#number of representative days modelled (24 hours per day)//#best for maintaining mean/max is k=6 2014, 2015
    "res_years"=>["2014","2015"],#Options: ["2012","2013","2014","2015","2016"]//#best for maintaining mean/max is k=6 2014, 2015
    "scenario_years"=>["2020","2030","2040"],#Options: ["2020","2030","2040"]
    "dr"=>0.04,#discount rate
    "yearly_investment"=>10000000,
    "clustered"=>true,
    ################ electrical parameters ################
    "conv_lim_onshore"=>36000,#Max Converter size in MVA
    "conv_lim_offshore"=>36000,#Max Converter size in MVA
    "strg_lim_offshore"=>0.2,
    "strg_lim_onshore"=>10,
    "candidate_ics_ac"=>[1,2,4,8],#AC Candidate Cable sizes (fraction of full MVA)
    "candidate_ics_dc"=>[1,2,4,8],#DC Candidate Cable sizes (fraction of full MVA)[1,4/5,3/5,2/5]
    ################## optimization/solver setup options ###################
    "relax_problem" => false,
    "corridor_limit" => false,
    "TimeLimit" => 45000,
    "MIPGap"=>1e-4, 
    "PoolSearchMode" => 0, 
    "PoolSolutions" => 1,
    "ntc_mva_scale" => 1.0)
    s=_CBD.hidden_settings(s)
   
######################### Nodal market #########################
s["home_market"]=[]
mn_data, data, s = _CBD.data_setup(s);
_CBD.problemINPUT_mapNTCs(data, s)
_CBD.problemINPUT_map(data, s)
@time result = _CBD.nodal_market_main(mn_data, data, s)#-3359431 -33899162 0.89%
FileIO.save("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\NORTH_SEA_nodal_k4_full_4STEPs_1200MW.jld2",result)#09gap was good one

result["1"]
######################### Zonal market #########################
#s["home_market"]=[[2,5],[3,6],[4,7]]
#s["home_market"]=[[9,10,11,12,13]]
s["home_market"]=[[16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31]]
mn_data, data, s = _CBD.data_setup(s);
@time result = _CBD.zonal_market_main(mn_data, data, s)#-3359431 -33899162 0.89%
FileIO.save("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\NORTH_SEA_nodal_k4_full_zOBZ.jld2",result)

#=
6444 binary->426 binary
Optimal solution found (tolerance 1.00e-04)
Best objective -8.412264555550e+06, best bound -8.412870390337e+06, gap 0.0072%

6444 binary->468 binary
Optimal solution found (tolerance 1.00e-04)
Best objective -8.364509426726e+06, best bound -8.364632938305e+06, gap 0.0015%

Optimal objective -8.371519331e+06
Optimal objective -8.371099410e+06
=#


function data_setup_septmeeting(s)
    scenario_data = _CBD.get_scenario_data(s)#scenario time series
    data, s = _CBD.get_topology_data(s, scenario_data)#topology.m file
    scenario_data=_CBD.freeze_offshore_expansion(s["nodes"], scenario_data)
    ########## untested
    _CBD.reduce_nonstoch_gens(scenario_data)
    ##########
	###########################################################################
	all_gens,s = _CBD.gen_types(data,scenario_data,s)
    if (haskey(s,"collection_circuit") && s["collection_circuit"]==true)
        #################### Calculates cable options for collection circuit AC lines
        data = _CBD.AC_cable_options_collection(scenario_data,data,s)
        #################### Calculates cable options for collection circuit DC lines
        data = _CBD.DC_cable_options_collection(scenario_data,data,s)
    else
        #################### Calculates cable options for AC lines
        data = _CBD.AC_cable_options(data,s)
        #################### Calculates cable options for DC lines
        data = _CBD.DC_cable_options(data,s["candidate_ics_dc"],s["ics_dc"],data["baseMVA"])
    end
    if (haskey(s, "home_market") && length(s["home_market"])>0);data = _CBD.keep_only_hm_cables(s,data);end#if home market reduce to only those in
    _CBD.additional_params_PMACDC(data)
    _CBD.print_topology_data_AC(data,s["map_gen_types"]["markets"])#print to verify
    _CBD.print_topology_data_DC(data,s["map_gen_types"]["markets"])#print to verify
    ##################### load time series data ##############################
    scenario_data = _CBD.load_time_series_gentypes(s, scenario_data)
    ##################### multi period setup #################################
	s = _CBD.update_settings_wgenz(s, data)
    mn_data, s  = multi_period_setup_wgen_type(scenario_data, data, all_gens, s);
	push!(s,"max_invest_per_year"=>_CBD.max_invest_per_year(s))
    ####################### WTACH OUT if  s["scenarios_length"]=6 is hared coded onlyt works with 6 scenarios!!!
    s["scenarios_length"]=6
    return  mn_data, data, s
end
[println(maximum(scenario_data["Generation"]["RES"]["Offshore Wind"][k0][k1][!,Symbol(k0)])) for k0 in keys(scenario_data["Generation"]["RES"]["Offshore Wind"]) for k1 in keys(scenario_data["Generation"]["RES"]["Offshore Wind"][k0])]

scenario_data["Generation"]["RES"]["Offshore Wind"]["BE00"]["2015"] 
function load_time_series_gentypes(s, scenario_data)
	#keeps data from specified scenarios only
    scenario_data["Generation"]["Scenarios"]=reduce_to_scenario_list(scenario_data["Generation"]["Scenarios"],s);
    scenario_data["Demand"]=reduce_to_scenario_list(scenario_data["Demand"],s);
    #Keep only specified markets
	countries=unique(vcat(s["map_gen_types"]["markets"][1],s["map_gen_types"]["markets"][2]));
    #scenario_data=reduce_to_market_list(scenario_data,countries);
    #keep only specified weather years
    scenario_data=reduce_to_weather_year_list(scenario_data,s);
    #keep only k specified days
    scenario_data["Generation"]["RES"], tss2keep = reduce_RES_to_k_days(scenario_data["Generation"]["RES"],s);
    scenario_data["Demand"]=reduce_DEMAND_to_k_days(scenario_data["Demand"],countries,tss2keep);
    #record number of hours
    country=first(keys(scenario_data["Generation"]["RES"]["Offshore Wind"]))
    year=first(keys(scenario_data["Generation"]["RES"]["Offshore Wind"][country]))
    s["hours_length"] = length(scenario_data["Generation"]["RES"]["Offshore Wind"][country][year].time_stamp)
	return scenario_data
end

################################### Clustering ##################################
demand2050=(sum.(eachrow(scenario_data["Demand"]["DE2040"][!,Not(Symbol("time_stamp"))])).+sum.(eachrow(scenario_data["Demand"]["GA2040"][!,Not(Symbol("time_stamp"))])).+sum.(eachrow(scenario_data["Demand"]["NT2040"][!,Not(Symbol("time_stamp"))])))./3
demand2050=sum.(eachrow(scenario_data["Demand"]["DE2040"][!,Not(Symbol("time_stamp"))]))
res="Offshore Wind"
year="2014"
country="BE00"

net_res=scenario_data["Generation"]["RES"][res][country][year][!,Symbol(country)].*0
count=0
for res in ["Offshore Wind"]#keys(scenario_data["Generation"]["RES"])
    for country in keys(scenario_data["Generation"]["RES"][res])
        for year in ["2014"]
            if !(isempty(scenario_data["Generation"]["RES"][res][country]))
                count=count+1
                net_res=net_res+scenario_data["Generation"]["RES"][res][country][year][!,Symbol(country)]
            end
        end
    end
end
net_res=net_res/count

using Plots, Clustering, PlotlyJS

df=DataFrame("time_stamp"=>scenario_data["Generation"]["RES"][res][country][year][!,Symbol("time_stamp")],"res"=>net_res,"demand"=>demand2050,"ratio"=>demand2050./net_res)
X=vcat(df[!,:res]',df[!,:demand]')
R=kmeans(X,2;maxiter=200,display=:iter)

a=assignments(R)


every=Array{GenericTrace{Dict{Symbol,Any}},1}()
for t in 1:1:4
cluster_1 = PlotlyJS.scatter(;x=[df[!,:demand][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]>0.35)], y=[df[!,:res][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]>0.35)], mode="markers")#, marker_color="red")#,text=[k for (k,v) in map["busac_i"]])
push!(every, cluster_1)
end

for t in 1:1:4
    cluster_2 = PlotlyJS.scatter(;x=[df[!,:demand][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]<=0.35)], y=[df[!,:res][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]<=0.35)], mode="markers")#, marker_color="red")#,text=[k for (k,v) in map["busac_i"]])
    push!(every, cluster_2)
    end


PlotlyJS.plot(every)

every=Array{GenericTrace{Dict{Symbol,Any}},1}()
for t in 1:1:4
cluster_1 = PlotlyJS.scatter(;x=[df[!,:demand][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]>0.275)], y=[df[!,:res][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]>0.275)], mode="markers+text",text=[df[!,:time_stamp][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]>0.275)])#, marker_color="red")#,text=[k for (k,v) in map["busac_i"]])
push!(every, cluster_1)
end

for t in 1:1:4
    cluster_2 = PlotlyJS.scatter(;x=[df[!,:demand][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]<=0.275)], y=[df[!,:res][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]<=0.275)], mode="markers+text",text=[df[!,:time_stamp][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]<=0.275)])#, marker_color="red")#,text=[k for (k,v) in map["busac_i"]])
    push!(every, cluster_2)
    end


PlotlyJS.plot(every)



