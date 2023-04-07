################## loads external packages ##############################
using Gurobi, JuMP, DataFrames, FileIO, CSV, Dates, OrderedCollections, PlotlyJS
import IEEE_energy_markets_test_case; const _CBD = IEEE_energy_markets_test_case#Cordoba package backend - under development
import PowerModelsACDC; const _PMACDC = PowerModelsACDC
import PowerModels; const _PM = PowerModels
##################### File parameters #################################

function main_setup()
    s = Dict(
    "rt_ex"=>pwd()*"\\data\\test_cases\\test\\",#folder path
    "scenario_data_file"=>pwd()*"\\data\\input\\scenario_data_for_UKFRBENLDEDKNO.jld2",#"C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\scenario_data_for_UKFRBENLDEDKNO.jld2",
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
    "owpp_mva"=>[4000,4000,6000,6000,8000],#mva of wf in MVA
    "conv_lim_onshore"=>3000,#Max Converter size in MVA
    "conv_lim_offshore"=>4000,#Max Converter size in MVA
    "strg_lim_offshore"=>0.2,
    "strg_lim_onshore"=>10,
    "candidate_ics_ac"=>[1,3/5],#AC Candidate Cable sizes (fraction of full MVA)
    "candidate_ics_dc"=>[1,3/5],#DC Candidate Cable sizes (fraction of full MVA)[1,4/5,3/5,2/5]
    ################## optimization/solver setup options ###################
    "output" => Dict("branch_flows" => false),
    "eps"=>0.0001,#admm residual (100kW)
    "beta"=>5.5,
    "relax_problem" => false,
    "conv_losses_mp" => true,
    "process_data_internally" => false,
    "corridor_limit" => true,
    "onshore_grid"=>true)

    ################## Run MIP Formulation ###################
    #NOTE only very basic intuitive check passed on functions wgen_type
    s["home_market"]=[]
    mn_data, data, s = _CBD.data_setup_nodal(s);
    _CBD.print_mn_data(mn_data,s)

    a=mn_data["nw"]["1"]["ne_branch"]["1"]["br_r"]
    b=mn_data["nw"]["1"]["branchdc_ne"]["11"]["rateB"]
    c=mn_data["nw"]["1"]["branchdc"]["5"]["index"]
    d=mn_data["nw"]["1"]["branch"]["1"]["cost"]
    e=mn_data["nw"]["1"]["convdc"]["23"]["Pacmax"]

    f=last(s["xd"]["ne_branch"]["2"]["construction_cost"])
    g=last(s["xd"]["branchdc_ne"]["7"]["cost"])
    h=last(s["xd"]["branchdc"]["6"]["r"])
    i=last(s["xd"]["branch"]["1"]["br_x"])
    j=last(s["xd"]["convdc"]["15"]["Pacmax"])
    return a+b+c+d+e+f+g+h+i+j
end