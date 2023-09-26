################## loads external packages ##############################
using Gurobi, JuMP, DataFrames, FileIO, CSV, Dates, PlotlyJS
import Cordoba_self; const _CBD = Cordoba_self#Cordoba package backend - under development
import PowerModelsACDC; const _PMACDC = PowerModelsACDC
import PowerModels; const _PM = PowerModels
using OrderedCollections

#################################### map output #######################
############################## newest #################################
results_NT=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\nodal_market_NORTH_SEA_NTk4.jld2")
results_DE=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\NORTH_SEA_nodal_k4_DE.jld2")
results_GA=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\NORTH_SEA_nodal_k4_GA.jld2")

result=results
pdic=_CBD.problemOUTPUT_map_byTimeStep(result["1"])
PlotlyJS.plot(pdic["trace012"], pdic["layout"])

for (i, res) in result
    for (j,dc_br) in res["result_mip"]["solution"]["nw"]["9"]["branchdc"]
        if (dc_br["p_rateA"]>0.0)
            f_bus=0;t_bus=0;
            for (k,conv) in result[i]["data"]["convdc"]
                if (conv["busdc_i"] == res["data"]["branchdc"][j]["fbusdc"]) 
                    f_bus=conv["busac_i"];end
                if (conv["busdc_i"] == res["data"]["branchdc"][j]["tbusdc"]) 
                    t_bus=conv["busac_i"];end
            end
            println(j,": from ",f_bus," to ",t_bus," MVA: ",dc_br["p_rateA"])
        end
    end
end

for (i, res) in result
    for (j,dc_br) in res["result_mip"]["solution"]["nw"]["576"]["branch"]
        if (dc_br["p_rateAC"]>0.0)
        
            f_bus=res["data"]["branch"][j]["f_bus"]
                
            t_bus=res["data"]["branch"][j]["t_bus"]

            println(j,": from ",f_bus," to ",t_bus," MVA: ",dc_br["p_rateAC"])
        end
    end
end

######################################################################################################
results=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\NORTH_SEA_nodal_k4_full.jld2")

pdic=_CBD.problemOUTPUT_map_byTimeStep(result["1"])
PlotlyJS.plot(pdic["trace2"], pdic["layout"])

resultMIP=deepcopy(result)

resultMIP["1"]["result_mip"]=result["1"]["result_mip2"]["solution"]["nw"]
pdicmip=_CBD.problemMIP_OUTPUT_map_byTimeStep(resultMIP["1"])
PlotlyJS.plot(pdicmip["trace012"], pdicmip["layout"])

result["1"]["data"]["branchdc"]["42"]["branchdc"]
for i=1:1:1728 
println(i," ", result["1"]["result_mip"]["solution"]["nw"][string(i)]["branchdc"]["42"]["p_rateA"]," ", result["1"]["result_mip"]["solution"]["nw"][string(i)]["branchdc"]["42"]["pt"])
end
i=1728
for i=1:1:1728 
    println(i," ", result["1"]["result_mip"]["solution"]["nw"][string(i)]["gen"]["14"]["pg"])
end

for i=1:1:1728 
    println(i," ", result["1"]["result_mip"]["solution"]["nw"][string(i)]["convdc"]["29"]["p_pacmax"])
end
i=1
cbdc=[]
for i=1:1:1728
    for (c_i, cdc) in result["1"]["result_mip"]["solution"]["nw"][string(i)]["branchdc"]
        if (result["1"]["data"]["branchdc"][c_i]["fbusdc"]>31 && result["1"]["data"]["branchdc"][c_i]["tbusdc"]>31)
            if (isapprox(cdc["p_rateA"], cdc["pt"], atol=0.01))
                #println(c_i, " ", cdc["p_rateA"], " ", cdc["pt"], " ", result["1"]["data"]["branchdc"][c_i]["fbusdc"], " ", result["1"]["data"]["branchdc"][c_i]["tbusdc"])
                push!(cbdc, c_i)
            end
        end
    end
end


for c_i in cbdc
    fac=0;tac=0
    for (cv_i,cv) in result["1"]["data"]["convdc"]
        if (result["1"]["data"]["branchdc"][c_i]["fbusdc"]==cv["busdc_i"])
            fac=cv["busac_i"]
        end
        if (result["1"]["data"]["branchdc"][c_i]["tbusdc"]==cv["busdc_i"])
            tac=cv["busac_i"]
        end
    end
    println(c_i, " ", fac, " ", tac)
end


unique!(cbdc)


################################
#from previous work
################################

################## loads external packages ##############################
using Gurobi, JuMP, DataFrames, FileIO, CSV, Dates, PlotlyJS
import Cordoba_self; const _CBD = Cordoba_self#Cordoba package backend - under development
import PowerModelsACDC; const _PMACDC = PowerModelsACDC
import PowerModels; const _PM = PowerModels
using OrderedCollections

######################### nOBZ to HMD
results=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\nodal_market_NORTH_SEA_4G.jld2")
result_mip_n2z, data_n2z, mn_data_n2z, s_n2z, result_mip_hm_prices_n2z=_CBD.nodal2zonal(results["s"],results["result_mip"],[[4,11],[5,10],[6,12],[1,8,13],[3,9]]);
results_n2z=Dict("result_mip"=>result_mip_n2z,"data"=>data_n2z, "mn_data"=>mn_data_n2z, "s"=>s_n2z, "result_mip_hm_prices"=>result_mip_hm_prices_n2z)
FileIO.save("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\n2HMD_results_NORTH_SEA_4G.jld2",results_n2z)

######################### nOBZ to zOBZ
results=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\nodal_market_NORTH_SEA_4G.jld2")
result_mip_n2z, data_n2z, mn_data_n2z, s_n2z, result_mip_hm_prices_n2z=_CBD.nodal2zonal(results["s"],results["result_mip"],[[11,10,12,13,9]]);
results_n2z=Dict("result_mip"=>result_mip_n2z,"data"=>data_n2z, "mn_data"=>mn_data_n2z, "s"=>s_n2z, "result_mip_hm_prices"=>result_mip_hm_prices_n2z)
FileIO.save("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\n2zOBZ_results_NORTH_SEA_4G.jld2",results_n2z)

######################### HMD to nOBZ
results=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\HMD_results_NORTH_SEA_4G.jld2")
result_mip_n2z, data_n2z, mn_data_n2z, s_n2z=_CBD.zonal2nodal(results["s"],results["result_mip"]);
results_n2z=Dict("result_mip"=>result_mip_n2z,"data"=>data_n2z, "mn_data"=>mn_data_n2z, "s"=>s_n2z)
FileIO.save("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\HMD2nOBZ_results_NORTH_SEA_4G.jld2",results_n2z)

######################### zOBZ to nOBZ
results=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\zOBZ_results_NORTH_SEA_4G.jld2")
result_mip_n2z, data_n2z, mn_data_n2z, s_n2z=_CBD.zonal2nodal(results["s"],results["result_mip"]);
results_n2z=Dict("result_mip"=>result_mip_n2z,"data"=>data_n2z, "mn_data"=>mn_data_n2z, "s"=>s_n2z)
FileIO.save("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\zOBZ2nOBZ_results_NORTH_SEA_4G.jld2",results_n2z)

results=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\nodal_market_NORTH_SEA_4G.jld2")
results=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\HMD_results_NORTH_SEA_4G.jld2")
results=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\zOBZ_results_NORTH_SEA_4G.jld2")
results=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\n2HMD_results_NORTH_SEA_4G.jld2")
results=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\n2zOBZ_results_NORTH_SEA_4G.jld2")
results=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\HMD2nOBZ_results_NORTH_SEA_4G.jld2")
results=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\zOBZ2nOBZ_results_NORTH_SEA_4G.jld2")

results=results_n2z
result=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\onshore_grid\\NORTH_SEA_nodal_k4_full_ntcX2.jld2")#09gap was good one


results=result["1"]
#results["s"]["map_gen_types"]["markets"][1]
#results["s"]["onshore_nodes"]=[i for i = 1:1:51]
######################### Nodal summary
#push!(results["s"]["map_gen_types"]["markets"][1],"UK")
results["result_mip"]["solution"]["nw"]=_CBD.VOLL_clearing_price(results["result_mip"]["solution"]["nw"],results["s"])
results["s"]["cost_summary"]=_CBD.print_solution_wcost_data(results["result_mip"], results["s"], results["data"])
s_nodal, result_mip_nodal, data_nodal, mn_data_nodal=_CBD.summarize_in_s(results);
_CBD.print_solution_wcost_data(result_mip_nodal, s_nodal, data_nodal)#-856896.0245340846
_CBD.print_table_summary(s_nodal)

######################### Zonal summary
push!(results["s"]["map_gen_types"]["markets"][1],"UK")
results["result_mip"]["solution"]["nw"]=_CBD.VOLL_clearing_price(results["result_mip"]["solution"]["nw"],results["s"])
results["result_mip_hm_prices"]["solution"]["nw"]=_CBD.VOLL_clearing_price(results["result_mip_hm_prices"]["solution"]["nw"],results["s"])
results["s"]["cost_summary"]=_CBD.print_solution_wcost_data(results["result_mip"], results["s"], results["data"])
s_z, result_mip_z, data_z, mn_data_z=_CBD.summarize_zonal_in_s(results);
_CBD.print_solution_wcost_data(result_mip_z, s_z, data_z)#-856896.0245340846
_CBD.print_table_summary(s_z)

######################################################
#get dictionary of ID, FD, RDispatch
dk_gen_load=_CBD.InitialD_FinalD_ReDispatch(results)
#Wind generation
wfs=[string(wf) for (k, wfs) in results["s"]["map_gen_types"]["offshore"] for wf in wfs]
sum(sum.(eachcol(dk_gen_load["FD"][!,Symbol.(wfs)])))/results["s"]["scenarios_length"]*(8760)/(results["s"]["hours_length"])
#Get Dataframe of the bus numbers of each generator
df_bus=_CBD.gen_load_values(results["mn_data"]["nw"],"gen_bus")
df_bus=df_bus[!,Symbol.(names(dk_gen_load["FD"]))]
#get dataframes of NPV/Orig clearing prices per node
dk_price=_CBD.bus_values(df_bus,results["result_mip"]["solution"]["nw"],results["s"])
#Get Dataframe of generator NPV hourly values 
push!(dk_price,"GENS"=>_CBD.gen_bid_prices(results["s"]["xd"]["gen"],Symbol.(names(dk_gen_load["FD"]))))
#Update generator names
dk_gen_load["FD"]=_CBD.rename_gen_df_columns(results["s"]["map_gen_types"]["type"],dk_gen_load["FD"])
dk_gen_load["ID"]=_CBD.rename_gen_df_columns(results["s"]["map_gen_types"]["type"],dk_gen_load["ID"])
dk_gen_load["RD"]=_CBD.rename_gen_df_columns(results["s"]["map_gen_types"]["type"],dk_gen_load["RD"])
dk_price["GENS"]=_CBD.rename_gen_df_columns(results["s"]["map_gen_types"]["type"],dk_price["GENS"])
dk_price["NPV"]=_CBD.rename_gen_df_columns(results["s"]["map_gen_types"]["type"],dk_price["NPV"])
dk_price["Orig"]=_CBD.rename_gen_df_columns(results["s"]["map_gen_types"]["type"],dk_price["Orig"])

#seperate the up and down regulation
pos,neg=_CBD.decompose_re_dispatch(dk_gen_load["RD"])
#calculate the Re dispatch cost
dk_price["NPV"][!,"SLACK"]=dk_price["GENS"][!,"SLACK"]
dk_price["NPV"][!,"SLACK_1"]=dk_price["GENS"][!,"SLACK_1"]
dk_price["NPV"][!,"SLACK_2"]=dk_price["GENS"][!,"SLACK_2"]
dk_price["NPV"][!,"SLACK_3"]=dk_price["GENS"][!,"SLACK_3"]
dk_price["NPV"][!,"SLACK_4"]=dk_price["GENS"][!,"SLACK_4"]
dk_price["NPV"][!,"SLACK_5"]=dk_price["GENS"][!,"SLACK_5"]
dk_price["NPV"][!,"SLACK_6"]=dk_price["GENS"][!,"SLACK_6"]
#VOLL
volls=["SLACK","SLACK_1","SLACK_2","SLACK_3","SLACK_4","SLACK_5","SLACK_6"]
sum(sum.(eachcol(dk_gen_load["FD"][!,Symbol.(volls)])))/results["s"]["scenarios_length"]*(8760)/(results["s"]["hours_length"])

b=pos.*dk_price["GENS"]
c=neg.*(dk_price["NPV"].-dk_price["GENS"])
#redispatch cost
d=(sum.(eachcol(b)).+sum.(eachcol(c)))./results["s"]["scenarios_length"]
for (_c,_v) in enumerate(d);println(names(b)[_c]*":"*string(_v));end #SLACK_4:6930.974227213993
println(sum(d))
#Gross consumer surplus 
loads=[string(load) for (k, loads) in results["s"]["map_gen_types"]["loads"] for load in loads]
gcs=dk_gen_load["FD"][!,Symbol.(loads)].*(dk_price["NPV"][!,Symbol.(loads)].-dk_price["GENS"][!,Symbol.(loads)])
sum(sum.(eachcol(gcs)))/results["s"]["scenarios_length"]
####################################################################
dk_gen_load["FD"]=_CBD.rename_gen_df_columns(results["s"]["map_gen_types"]["type"],dk_gen_load["FD"])
sum(sum.(eachcol(dk_gen_load["RD"][!,Symbol.(["SLACK_4"])])./60))
println(pos[!,Symbol.(["SLACK_4"])])
sum(sum(eachcol(neg[!,Symbol.(["SLACK_4"])])))
sum.(eachcol(b[!,Symbol.(["SLACK_4"])]))/6
sum(sum.(eachcol(b)))/60
sum(sum.(eachcol(neg)))/60
results["s"]["xd"]["gen"]["386"]["wf_pmax"]

#total wind
sum([sum(results["s"]["xd"]["gen"][wf]["pmax"].*results["s"]["xd"]["gen"][wf]["wf_pmax"]/10) for wf in wfs])/6*(8760)/results["s"]["hours_length"]*10
#total load
-1*sum([sum(results["s"]["xd"]["gen"][load]["pmax"]/10) for load in loads])/6*(8760)/results["s"]["hours_length"]*10

#VOLL
#3.8464108193018793 nOBZ
#3.8464108193018793 HMD
#3.8554835123377384 zOBZ
#3.8464108193018793 nOBZ2zOBZ
sum(sum.(eachcol(pos)))/6
