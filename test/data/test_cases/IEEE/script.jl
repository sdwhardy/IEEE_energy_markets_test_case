################## loads external packages ##############################
using Gurobi, JuMP, DataFrames, FileIO, CSV, Dates, OrderedCollections, PlotlyJS
import IEEE_energy_markets_test_case; const _CBD = IEEE_energy_markets_test_case#Cordoba package backend - under development
import PowerModelsACDC; const _PMACDC = PowerModelsACDC
import PowerModels; const _PM = PowerModels
##################### File parameters #################################

s = Dict(
"rt_ex"=>pwd()*"\\test\\data\\test_cases\\IEEE\\",#folder path
"scenario_data_file"=>pwd()*"\\test\\data\\input\\scenario_data_for_UKFRBENLDEDKNO.jld2",#"C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\scenario_data_for_UKFRBENLDEDKNO.jld2",
################# temperal parameters #################
"test"=>false,#if true smallest (2 hour) problem variation is built for testing
"scenario_planning_horizon"=>30,
"scenario_names"=>["NT","DE","GA"],#["NT","DE","GA"]
"k"=>4,#number of representative days modelled (24 hours per day)//#best for maintaining mean/max is k=6 2014, 2015
"res_years"=>["2014","2015"],#Options: ["2012","2013","2014","2015","2016"]//#best for maintaining mean/max is k=6 2014, 2015
"scenario_years"=>["2020","2030","2040"],#Options: ["2020","2030","2040"]
"dr"=>0.04,#discount rate
"yearly_investment"=>1000000,
################ electrical parameters ################
"AC"=>"1",#0=false, 1=true
"owpp_mva"=>[4000,4000,4000,4000,4000],#mva of wf in MVA
"conv_lim_onshore"=>3000,#Max Converter size in MVA
"conv_lim_offshore"=>4000,#Max Converter size in MVA
"strg_lim_offshore"=>0.2,
"strg_lim_onshore"=>10,
"candidate_ics_ac"=>[1,4/5,3/5],#AC Candidate Cable sizes (fraction of full MVA)
"candidate_ics_dc"=>[1,4/5,3/5],#DC Candidate Cable sizes (fraction of full MVA)[1,4/5,3/5,2/5]
################## optimization/solver setup options ###################
"output" => Dict("branch_flows" => false),
"eps"=>0.0001,#admm residual (100kW)
"beta"=>5.5,
"relax_problem" => false,
"conv_losses_mp" => true,
"process_data_internally" => false,
"corridor_limit" => true,
"onshore_grid"=>true)


######################### Nodal OBZ #########################
s["home_market"]=[]
mn_data, data, s = _CBD.data_setup(s);
#_CBD.problemINPUT_map(data, s)#oucomment to print result
@time result = _CBD.nodal_market_main(mn_data, data, s)#0.04% gap remained for best solution found
result["s"]["cost_summary"]=_CBD.print_solution_wcost_data(result["result_mip"], result["s"], result["data"])

######################### HMD market #########################
s["home_market"]=[[4,11],[5,10],[6,12],[1,8,13],[3,9]]
mn_data, data, s = _CBD.data_setup(s);
@time result = _CBD.zonal_market_main(mn_data, data, s)
result["s"]["cost_summary"]=_CBD.print_solution_wcost_data(result["result_mip"], result["s"], result["data"])

######################### Zonal OBZ #########################
s["home_market"]=[[9,10,11,12,13]]
mn_data, data, s = _CBD.data_setup(s);
@time result = _CBD.zonal_market_main(mn_data, data, s)
result["s"]["cost_summary"]=_CBD.print_solution_wcost_data(result["result_mip"], result["s"], result["data"])

