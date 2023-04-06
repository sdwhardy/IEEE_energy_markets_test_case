################## loads external packages ##############################
using Gurobi, JuMP, DataFrames, FileIO, CSV, Dates, PlotlyJS
import Cordoba_self; const _CBD = Cordoba_self#Cordoba package backend - under development
import PowerModelsACDC; const _PMACDC = PowerModelsACDC
import PowerModels; const _PM = PowerModels
using OrderedCollections

results_nodal=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\UK_DE_DK\\nodal_results_VOLL5000b_rc.jld2")
results_14=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\UK_DE_DK\\zonal_results_hm14_VOLL5000_rc.jld2")
results_24=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\UK_DE_DK\\zonal_results_hm24_VOLL5000_rc.jld2")
results_34=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\UK_DE_DK\\zonal_results_hm34_VOLL5000_rc.jld2")



######################################################
#get dictionary of ID, FD, RDispatch
results=results_24
dk_gen_load=_CBD.InitialD_FinalD_ReDispatch(results)
#Get Dataframe of the bus numbers of each generator
df_bus=_CBD.gen_load_values(results["mn_data"]["nw"],"gen_bus")
df_bus=df_bus[!,Symbol.(names(dk_gen_load["FD"]))]
#get dataframes of NPV/Orig clearing prices per node
dk_price=_CBD.bus_values(df_bus,results["result_mip"]["solution"]["nw"],results["s"])
#Get Dataframe of generator NPV hourly values 
push!(dk_price,"GENS"=>_CBD.gen_bid_prices(results["s"]["xd"]["gen"],Symbol.(names(dk_gen_load["FD"]))))
#calculate the final dispatch cost
a=dk_gen_load["ID"].*dk_price["NPV"]
push!(a,sum.(eachcol(a)))
a=_CBD.rename_gen_df_columns(results["s"]["map_gen_types"]["type"],a)
sum(a[end,Not([Symbol(string(_name)) for _name = 167:1:196])])/6
#seperate the up and down regulation
pos,neg=_CBD.decompose_re_dispatch(dk_gen_load["RD"])
#calculate the Re dispatch cost
b=pos.*dk_price["GENS"]
c=neg.*(dk_price["NPV"].-dk_price["GENS"])
rbc=(sum(sum.(eachcol(b)))+sum(sum.(eachcol(c))))/6#191272.64882850088
b=_CBD.rename_gen_df_columns(results["s"]["map_gen_types"]["type"],b)

d=(sum.(eachcol(b)).+sum.(eachcol(c)))./6
for (_c,_v) in enumerate(d);println(names(b)[_c]*":"*string(_v));end

names(b)[argmax(d)]
push!(b,sum.(eachcol(b)))
push!(c,sum.(eachcol(c)))
b=_CBD.rename_gen_df_columns(results["s"]["map_gen_types"]["type"],b)
c=_CBD.rename_gen_df_columns(results["s"]["map_gen_types"]["type"],c)

(sum(b[end,:]+c[end,:]))/6

push!(dk_gen_load["FD"],sum.(eachcol(dk_gen_load["FD"])))
dk_gen_load["FD"]=_CBD.rename_gen_df_columns(results["s"]["map_gen_types"]["type"],dk_gen_load["FD"])
sum(dk_gen_load["FD"][end,[:SLACK,:SLACK_1,:SLACK_2]])/6
print(names(a))

######################################################
w_ttl=(sum(results["s"]["xd"]["gen"][string(first(first(results["s"]["wfz"])))]["pmax"])/6)*4000*8760/(6*24)
print(w_ttl)

_w=0
for (nw_i,nw) in sort(OrderedCollections.OrderedDict(results["result_mip"]["solution"]["nw"]), by=x->parse(Int64,x))
     _w=_w+nw["gen"]["166"]["pg"] 
end

w_gen=(_w/6)*100*8760/(6*24)
print(w_gen)
print((w_ttl-w_gen)/(w_ttl)*100)

######################################################
argmax(b[end,Not(Symbol("191"))])
a[end,argmax(a[end,Not(Symbol("191"))])]/6
display(a[end,Not(Symbol("191"))])
CSV.write("C://Users//shardy//Desktop//thesis//plot_data.csv",a)


s_nodal, result_mip_nodal, data_nodal, mn_data_nodal=_CBD.summarize_in_s(results_nodal);
s_14, result_mip_14, data_14, mn_data_14=_CBD.summarize_zonal_in_s(results_14);
s_24, result_mip_24, data_24, mn_data_24=_CBD.summarize_zonal_in_s(results_24);
s_34, result_mip_34, data_34, mn_data_34=_CBD.summarize_zonal_in_s(results_34);

_CBD.print_solution_wcost_data(result_mip_34, s_34, data_34)#-856896.0245340846
_CBD.print_table_summary(s_nodal)
_CBD.print_table_summary(s_14)
_CBD.print_table_summary(s_24)
_CBD.print_table_summary(s_34)


_CBD.topology_map(s_34,1.75)

_CBD.plot_cumulative_production_all_scenarios_allWF(s_nodal, mn_data_nodal)
_CBD.plot_cumulative_income_all_scenarios_allWF(s_nodal, mn_data_nodal)
_CBD.plot_cumulative_income_tl_all_scenarios(s_nodal,data_nodal)


_CBD.print_solution_wcost_data(result_mip_34, s_34, data_34)#-856896.0245340846 




###########################################
#NOTE uncomment AC cables!!!!!!!!!!!!!!!!! 1043 post_process.jl
s=results_14["s"]
result_mip=results_14["result_mip"]

mn_data=results_14["mn_data"]

data=results_14["data"]
zones=[[1,4]]
gurobi = JuMP.optimizer_with_attributes(Gurobi.Optimizer,"OutputFlag" => 1)#select solver
s["home_market"]=zones
s["rebalancing"]=true
s["relax_problem"]=true
s["output"]["duals"]=true
result_mip_hm_prices = _CBD.cordoba_acdc_wf_strg(mn_data, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)#Solve problem
_CBD.print_solution_wcost_data(result_mip_hm_prices, s, data)#-856896.0245340846 

s["home_market"]=[]
result_mip = _CBD.cordoba_acdc_wf_strg(mn_data, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)#Solve problem
result_mip = _CBD.hm_market_prices(result_mip, result_mip_hm_prices)
_CBD.print_solution_wcost_data(result_mip, s, data)#-856896.0245340846 
results=Dict("result_mip"=>result_mip,"data"=>data, "mn_data"=>mn_data, "s"=>s)

s, result_mip, data, mn_data=_CBD.summarize_in_s(results);
_CBD.print_table_summary(s)
###########################################






####################################################################################################################

s=s_nodal; result_mip=result_mip_nodal;mn_data=mn_data_nodal;data=data_nodal
sw=SocialWelfare(s_nodal, result_mip_nodal, mn_data_nodal, data_nodal)
s_nodal["totals"]["all"]
2.39119e8/2.84666e6
2.75453e8/2.84666e6
2.75453e8-2.39119e8

s_nodal=results_nodal["s"];result_mip_nodal=results_nodal["result_mip"];data_nodal=results_nodal["data"];mn_data_nodal=results_nodal["mn_data"]
s_14=results_14["s"];result_mip_14=results_14["result_mip"];data_14=results_14["data"];mn_data_14=results_14["mn_data"]
s_24=results_24["s"];result_mip_24=results_24["result_mip"];data_24=results_24["data"];mn_data_24=results_24["mn_data"]
s_34=results_34["s"];result_mip_34=results_34["result_mip"];data_34=results_34["data"];mn_data_34=results_34["mn_data"]

s_nodal=_CBD.owpps_profit_obz(s_nodal, result_mip_nodal, mn_data_nodal)
s_14=_CBD.owpps_profit_obz(s_14, result_mip_14, mn_data_14)
s_24=_CBD.owpps_profit_obz(s_24, result_mip_24, mn_data_24)
s_34=_CBD.owpps_profit_obz(s_34, result_mip_34, mn_data_34)

s_nodal=_CBD.transmission_lines_profits(s_nodal, result_mip_nodal, mn_data_nodal, data_nodal);
s_14=_CBD.transmission_lines_profits(s_14, result_mip_14, mn_data_14, data_14);
s_24=_CBD.transmission_lines_profits(s_24, result_mip_24, mn_data_24, data_24);
s_34=_CBD.transmission_lines_profits(s_34, result_mip_34, mn_data_34, data_34);

s_nodal=_CBD.undo_marginal_price_scaling(s_nodal,result_mip_nodal)
s_14=_CBD.undo_marginal_price_scaling(s_14,result_mip_14)
s_24=_CBD.undo_marginal_price_scaling(s_24,result_mip_24)
s_34=_CBD.undo_marginal_price_scaling(s_34,result_mip_34)

gen_consume_summary_nodal=_CBD.summarize_generator_solution_data(result_mip_nodal, data_nodal,s_nodal)#print solution
gen_consume_summary_14=_CBD.summarize_generator_solution_data(result_mip_14, data_14,s_14)#print solution
gen_consume_summary_24=_CBD.summarize_generator_solution_data(result_mip_24, data_24,s_24)#print solution
gen_consume_summary_34=_CBD.summarize_generator_solution_data(result_mip_34, data_34,s_34)#print solution


social_welfare_nodal = _CBD.SocialWelfare(s_nodal, result_mip_nodal, mn_data_nodal, data_nodal)
social_welfare_14 = _CBD.SocialWelfare(s_14, result_mip_14, mn_data_14, data_14)
social_welfare_24 = _CBD.SocialWelfare(s_24, result_mip_24, mn_data_24, data_24)
social_welfare_34 = _CBD.SocialWelfare(s_34, result_mip_34, mn_data_34, data_34)

s["income_summary"]["owpp"]
social_welfare["totals"]
#_CBD.topology_map(s_nodal,"tinf")
#nodal "gross_consumer_surplus"=>-1.30748e6
#hm

s_34=_CBD.tl_totals(s_34,data_34)
s_34["income_summary"]["tso"]["totals"]
s_nodal["income_summary"]["strg"]["all"]


s=s_nodal;result_mip=result_mip_nodal;mn_data=mn_data_nodal
scenario_num="1";scenario= mn_data["scenario"][scenario_num]
s_nodal=_CBD.strg_profit_obzs(s_nodal, result_mip_nodal, mn_data_nodal)



_CBD.plot_cumulative_wf_production_all_scenarios(s, mn_data, "DE")

_CBD.plot_cumulative_wf_income_all_scenarios(s, mn_data, "DK")

_CBD.plot_cumulative_wf_income_all_scenarios(s, mn_data, "BE")

using PlotlyJS
yvalues=[social_welfare_allhm["totals"]["all"]["gross_consumer_surplus"], social_welfare_567["totals"]["all"]["gross_consumer_surplus"], social_welfare_nodal["totals"]["all"]["gross_consumer_surplus"]]
yvalues=[s_allhm["income_summary"]["owpp"]["all"]["power"]*(8760/s_allhm["hours_length"]), s_567["income_summary"]["owpp"]["all"]["power"]*(8760/s_567["hours_length"]), s_nodal["income_summary"]["owpp"]["all"]["power"]*(8760/s_nodal["hours_length"])]
xvalues=["HMD", "zOBZ", "nOBZ"]
xlabel="Market Type"
ylabel="GWh"
_CBD.basic_bar_chart(xvalues,yvalues,xlabel,ylabel)





#social welfare
#totals: -74468.4(567), -75017.9(HM), -74738.6(zonal)
c=sum(sum(cb["rent"]) for (c,cb) in hourly_income_tl["dc"])#3262.67155
c=sum(sum(cb["rent"]) for (c,cb) in hourly_income_tl["ac"])

wf=[];sc="6"
for (n,nw) in enumerate(s["xd"]["gen"]["218"]["pmax"]); if (issubset([n],values(mn_data["scenario"][sc]))) push!(wf,nw);end;end
maximum(wf)


country="WF"#,"DE","DK"]
scenario="1"
con=gen_consume_summary_nodal["onshore_demand"][scenario][country]#[121:144,:]
gen=gen_consume_summary_nodal["onshore_generation"][scenario][country]#[121:144,:]
_CBD.plot_generation_profile(deepcopy(gen),deepcopy(con),country*" "*scenario)

#result_mip=deepcopy(result_mip_001)
#####################################

country="DK"#,"DE","DK"]
scenario="1"
con=gen_consume_summary["onshore_demand"][scenario][country]#[121:144,:]
gen=gen_consume_summary["onshore_generation"][scenario][country]#[121:144,:]
_CBD.plot_generation_profile(deepcopy(gen),deepcopy(con),country*" "*scenario)


s["income_summary"]=Dict()

country="DE"#,"DE","DK"]
scenario="1"
con=gen_consume_summary_nodal["onshore_demand"][scenario][country]#[121:144,:]
gen=gen_consume_summary_nodal["offshore_generation"][scenario][country]#[121:144,:]
con=select!(con,:ts)
_CBD.plot_generation_profile(deepcopy(gen),deepcopy(con),country*" "*scenario)


_CBD.plot_dual_marginal_price(result_mip, string.(values(mn_data["scenario"][scenario])), (1,"UK"))
_CBD.plot_dual_marginal_price(result_mip, keys(mn_data["scenario"][scenario]), (2,"BE"))
_CBD.plot_dual_marginal_price(result_mip, keys(mn_data["scenario"][scenario]), (4,"BE"))
_CBD.plot_dual_marginal_price(result_mip, keys(mn_data["scenario"][scenario]), (4,"DK"))

