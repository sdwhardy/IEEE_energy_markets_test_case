################## loads external packages ##############################
using XLSX, Gurobi, JuMP, DataFrames, FileIO, CSV, Dates, OrderedCollections, PlotlyJS
import IEEE_energy_markets_test_case; const _CBD = IEEE_energy_markets_test_case#Cordoba package backend - under development
import PowerModelsACDC; const _PMACDC = PowerModelsACDC
import PowerModels; const _PM = PowerModels
##################### File parameters #################################
include("script_functions.jl")


s = Dict(
    "rt_ex"=>pwd()*"\\test\\data\\test_cases\\Yuso\\",#folder path if directly
    "scenario_data_file"=>"C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\scenario_data_4EU.jld2",
    ################# temperal parameters #################
    "test"=>false,#if true smallest (2 hour) problem variation is built for testing
    "scenario_planning_horizon"=>30,
    "scenario_names"=>["NT2030"],#["NT","DE","GA"]#,"NT2030","NT2040","DE2030","DE2040","GA2030","GA2040"
    "k"=>365,#number of representative days modelled (24 hours per day)//#best for maintaining mean/max is k=6 2014, 2015
    "res_years"=>["2016"],#Options: ["2012","2013","2014","2015","2016"]//#best for maintaining mean/max is k=6 2014, 2015
    "scenario_years"=>["2030"],#Options: ["2020","2030","2040"]
    "dr"=>0.04,#discount rate
    "yearly_investment"=>10000000,
    ################ electrical parameters ################
    "conv_lim_onshore"=>36000,#Max Converter size in MVA
    "conv_lim_offshore"=>36000,#Max Converter size in MVA
    "strg_lim_offshore"=>0.2,
    "strg_lim_onshore"=>10,
    "candidate_ics_ac"=>[1],#AC Candidate Cable sizes (fraction of full MVA)
    "candidate_ics_dc"=>[1],#DC Candidate Cable sizes (fraction of full MVA)[1,4/5,3/5,2/5]
    ################## optimization/solver setup options ###################
    "relax_problem" => false,
    "corridor_limit" => false,
    "TimeLimit" => 320000,
    "MIPGap"=>1e-4, 
    "PoolSearchMode" => 0, 
    "PoolSolutions" => 1,
    "ntc_mva_scale" => 1.0)
    
    s=_CBD.hidden_settings(s)

    scenario_data = get_scenario_data4YUSO(s,["NS"])#scenario time series
    
    scenario_data = reduce_grid_size_4YUSO(scenario_data)
    
    scenario_data = reduce_toRegions4YUSO(scenario_data)#scenario time series

    push!(scenario_data["Generation"]["Scenarios"]["NT2030"]["BE00"],["Nuclear",3500.0])
    
    data, s = _CBD.get_topology_data(s, scenario_data)#topology.m file
   
    ########## untested
    _CBD.reduce_nonstoch_gens(scenario_data)
    
	all_gens,s = _CBD.gen_types(data,scenario_data,s)
    
    #################### Calculates cable options for AC lines
    data = _CBD.AC_cable_options(data,s)
    
    #################### Calculates cable options for DC lines
    data = _CBD.DC_cable_options(data,s["candidate_ics_dc"],s["ics_dc"],data["baseMVA"])
    
    data["ne_branch"]["1"]["construction_cost"]=0.0
    
    data["branchdc_ne"]["1"]["cost"]=0.0
    
    data["branchdc_ne"]["2"]["cost"]=0.0

    data["branchdc_ne"]["3"]["cost"]=0.0
    
    data["convdc"]["1"]["cost"]=0.0
    
    data["convdc"]["2"]["cost"]=0.0
    
    data["convdc"]["3"]["cost"]=0.0

    data["convdc"]["4"]["cost"]=0.0
    
    data["convdc"]["5"]["cost"]=0.0
    
    for i in 1:1:5
    
        data["storage"][string(i)]["cost"]=1000000.0
    
    end
    
    _CBD.additional_params_PMACDC(data)
    
    _CBD.print_topology_data_AC(data,s["map_gen_types"]["markets"])#print to verify
    
    _CBD.print_topology_data_DC(data,s["map_gen_types"]["markets"])#print to verify
    
    ##################### load time series data ##############################
    scenario_data = _CBD.load_time_series_gentypes(s, scenario_data)
    ##################### multi period setup #################################
	s = _CBD.update_settings_wgenz(s, data)
    
    mn_data, s  = _CBD.multi_period_setup_wgen_type(scenario_data, data, all_gens, s);
    
    EI_wind=DataFrames.DataFrame(XLSX.readtable(pwd()*"\\test\\data\\test_cases\\Yuso\\2016\\corres\\P2016.xlsx", "P"))
    
    s["xd"]["gen"]["1"]["pmax"]=Float64.(EI_wind[!,:OWPP95_12])'
    

	push!(s,"max_invest_per_year"=>_CBD.max_invest_per_year(s))
    
    gurobi = JuMP.optimizer_with_attributes(Gurobi.Optimizer,"OutputFlag" => 1, "TimeLimit" => s["TimeLimit"], "MIPGap"=>s["MIPGap"], "PoolSearchMode" => s["PoolSearchMode"], "PoolSolutions" => s["PoolSolutions"])#, "MIPGap"=>9e-3)#select solver
    
    jump_result_mip =  _CBD.cordoba_acdc_wf_split(mn_data, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s);
    
    result_mip_ms=_CBD.run_model_p2(jump_result_mip, gurobi);
   
    gurobi = JuMP.optimizer_with_attributes(Gurobi.Optimizer,"OutputFlag" => 1)#select solver
    
    s["rebalancing"]=true
    
    s["relax_problem"]=true
    
    s["output"]["duals"]=true
    
    results=Dict{String, Any}();
    
    _k="1"; _v=result_mip_ms["solution"][_k]
    
    result_mip2=Dict{String,Any}("solution"=>Dict{String,Any}("nw"=>_v))

    result_mip2_copy=deepcopy(result_mip2)
    
    mn_data, data, s2 = data_update_4YUSO(deepcopy(s),result_mip2,["NS"]);#Build data structure for given options
    
    EI_wind=DataFrames.DataFrame(XLSX.readtable(pwd()*"\\test\\data\\test_cases\\Yuso\\2016\\corres\\P2016.xlsx", "P"))
    
    s2["xd"]["gen"]["1"]["pmax"]=Float64.(EI_wind[!,:OWPP95_12])'

    mn_data, s2 = _CBD.set_rebalancing_grid(result_mip2,mn_data,s2);
    
    s2, mn_data= _CBD.remove_integers(result_mip2,mn_data,data,s2);
    
    result_mip =  _CBD.cordoba_acdc_wf_strg(mn_data, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s2)#Solve problem=#
    
    push!(results,_k=>Dict("result_mip"=>result_mip,"data"=>data, "mn_data"=>mn_data, "s"=>s2, "result_mip2"=>result_mip2));
   
    FileIO.save(pwd()*"\\test\\data\\test_cases\\Yuso\\2016\\results\\YUSO_wNuclear2030.jld2",results)
   