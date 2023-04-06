################## loads external packages ##############################
using Gurobi, JuMP, DataFrames, FileIO, CSV, Dates, OrderedCollections, PlotlyJS
import Cordoba_self; const _CBD = Cordoba_self#Cordoba package backend - under development
import PowerModelsACDC; const _PMACDC = PowerModelsACDC
import PowerModels; const _PM = PowerModels
##################### File parameters #################################

s = Dict(
"rt_ex"=>pwd()*"\\test\\data\\input\\onshore_grid\\",#folder path
"scenario_data_file"=>"C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\scenario_data_for_UKFRBENLDEDKNO.jld2",
################# temperal parameters #################
"test"=>true,#if true smallest (2 hour) problem variation is built for testing
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

#[println(mn_data["nw"]["1"]["ne_branch"]["4"])["5"]["pt"]) for k=1:1:32]
######################### Nodal market #########################
s["home_market"]=[]
mn_data, data, s = _CBD.data_setup(s);
_CBD.problemINPUT_map(data, s)
@time result = _CBD.nodal_market_main(mn_data, data, s)#-3359431 -33899162 0.89%
result["s"]["cost_summary"]=_CBD.print_solution_wcost_data(result["result_mip"], result["s"], result["data"])
FileIO.save("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\nodal_market_NORTH_SEA_4G.jld2",result)#09gap was good one
######################### Zonal market #########################
#s["home_market"]=[[2,5],[3,6],[4,7]]
#s["home_market"]=[[9,10,11,12,13]]
s["home_market"]=[[4,11],[5,10],[6,12],[1,8,13],[3,9]]
mn_data, data, s = _CBD.data_setup(s);
@time result = _CBD.zonal_market_main(mn_data, data, s)#-3359431 -33899162 0.89%
FileIO.save("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\HMD_results_NORTH_SEA_4G.jld2",result)
##################### Post processing ##########################                               
results = FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\UK_BE_DE_DK\\zonalOBZ_results_NORTH_SEA_0gap.jld2")
s, result_mip, data, mn_data = _CBD.summarize_in_s(results);
s, result_mip, data, mn_data = _CBD.summarize_zonal_in_s(results);

_CBD.print_table_summary(s)

_CBD.topology_map(s)

_CBD.plot_cumulative_production_all_scenarios_allWF(s, mn_data)

_CBD.plot_cumulative_income_tl_all_scenarios(s,data)

_CBD.print_solution_wcost_data(result_mip, s, data)

for (k,c) in s["income_summary"]["tso"]["totals"]["ac"];println("AC("*k*"):"*string(c));end

for (k,c) in s["income_summary"]["tso"]["totals"]["dc"];println("DC("*k*"):"*string(c));end

country="DE";scenario="1"
con=s["gen_consume_summary"]["onshore_demand"][scenario][country]#[121:144,:]
gen=s["gen_consume_summary"]["onshore_generation"][scenario][country]
_CBD.plot_generation_profile(deepcopy(gen),deepcopy(con))

s=_CBD.owpps_profit_obz(s, result_mip, mn_data)

s=_CBD.transmission_lines_profits(s, result_mip, mn_data, data);

s=_CBD.undo_marginal_price_scaling(s, result_mip)

gen_consume_summary_nodal=_CBD.summarize_generator_solution_data(result_mip, data,s)#print SOLUTION

social_welfare = _CBD.SocialWelfare(s, result_mip, mn_data, data)

_CBD.plot_cumulative_production_all_scenarios_allWF(s, mn_data)

_CBD.plot_cumulative_income_all_scenarios_allWF(s, mn_data)

_CBD.plot_cumulative_income_tl_all_scenarios(s,data)

_CBD.plot_cumulative_wf_production_all_scenarios(s, mn_data, "DE")

_CBD.plot_cumulative_wf_income_all_scenarios(s, mn_data, "DK")

#_CBD.plot_dual_marginal_price(result_mip, keys(mn_data["scenario"][scenario]), (2,"BE"))




###########################################################################################################################
############### YUSO 
#Generation 
#=df=FileIO.load(s["scenario_data_file"])
scene="NT";year="2030";country="UK"
CSV.write("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\YUSO_data\\"*country*"_"*scene*year*"_ENERGY_MIX.csv", df["Generation"]["Scenarios"][scene][year][country])
#Demand
scene="Base";year="2020";country="UK"
CSV.write("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\YUSO_data\\"*country*"_BASE_DEMAND.csv", select(df["Demand"][scene][year],["time_stamp",country*"_MWh"]))
=###############
