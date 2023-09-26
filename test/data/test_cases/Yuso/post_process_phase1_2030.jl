################## loads external packages ##############################
using Gurobi, JuMP, DataFrames, FileIO, CSV, Dates, PlotlyJS
import IEEE_energy_markets_test_case; const _CBD = IEEE_energy_markets_test_case#Cordoba package backend - under development
import PowerModelsACDC; const _PMACDC = PowerModelsACDC
import PowerModels; const _PM = PowerModels
using OrderedCollections

#################################### map output #######################
############################## newest #################################

results=FileIO.load(pwd()*"\\test\\data\\test_cases\\Yuso\\2016\\results\\YUSO_wNuclear2030.jld2")
######################################################
#get dictionary of ID, FD, RDispatch
dk_gen_load=_CBD.InitialD_FinalD_ReDispatch(results["1"])


#Wind generation
wfs=[string(wf) for (k, wfs) in results["1"]["s"]["map_gen_types"]["offshore"] for wf in wfs]

#Get Dataframe of the bus numbers of each generator
df_bus=_CBD.gen_load_values(results["1"]["mn_data"]["nw"],"gen_bus")

df_bus=df_bus[!,Symbol.(names(dk_gen_load["FD"]))]

#get dataframes of NPV/Orig clearing prices per node
dk_price=_CBD.bus_values(df_bus,results["1"]["result_mip"]["solution"]["nw"],results["1"]["s"])

#Get Dataframe of generator NPV hourly values 
push!(dk_price,"GENS"=>_CBD.gen_bid_prices(results["1"]["s"]["xd"]["gen"],Symbol.(names(dk_gen_load["FD"]))))

#Update generator names
dk_gen_load["FD"]=_CBD.rename_gen_df_columns(results["1"]["s"]["map_gen_types"]["type"],dk_gen_load["FD"])

dk_price["GENS"]=_CBD.rename_gen_df_columns(results["1"]["s"]["map_gen_types"]["type"],dk_price["GENS"])

dk_price["NPV"]=_CBD.rename_gen_df_columns(results["1"]["s"]["map_gen_types"]["type"],dk_price["NPV"])

dk_price["Orig"]=_CBD.rename_gen_df_columns(results["1"]["s"]["map_gen_types"]["type"],dk_price["Orig"])

dk_gen_load["FD"]=dk_gen_load["FD"]./10

new_names=["Offshore Wind EI", "nonStochGen89 BE", "nonStochGen18 BE", "SLACK BE", "nonStochGen150 BE", "nonStochGen119 BE", "nonStochGen120 BE", "Onshore Wind BE", "nonStochGen60 BE", "Offshore Wind BE", "Solar PV BE", "nonStochGen89 UK",  "nonStochGen18 UK",  "SLACK UK",  "nonStochGen150 UK",  "nonStochGen119 UK",  "nonStochGen140 UK",  "nonStochGen120 UK",  "Onshore Wind UK",  "nonStochGen60 UK",  "nonStochGen110 UK",  "Offshore Wind UK",  "Solar PV UK", "Load BE", "Load UK"]

DataFrames.rename!(dk_gen_load["FD"],Symbol.(new_names))

DataFrames.rename!(dk_price["Orig"],Symbol.(new_names))

#BE WF
CSV.write(pwd()*"\\test\\data\\test_cases\\Yuso\\2016\\results\\generation_BE_EI2016_2030.csv", dk_gen_load["FD"][!,1:1])
CSV.write(pwd()*"\\test\\data\\test_cases\\Yuso\\2016\\results\\cost_BE_EI2016_2030.csv", dk_price["Orig"][!,1:1])

#BE
CSV.write(pwd()*"\\test\\data\\test_cases\\Yuso\\2016\\results\\generation_BE2016_2030.csv", dk_gen_load["FD"][!,2:11])
CSV.write(pwd()*"\\test\\data\\test_cases\\Yuso\\2016\\results\\cost_BE2016_2030.csv", dk_price["Orig"][!,2:11])

#UK
CSV.write(pwd()*"\\test\\data\\test_cases\\Yuso\\2016\\results\\generation_UK2016_2030.csv", dk_gen_load["FD"][!,12:end-2])
CSV.write(pwd()*"\\test\\data\\test_cases\\Yuso\\2016\\results\\cost_UK2016_2030.csv", dk_price["Orig"][!,12:end-2])

#Load
CSV.write(pwd()*"\\test\\data\\test_cases\\Yuso\\2016\\results\\Load_BEUK2016_2030.csv", dk_gen_load["FD"][!,end-1:end])
###################################################

#results["1"]["result_mip"]["solution"]["nw"]["1"]["branchdc"]["1"]["pf"]
dc_cable_BEIE=[eqps["branchdc"]["1"]["pf"] for (k, eqps) in sort(OrderedCollections.OrderedDict(results["1"]["result_mip"]["solution"]["nw"]), by=x->parse(Int64,x))]

ac_cable_BEIE=[eqps["branch"]["1"]["pf"] for (k, eqps) in sort(OrderedCollections.OrderedDict(results["1"]["result_mip"]["solution"]["nw"]), by=x->parse(Int64,x))]

dc_cable_UKIE=[eqps["branchdc"]["2"]["pf"] for (k, eqps) in sort(OrderedCollections.OrderedDict(results["1"]["result_mip"]["solution"]["nw"]), by=x->parse(Int64,x))]

dc_cable_UKBE=[eqps["branchdc"]["3"]["pf"] for (k, eqps) in sort(OrderedCollections.OrderedDict(results["1"]["result_mip"]["solution"]["nw"]), by=x->parse(Int64,x))]

dc_cable_BEIE=dc_cable_BEIE./10

ac_cable_BEIE=ac_cable_BEIE./10

dc_cable_UKIE=dc_cable_UKIE./10

dc_cable_UKBE=dc_cable_UKBE./10

loads=DataFrame(Symbol("dc cable BE")=>dc_cable_BEIE,Symbol("ac cable BE")=>ac_cable_BEIE,Symbol("dc cable UK")=>dc_cable_UKIE, Symbol("dc cable UKBE")=>dc_cable_UKBE)

CSV.write(pwd()*"\\test\\data\\test_cases\\Yuso\\2016\\results\\powerflow_BEUK2016_2030.csv", loads)
