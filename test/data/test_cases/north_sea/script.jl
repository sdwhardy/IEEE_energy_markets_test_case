################## loads external packages ##############################
using XLSX, Gurobi, JuMP, DataFrames, FileIO, CSV, Dates, OrderedCollections, PlotlyJS
import IEEE_energy_markets_test_case; const _CBD = IEEE_energy_markets_test_case#Cordoba package backend - under development
import PowerModelsACDC; const _PMACDC = PowerModelsACDC
import PowerModels; const _PM = PowerModels
##################### File parameters #################################

s = Dict(
    "rt_ex"=>pwd()*"\\test\\data\\test_cases\\north_sea\\",#folder path if directly
    "scenario_data_file"=>"C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\scenario_data_4EU.jld2",
    ################# temperal parameters #################
    "test"=>true,#if true smallest (2 hour) problem variation is built for testing
    "scenario_planning_horizon"=>30,
    "scenario_names"=>["NT2025","NT2030","NT2040"],#"DE2030","DE2040","GA2030","GA2040"],#["NT","DE","GA"]#,"NT2030","NT2040","DE2030","DE2040","GA2030","GA2040"
    "k"=>4,#number of representative days modelled (24 hours per day)//#best for maintaining mean/max is k=6 2014, 2015
    "res_years"=>["2014"],#"2015"],#Options: ["2012","2013","2014","2015","2016"]//#best for maintaining mean/max is k=6 2014, 2015
    "scenario_years"=>["2020","2030","2040"],#Options: ["2020","2030","2040"]
    "dr"=>0.04,#discount rate
    "yearly_investment"=>10000000,
    "clustered"=>true,
    ################ electrical parameters ################
    "conv_lim_onshore"=>36000,#Max Converter size in MVA
    "conv_lim_offshore"=>36000,#Max Converter size in MVA
    "strg_lim_offshore"=>0.2,
    "strg_lim_onshore"=>10,
    "candidate_ics_ac"=>[1,2],#4,8],#AC Candidate Cable sizes (fraction of full MVA)
    "candidate_ics_dc"=>[1,2],#4,8],#DC Candidate Cable sizes (fraction of full MVA)[1,4/5,3/5,2/5]
    ################## optimization/solver setup options ###################
    "relax_problem" => false,
    "corridor_limit" => false,
    "TimeLimit" => 1800,
    "MIPGap"=>2e-3,#0.2% 
    "PoolSearchMode" => 0, 
    "PoolSolutions" => 1,
    "ntc_mva_scale" => 1.0)
    s=_CBD.hidden_settings(s)
   
######################### Nodal market #########################
s["home_market"]=[]
mn_data, data, s = _CBD.data_setup(s);
#_CBD.problemINPUT_mapNTCs(data, s)
#_CBD.problemINPUT_map(data, s)
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








