################## loads external packages ##############################
using Gurobi, JuMP, DataFrames, FileIO, CSV, Dates, PlotlyJS
import IEEE_energy_markets_test_case; const _CBD = IEEE_energy_markets_test_case#Cordoba package backend - under development
import PowerModelsACDC; const _PMACDC = PowerModelsACDC
import PowerModels; const _PM = PowerModels
using OrderedCollections

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
   
#################################### map output #######################
############################## newest #################################
results=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\NORTH_SEA_nodal_k4_full_4STEPs.jld2")

result=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\NORTH_SEA_nodal_k4_full.jld2")#09gap was good one
results=result

#top1=string(last(first(results["1"]["s"]["scenario"]["sc_names"]))["2020"][1])
#top2=string(last(first(results["1"]["s"]["scenario"]["sc_names"]))["2030"][1])
#top3=string(last(first(results["1"]["s"]["scenario"]["sc_names"]))["2040"][1])
top1=string(last(first(result["s"]["scenario"]["sc_names"]))["2020"][1])
top2=string(last(first(result["s"]["scenario"]["sc_names"]))["2030"][1])
top3=string(last(first(result["s"]["scenario"]["sc_names"]))["2040"][1])
tops=[top1,top2,top3]

gurobi = JuMP.optimizer_with_attributes(Gurobi.Optimizer,"OutputFlag" => 1)#select solver
#_v=results["1"]["result_mip2"]["solution"]["nw"]
_v=result["result_mip2"]["solution"]["nw"]
s["rebalancing"]=true
s["relax_problem"]=true
s["output"]["duals"]=true
results=Dict{String, Any}();

result_mip2=Dict{String,Any}("solution"=>Dict{String,Any}("nw"=>_v))
mn_data, data, s2 = _CBD.data_update(deepcopy(s),result_mip2);#Build data structure for given options

mn_data, s2 = set_rebalancing_grid(result_mip2,mn_data,s2, tops);
s2, mn_data= remove_integers(result_mip2,mn_data,data,s2, tops);


result_mip =  _CBD.cordoba_acdc_wf_strg(mn_data, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s2)#Solve problem=#
push!(results,"1"=>Dict("result_mip"=>result_mip,"data"=>data, "mn_data"=>mn_data, "s"=>s2, "result_mip2"=>result_mip2));
FileIO.save("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\NORTH_SEA_nodal_k4_full_4STEPs_nOBZ_reduced.jld2",results)
  

function remove_integers(result_mip,mn_data,data,s, tops)
    for (i_sc, scn) in (s["scenario"]["sc_names"])
        println("I_sc ", i_sc)
        for (i_yr, tss) in scn
            println("i_yr ", i_yr)
            if (i_yr=="2020")
                t_ts=tops[1]
            elseif (i_yr=="2030")
                t_ts=tops[2]
            else
                t_ts=tops[3]
            end
            #println(tss)

            for ts in sort(tss)
                println("ts ", ts)
                for (bc,brc) in data["branchdc"]
                    s["xd"]["branchdc"][bc]["rateA"][1,ts]=0.0
                    s["xd"]["branchdc"][bc]["r"][1,ts]=0.0
                end;

                #dc cables
                for (b,br) in result_mip["solution"]["nw"][t_ts]["branchdc_ne"];
                    if (br["isbuilt"]>0.9)
                        for (bc,brc) in data["branchdc"]
                           
                            if (brc["fbusdc"]==data["branchdc_ne"][b]["fbusdc"] && brc["tbusdc"]==data["branchdc_ne"][b]["tbusdc"])                           
                                s["xd"]["branchdc"][bc]["rateA"][1,ts]=s["xd"]["branchdc"][bc]["rateA"][1,ts]+data["branchdc_ne"][b]["rateA"]
                                s["xd"]["branchdc"][bc]["cost"][1,ts]=0.0;
                                if (s["xd"]["branchdc"][bc]["r"][1,ts]>0.0)
                                    s["xd"]["branchdc"][bc]["r"][1,ts]=1/((1/s["xd"]["branchdc"][bc]["r"][1,ts]) + (1/data["branchdc_ne"][b]["r"]))
                                else
                                    s["xd"]["branchdc"][bc]["r"][1,ts]=data["branchdc_ne"][b]["r"]
                                end                    
                            end
                        end;
                    end;
                end
            
                #ac cables
                if (haskey(result_mip["solution"]["nw"][t_ts],"ne_branch"))
                    for (bc,brc) in data["branch"]
                        s["xd"]["branch"][bc]["rateA"][1,ts]=0.0;
                    end
                    for (b,br) in result_mip["solution"]["nw"][t_ts]["ne_branch"];
                        if (br["built"]>0.9)                 
                            for (bc,brc) in data["branch"]
                                if (brc["f_bus"]==data["ne_branch"][b]["f_bus"] && brc["t_bus"]==data["ne_branch"][b]["t_bus"])    
                            
                                    s["xd"]["branch"][bc]["rateA"][1,ts]=s["xd"]["branch"][bc]["rateA"][1,ts]+data["ne_branch"][b]["rate_a"]
                                    s["xd"]["branch"][bc]["cost"][1,ts]=0.0;
                                    if (s["xd"]["branch"][bc]["br_r"][1,ts]>0.0)
                                        s["xd"]["branch"][bc]["br_r"][1,ts]=1/((1/s["xd"]["branch"][bc]["br_r"][1,ts])+(1/data["ne_branch"][b]["br_r"]))
                                    else
                                        s["xd"]["branch"][bc]["br_r"][1,ts]=data["ne_branch"][b]["br_r"]
                                    end
                                end
                            end;
                        end;
                    end;
                end
            end
        end;
    end
    return s, mn_data
end
#=
function set_rebalancing_grid(result_mip,mn_data,s, tops)
    for (i_sc, scn) in (s["scenario"]["sc_names"])
        for (i_yr, tss) in scn
            if (i_yr=="2020")
                t_ts=tops[1]
            elseif (i_yr=="2030")
                t_ts=tops[2]
            else
                t_ts=tops[3]
            end
            #println(tss)
            for ts in sort(tss)
                #dc cables
                for (b,br) in result_mip["solution"]["nw"][t_ts]["branchdc_ne"];
                    if (br["isbuilt"]>0.9)
                            s["xd"]["branchdc_ne"][b]["cost"][1,ts]=0.0;
                    end
                end;
    
                #ac cables
                if (haskey(result_mip["solution"]["nw"][t_ts],"ne_branch"))
                    for (b,br) in result_mip["solution"]["nw"][t_ts]["ne_branch"];
                        if (br["built"]>0.9)
                                s["xd"]["ne_branch"][b]["construction_cost"][1,ts]=0.0;
                        end;
                    end;
                end
                #converters
                if (haskey(result_mip["solution"]["nw"][t_ts],"convdc"))
                    for (c,cnv) in result_mip["solution"]["nw"][t_ts]["convdc"];
                        if (cnv["p_pacmax"]>0)
                                s["xd"]["convdc"][c]["Pacmin"][1,ts]=round(cnv["p_pacmax"],digits = 6);
                                s["xd"]["convdc"][c]["Pacmax"][1,ts]=round(cnv["p_pacmax"],digits = 6);
                        else
                                s["xd"]["convdc"][c]["Pacmin"][1,ts]=0;
                                s["xd"]["convdc"][c]["Pacmax"][1,ts]=0;
                        end;
                    end;
                end
                #storage
                if (haskey(result_mip["solution"]["nw"][t_ts],"storage"))
                    for (b,strg) in result_mip["solution"]["nw"][t_ts]["storage"];
                        if (strg["e_absmax"]>0)
                                s["xd"]["storage"][b]["pmin"][1,ts]=round(strg["e_absmax"],digits = 6);
                                s["xd"]["storage"][b]["pmax"][1,ts]=round(strg["e_absmax"],digits = 6);
                        else
                                s["xd"]["storage"][b]["pmin"][1,ts]=0;
                                s["xd"]["storage"][b]["pmax"][1,ts]=0;
                        end;
                    end;
                end
                for wf in s["wfz"]
                    s["xd"]["gen"][string(first(wf))]["wf_pmax"][1,ts]=round(result_mip["solution"]["nw"][t_ts]["gen"][string(first(wf))]["wf_pacmax"],digits = 6);
                end;
        
            end;
            #end
        end
    end
    return mn_data, s
end
    =#