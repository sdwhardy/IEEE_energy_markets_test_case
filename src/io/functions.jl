
function zonal_market_main_IEEE(mn_data, data, s)
    hm=deepcopy(s["home_market"]);
    gurobi = JuMP.optimizer_with_attributes(Gurobi.Optimizer,"OutputFlag" => 1, "TimeLimit" => 36000);#select solver
    result_mip = cordoba_acdc_wf_strg(mn_data, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s);#Solve problem
    #print_solution_wcost_data(result_mip, s, data);
    s["home_market"]=[]
    mn_data, data, s = data_setup_IEEE(s);#Build data structure for given options
    s["home_market"]=hm
    mn_data, s = set_inter_zonal_grid(result_mip,mn_data,s);
    s["home_market"]=[]
    gurobi = JuMP.optimizer_with_attributes(Gurobi.Optimizer,"OutputFlag" => 1, "TimeLimit" => 36000)#select solver
    result_mip = cordoba_acdc_wf_strg(mn_data, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)#Solve problem
    #print_solution_wcost_data(result_mip, s, data)
    s["home_market"]=hm
    s["rebalancing"]=true
    s["relax_problem"]=true
    s["output"]["duals"]=true
    mn_data, data, s = data_update_IEEE(s,result_mip);#Build data structure for given options
    mn_data, s = set_rebalancing_grid(result_mip,mn_data,s);
    s, mn_data= remove_integers(result_mip,mn_data,data,s);
    result_mip_hm_prices = cordoba_acdc_wf_strg(mn_data, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)#Solve problem
    s["home_market"]=[]
    mn_data, data, s = data_update_IEEE(s,result_mip);#Build data structure for given options
    mn_data, s = set_rebalancing_grid(result_mip,mn_data,s);
    s, mn_data= remove_integers(result_mip,mn_data,data,s);
    result_mip = cordoba_acdc_wf_strg(mn_data, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)#Solve problem
    result_mip= hm_market_prices(result_mip, result_mip_hm_prices)
    results=Dict("result_mip"=>result_mip,"data"=>data, "mn_data"=>mn_data, "s"=>s, "result_mip_hm_prices"=>result_mip_hm_prices)
    return results
end
#####################

function nodal_market_main_IEEE(mn_data, data, s)
    gurobi = JuMP.optimizer_with_attributes(Gurobi.Optimizer,"OutputFlag" => 1, "TimeLimit" => 54000)#, "MIPGap"=>9e-3)#select solver
    result_mip = cordoba_acdc_wf_strg(mn_data, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)#Solve problem
    #print_solution_wcost_data(result_mip, s, data)
    gurobi = JuMP.optimizer_with_attributes(Gurobi.Optimizer,"OutputFlag" => 1)#select solver
    s["rebalancing"]=true
    s["relax_problem"]=true
    s["output"]["duals"]=true
    mn_data, data, s = data_update_IEEE(s,result_mip);#Build data structure for given options
    mn_data, s = set_rebalancing_grid(result_mip,mn_data,s);
    s, mn_data= remove_integers(result_mip,mn_data,data,s);
    result_mip =  cordoba_acdc_wf_strg(mn_data, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)#Solve problem=#
    results=Dict("result_mip"=>result_mip,"data"=>data, "mn_data"=>mn_data, "s"=>s)
    return results
end

############
function print_mn_data(mn_data,s)
    println(s["onshore_nodes"])
    println(s["offshore_nodes"])
    println(s["wfz"])
    println("!!!!!!!!!! branch_ne !!!!!!!!!!!!!!!!!!!!")
    for c in sort!(parse.(Int64,keys(mn_data["nw"]["1"]["ne_branch"]))) 
        cb=mn_data["nw"]["1"]["ne_branch"][string(c)]
        println("rate_a "*string(cb["rate_a"])*" cost "*string(cb["construction_cost"])*" status "*string(cb["br_status"])*" ID "*string(cb["source_id"])*" bfr "*string(cb["f_bus"])*" bto "*string(cb["t_bus"]))    
        #println(mn_data["nw"]["1"]["ne_branch"][string(c)]==mn_data["nw"]["2"]["ne_branch"][string(c)]==mn_data["nw"]["3"]["ne_branch"][string(c)]==mn_data["nw"]["4"]["ne_branch"][string(c)])
        #println(s["xd"]["ne_branch"][string(c)])
    end
    println("!!!!!!!!!! branch !!!!!!!!!!!!!!!!!!!!")
    for c in sort!(parse.(Int64,keys(mn_data["nw"]["1"]["branch"]))) 
        cb=mn_data["nw"]["1"]["branch"][string(c)]
        println("rate_a "*string(cb["rateA"])*" cost "*string(cb["cost"])*" status "*string(cb["br_status"])*" ID "*string(cb["source_id"])*" bfr "*string(cb["f_bus"])*" bto "*string(cb["t_bus"]))    
        #println(mn_data["nw"]["1"]["branch"][string(c)]==mn_data["nw"]["2"]["branch"][string(c)]==mn_data["nw"]["3"]["branch"][string(c)]==mn_data["nw"]["4"]["branch"][string(c)])
       # println(s["xd"]["branch"][string(c)])
    end
    println("!!!!!!!!!! branchdc_ne !!!!!!!!!!!!!!!!!!!!")
    for c in sort!(parse.(Int64,keys(mn_data["nw"]["1"]["branchdc_ne"]))) 
        cb=mn_data["nw"]["1"]["branchdc_ne"][string(c)]
        println("rateA "*string(cb["rateA"])*" cost "*string(cb["cost"])*" status "*string(cb["status"])*" ID "*string(cb["source_id"])*" bfr "*string(cb["fbusdc"])*" bto "*string(cb["tbusdc"]))    
       # println(mn_data["nw"]["1"]["branchdc_ne"][string(c)]==mn_data["nw"]["2"]["branchdc_ne"][string(c)]==mn_data["nw"]["3"]["branchdc_ne"][string(c)]==mn_data["nw"]["4"]["branchdc_ne"][string(c)])
        #println(s["xd"]["branchdc_ne"][string(c)])
    end
    println("!!!!!!!!!! branchdc !!!!!!!!!!!!!!!!!!!!")
    for c in sort!(parse.(Int64,keys(mn_data["nw"]["1"]["branchdc"]))) 
        cb=mn_data["nw"]["1"]["branchdc"][string(c)]
        println("rateA "*string(cb["rateA"])*" cost "*string(cb["cost"])*" status "*string(cb["status"])*" ID "*string(cb["source_id"])*" bfr "*string(cb["fbusdc"])*" bto "*string(cb["tbusdc"]))    
        #println(mn_data["nw"]["1"]["branchdc"][string(c)]==mn_data["nw"]["2"]["branchdc"][string(c)]==mn_data["nw"]["3"]["branchdc"][string(c)]==mn_data["nw"]["4"]["branchdc"][string(c)])
       # println(s["xd"]["branchdc"][string(c)])
    end
    println("!!!!!!!!!! convdc !!!!!!!!!!!!!!!!!!!!")
    for c in sort!(parse.(Int64,keys(mn_data["nw"]["1"]["convdc"]))) 
        cv=mn_data["nw"]["1"]["convdc"][string(c)]
        println("Pmax "*string(cv["Pacmax"])*","*string(cv["Pacrated"])*" ID "*string(cv["source_id"])*" DCb "*string(cv["busdc_i"])*" ACb "*string(cv["busac_i"]))    
       # println(mn_data["nw"]["1"]["convdc"][string(c)]==mn_data["nw"]["2"]["convdc"][string(c)]==mn_data["nw"]["3"]["convdc"][string(c)]==mn_data["nw"]["4"]["convdc"][string(c)])
        #println(s["xd"]["convdc"][string(c)])
    end
    println("!!!!!!!!!! owpps !!!!!!!!!!!!!!!!!!!!")
    for c in ["BE","NL","DE","DK","UK"]
        println(c)    
        wfn=s["map_gen_types"]["offshore"][c][1]
        wf=mn_data["nw"]["1"]["gen"][wfn] 
        println("pmax "*string(wf["pmax"])*" cost "*string(wf["invest"])*" status "*string(wf["gen_status"])*" ID "*string(wf["source_id"])*" bus "*string(wf["gen_bus"]))    
       # println(s["xd"]["gen"][string(wfn)])
    end
    println("!!!!!!!!!! ACBus !!!!!!!!!!!!!!!!!!!!")
    for c in sort!(parse.(Int64,keys(mn_data["nw"]["1"]["bus"]))) 
        println(c)
        cv=mn_data["nw"]["1"]["bus"][string(c)]
        println("bus_i "*string(cv["bus_i"])*" bus_type "*string(cv["bus_type"])*" ID "*string(cv["source_id"]))    
        #println(mn_data["nw"]["1"]["bus"][string(c)]==mn_data["nw"]["2"]["bus"][string(c)]==mn_data["nw"]["3"]["bus"][string(c)]==mn_data["nw"]["4"]["bus"][string(c)])
    end
    
    println("!!!!!!!!!! DCBus !!!!!!!!!!!!!!!!!!!!")
    for c in sort!(parse.(Int64,keys(mn_data["nw"]["1"]["busdc"])))
        #println(c) 
        cv=mn_data["nw"]["1"]["busdc"][string(c)]
        println("busdc_i "*string(cv["busdc_i"])*" busac_i "*" grid "*string(cv["grid"])*" ID "*string(cv["source_id"]))    
       # println(mn_data["nw"]["1"]["busdc"][string(c)]==mn_data["nw"]["2"]["busdc"][string(c)]==mn_data["nw"]["3"]["busdc"][string(c)]==mn_data["nw"]["4"]["busdc"][string(c)])
    end
end
###########

function nodal2zonal(s,result_mip,zones)
    gurobi = JuMP.optimizer_with_attributes(Gurobi.Optimizer,"OutputFlag" => 1)#select solver
    s["home_market"]=zones
    s["rebalancing"]=true
    s["relax_problem"]=true
    s["output"]["duals"]=true
    mn_data, data, s = data_update_IEEE(s,result_mip);#Build data structure for given options
    mn_data, s = set_rebalancing_grid(result_mip,mn_data,s);
    s, mn_data= remove_integers_new_market(result_mip,mn_data,data,s);
    result_mip_hm_prices = cordoba_acdc_wf_strg(mn_data, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)#Solve problem
    s["home_market"]=[]
    mn_data, data, s = data_update_IEEE(s,result_mip);#Build data structure for given options
    mn_data, s = set_rebalancing_grid(result_mip,mn_data,s);
    s, mn_data= remove_integers_new_market(result_mip,mn_data,data,s);
    result_mip = cordoba_acdc_wf_strg(mn_data, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)#Solve problem
    result_mip= hm_market_prices(result_mip, result_mip_hm_prices)
    return result_mip, data, mn_data, s, result_mip_hm_prices
end

function zonal2nodal(s,result_mip)
    gurobi = JuMP.optimizer_with_attributes(Gurobi.Optimizer,"OutputFlag" => 1)#select solver
    s["rebalancing"]=true
    s["relax_problem"]=true
    s["output"]["duals"]=true
    s["home_market"]=[]
    mn_data, data, s = data_update_IEEE(s,result_mip);#Build data structure for given options
    mn_data, s = set_rebalancing_grid(result_mip,mn_data,s);
    s, mn_data= remove_integers_new_market(result_mip,mn_data,data,s);
    result_mip = cordoba_acdc_wf_strg(mn_data, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)#Solve problem
    return result_mip, data, mn_data, s
end

##########################
##################### Topology input data ############################
function get_topology_data_IEEE(s)
    ################# Load topology files ###################################
    topology_df_IEEE(s["rt_ex"], s["relax_problem"], s["AC"])#creates .m file
    data, s["ics_ac"], s["ics_dc"], s["nodes"] = filter_mfile_cables_IEEE(s["rt_ex"])#loads resulting topology and filters for candidate cables
    return data, s
end

#=country="FR"
ts=scenario_data["Generation"]["RES"]["Offshore Wind"][country]["2015"][!,country*"_MWh"]
sum(ts)/length(ts)
BE
2014:0.4053456029319635
2015:0.4580923631639269
UK
2014:0.4130090032551277
2015:0.37776645245081936
NL
2014:0.45002760967431504
2015:0.4480488467697488
DE
2014:0.45225340715311957
2015:0.45383560031231224
DK
2014:0.45634484441152967
2015:0.47359769002990865
NO
2014:0.44982428092977383
2015:0.4399956644005189
FR
2014:0.37906190301267856
2015:0.40786826342739074=#
function get_scenario_data_IEEE(s)
    ############### defines size and market of genz and wfs ###################
	scenario_data=FileIO.load(s["scenario_data_file"])
    ######## Batteries are removed and modeled seperately time series #########
    for (k_sc,sc) in scenario_data["Generation"]["Scenarios"];for (k_yr,yr) in sc; for (k_cunt,cuntree) in yr;
        filter!(:Generation_Type=>x->x!="Battery", cuntree);
        filter!(:Generation_Type=>x->x!="VOLL", cuntree);
        push!(cuntree,["SLACK",1000000])
    end;end;end
        push!(scenario_data["Generation"]["keys"],"SLACK")
        delete!(scenario_data["Generation"]["costs"],"VOLL");
        #push!(scenario_data["Generation"]["costs"],"SLACK"=>maximum(values(scenario_data["Generation"]["costs"])))
        push!(scenario_data["Generation"]["costs"],"SLACK"=>5000)

    ####################### Freeze offshore expansion of data #################
    #scenario_data=freeze_offshore_expansion(s["nodes"], scenario_data)
    return scenario_data
end

function freeze_offshore_expansion(nodes, scenario_data)
	developement_zones=filter(:type=>x->x==0,nodes)[!,:country]
	Base_offshore=Dict();for (k_cunt,cuntree) in scenario_data["Generation"]["Scenarios"]["Base"]["2020"]
	push!(Base_offshore,k_cunt=>filter(:Generation_Type=>x->x=="Offshore Wind", cuntree))end;
	for (k_sc,sc) in scenario_data["Generation"]["Scenarios"]
        for (k_yr,yr) in sc;
            for (k_cunt,cuntree) in yr;
                if (issubset([k_cunt],developement_zones))
                    owf=findfirst(x->x=="Offshore Wind", cuntree[!,:Generation_Type]);
                    scenario_data["Generation"]["Scenarios"][k_sc][k_yr][k_cunt][!,:Capacity][owf]=Base_offshore[k_cunt][!,"Capacity"][1]
                end;end;end;end
                return scenario_data
            end

function keep_only_hm_cables(s,data)
    for (b,br) in data["branchdc_ne"]
        if (is_intra_zonal(br["fbusdc"],br["tbusdc"],s["home_market"]))
            #br["rateA"]=br["rateB"]=br["rateC"]=0
            br["status"]=0
        end;end;
    for (b,br) in data["ne_branch"]
        if (is_intra_zonal(br["f_bus"],br["t_bus"],s["home_market"]))
            #br["rateA"]=br["rateB"]=br["rateC"]=0
            br["br_status"]=0
        end;end;
    return data
end

function is_intra_zonal(f,t,zms)
    for zm in zms
        if (issubset([f,t],zm))
            #println(f);println(t)
            return true
        end
    end
    return false
end

function update_settings(s, argz, data)
    s["genz"]=argz["genz"]
    s["wfz"]=argz["wfz"]
    s["ic_lim_onshore"]=argz["conv_lim_onshore"]/data["baseMVA"]
    s["ic_lim_offshore"]=argz["conv_lim_offshore"]/data["baseMVA"]
    s["rad_lim"]=maximum([b["rate_a"] for (k,b) in data["ne_branch"]])
    s["scenarios_length"] = length(argz["scenario_names"])
    s["years_length"] = length(argz["scenario_years"])
    s["hours_length"] = argz["ls"]
    return s
end


function update_settings_wgenz(s, argz, data)
    s["ic_lim_onshore"]=argz["conv_lim_onshore"]/data["baseMVA"]
    s["ic_lim_offshore"]=argz["conv_lim_offshore"]/data["baseMVA"]
    s["rad_lim"]=maximum([b["rate_a"] for (k,b) in data["ne_branch"]])
    s["scenarios_length"] = length(argz["scenario_names"])*length(argz["res_years"])
    s["years_length"] = length(argz["scenario_years"])
    s["hours_length"] = argz["ls"]
    return s
end

#
function update_settings_wgenz(s, data)
    s["ic_lim_onshore"]=s["conv_lim_onshore"]/data["baseMVA"]
    s["ic_lim_offshore"]=s["conv_lim_offshore"]/data["baseMVA"]
    if (length(data["ne_branch"])>0);s["rad_lim"]=maximum([b["rate_a"] for (k,b) in data["ne_branch"]]);end
    s["scenarios_length"] = length(s["scenario_names"])*length(s["res_years"])
    s["years_length"] = length(s["scenario_years"])
    return s
end

########################################## Cables ###############################################
###################### HVAC/HVDC

function filter_mfile_cables_IEEE(rt_ex)
    nodes = DataFrames.DataFrame(XLSX.readtable(rt_ex*"input.xlsx", "node_generation"))
	edges = DataFrames.DataFrame(XLSX.readtable(rt_ex*"input.xlsx", "connections_acdc"))
    edges_existing = DataFrames.DataFrame()
    try edges_existing = DataFrames.DataFrame(XLSX.readtable(rt_ex*"input.xlsx", "existing_lines")) catch; println("No onshore net transfer capacities specified.") end
    file = rt_ex*"topology.m"
	data = PowerModels.parse_file(file)
    data,edges_existing=add_ntcs(data,edges_existing)
	data,ics_ac=filter_AClines(data,edges,nodes)
	data,ics_dc=filter_DClines(data,edges,nodes,edges_existing)
    return data, ics_ac, ics_dc, nodes
end

function add_ntcs(data,edges_existing)
    for r in eachrow(edges_existing)  
        if !(ismissing(r[:DC_from]))
            data["busdc"],dcbus_fr=addDCbuses(data["busdc"])
            data["convdc"]=addDCconv(data["convdc"],r[:DC_mva],r[:DC_from],dcbus_fr) 
            data["busdc"],dcbus_to =addDCbuses(data["busdc"])
            data["convdc"]=addDCconv(data["convdc"],r[:DC_mva],r[:DC_to],dcbus_to)
            data["branchdc"]=addDCNTC(data["branchdc"],r[:DC_mva],dcbus_fr,dcbus_to)
            r[:DC_from]=dcbus_fr
            r[:DC_to]=dcbus_to
        end
    end
    return data, edges_existing
end

function addDCNTC(brchs,mva,dc_busFR,dc_busTO)
    brch=maximum(parse.(Int64,keys(brchs)))
    br=deepcopy(brchs[string(brch)])
    br["rateA"]=br["rateB"]=br["rateC"]=mva
    br["status"]=1
    br["r"]=0.001
    br["fbusdc"]=dc_busFR
    br["tbusdc"]=dc_busTO
    br["source_id"]=["branchdc", brch+1]
    br["cost"]=0
    push!(brchs,string(brch+1)=>deepcopy(br))
    return brchs 
end

function addDCconv(convdcs,mva,ac_bus,dc_bus)
    convdc=maximum(parse.(Int64,keys(convdcs)))
    cv=deepcopy(convdcs[string(convdc)])
    cv["Pacrated"]=mva
    cv["Pacmax"]=mva
    cv["Pacmin"]=-1*mva
    cv["Qacrated"]=mva
    cv["Qacmin"]=-1*mva
    cv["Qacmax"]=mva
    cv["status"]=1
    cv["source_id"]=["convdc", convdc+1]
    cv["index"]=convdc+1
    cv["busdc_i"]=dc_bus
    cv["busac_i"]=ac_bus
    cv["type_ac"]=2
    cv["type_dc"]=3
    cv["cost"]=0
    push!(convdcs,string(convdc+1)=>deepcopy(cv))
    return convdcs 
end

function addDCbuses(db)
    dcbuses=maximum(parse.(Int64,keys(db)))
    bd=deepcopy(db[string(dcbuses)])
    bd["source_id"]=["busdc",dcbuses+1]
    bd["index"]=dcbuses+1
    bd["busdc_i"]=dcbuses+1
    bd["grid"]=dcbuses+1
    push!(db,string(dcbuses+1)=>deepcopy(bd))
    return db, dcbuses+1
end



#utm coordinates from gps
function utm_gps2xy(lla,north_south::Bool=true,zone_utm::Int64=31)
    utm_desired = Geodesy.UTMfromLLA(zone_utm, north_south, Geodesy.wgs84)#sets UTM zone
    utm = utm_desired(Geodesy.LLA(first(lla),last(lla)))#coverts to cartesian
    return utm
end

################################# HVAC ##############################
function filter_AClines(data,edges,nodes)
    #size and length
    z_base_ac=(data["bus"]["1"]["base_kv"])^2/data["baseMVA"]
    ics_ac=Tuple{Int64,Int64}[]
    acc=filter(x->!ismissing(x),edges[!,"AC_mva"])
    for (k, s) in enumerate(acc)
        from_xy=utm_gps2xy((nodes[!,"lat"][edges[!,"AC_from"][k]],nodes[!,"long"][edges[!,"AC_from"][k]]))
        to_xy=utm_gps2xy((nodes[!,"lat"][edges[!,"AC_to"][k]],nodes[!,"long"][edges[!,"AC_to"][k]]))
        push!(ics_ac,(s,round(Int64,Geodesy.euclidean_distance(from_xy, to_xy, 31, true, Geodesy.wgs84)/1000*1.25)))
    end
    accbles2keep_ne=Dict[];
    acc=filter!(x->!ismissing(x),edges[!,"AC_mva"])
    for (r,s) in enumerate(acc)
        for (k,b) in data["ne_branch"]
            if (edges[!,"AC_from"][r]==b["f_bus"] && edges[!,"AC_to"][r]==b["t_bus"])
                push!(accbles2keep_ne,deepcopy(b))
                break;
            end
        end
    end
    data["ne_branch"]=Dict{String,Any}()
    for (k,c) in enumerate(accbles2keep_ne)
        c["source_id"][2]=k
        push!(data["ne_branch"],string(k)=>c)
    end
    ##cables to keep for candidates
    accbles2keep=Dict[]
    for (r,s) in enumerate(acc)
        for (k,b) in data["branch"]
            if (edges[!,"AC_from"][r]==b["f_bus"] && edges[!,"AC_to"][r]==b["t_bus"])
                push!(accbles2keep,deepcopy(b))
                break;
            end
        end
    end
    #existing branches to keep
    data["branch"]=Dict{String,Any}()
    for (k,c) in enumerate(accbles2keep)
        c["source_id"][2]=k
        c["index"]=k
        push!(data["branch"],string(k)=>c)
    end
    return data, ics_ac
end

function AC_cable_options_IEEE(data,candidate_ics_ac,ics_ac,pu)
    z_base_ac=(data["bus"]["1"]["base_kv"])^2/pu
    data=additional_candidatesICS_AC(data,candidate_ics_ac,ics_ac)#adds additional candidates
    for (i,bac) in data["ne_branch"]
    data["ne_branch"][i]=candidateIC_cost_impedance_AC(bac,z_base_ac,pu);end
    data["ne_branch"]=unique_candidateIC_AC(data["ne_branch"])#keep only unique candidates
	temp_cables_ne=Dict{String,Any}()
	temp_cables=Dict{String,Any}()
	cable_pu_costs=Dict{String,Any}()
	cable_pu_r=Dict{String,Any}()
	cable_pu_x=Dict{String,Any}()
    cable_rateA=Dict{String,Any}()

	for (i,acb) in enumerate(sort(OrderedCollections.OrderedDict(data["ne_branch"]), by=x->parse(Int64,x)))
		last(acb)["source_id"][2]=i
		#last(acb)["br_status"]=0
		push!(temp_cables_ne,string(i)=>last(acb))
		for (j,acb_con) in enumerate(sort(OrderedCollections.OrderedDict(data["branch"]), by=x->parse(Int64,x)))
			if (last(acb)["f_bus"]==last(acb_con)["f_bus"] && last(acb)["t_bus"]==last(acb_con)["t_bus"])
				last(acb_con)["source_id"][2]=j
				push!(temp_cables,string(j)=>last(acb_con))
				if (haskey(cable_pu_costs,string(last(acb_con)["f_bus"])*"_"*string(last(acb_con)["t_bus"])))
					push!(cable_pu_costs[string(last(acb_con)["f_bus"])*"_"*string(last(acb_con)["t_bus"])],last(acb)["construction_cost"]/(last(acb)["rate_a"]))
					push!(cable_pu_r[string(last(acb_con)["f_bus"])*"_"*string(last(acb_con)["t_bus"])],last(acb)["br_r"])
					push!(cable_pu_x[string(last(acb_con)["f_bus"])*"_"*string(last(acb_con)["t_bus"])],last(acb)["br_x"])
                    push!(cable_rateA[string(last(acb_con)["f_bus"])*"_"*string(last(acb_con)["t_bus"])],last(acb)["rate_a"])
				else
					push!(cable_pu_costs,string(last(acb_con)["f_bus"])*"_"*string(last(acb_con)["t_bus"])=>[last(acb)["construction_cost"]/(last(acb)["rate_a"])])
					push!(cable_pu_r,string(last(acb_con)["f_bus"])*"_"*string(last(acb_con)["t_bus"])=>[last(acb)["br_r"]])
					push!(cable_pu_x,string(last(acb_con)["f_bus"])*"_"*string(last(acb_con)["t_bus"])=>[last(acb)["br_x"]])
                    push!(cable_rateA,string(last(acb_con)["f_bus"])*"_"*string(last(acb_con)["t_bus"])=>[last(acb)["rate_a"]])
				end
				break
			end
		end
	end
	println(cable_pu_costs)
	data["ne_branch"]=temp_cables_ne
	temp_cables2=Dict{String,Any}()
	for (i,acb) in enumerate(sort(OrderedCollections.OrderedDict(temp_cables), by=x->parse(Int64,x)))
		trms=length(cable_pu_costs[string(last(acb)["f_bus"])*"_"*string(last(acb)["t_bus"])])
		trms_total=sum(b for b in cable_pu_costs[string(last(acb)["f_bus"])*"_"*string(last(acb)["t_bus"])])

		trms_R=length(cable_pu_r[string(last(acb)["f_bus"])*"_"*string(last(acb)["t_bus"])])
		trms_total_R=sum(b for b in cable_pu_r[string(last(acb)["f_bus"])*"_"*string(last(acb)["t_bus"])])

		trms_X=length(cable_pu_x[string(last(acb)["f_bus"])*"_"*string(last(acb)["t_bus"])])
		trms_total_X=sum(b for b in cable_pu_x[string(last(acb)["f_bus"])*"_"*string(last(acb)["t_bus"])])

		last(acb)["br_r"]=(trms_total_R/trms_R)
		last(acb)["br_x"]=(trms_total_X/trms_X)
		last(acb)["cost"]=(trms_total/trms)
        last(acb)["rateA"]=last(acb)["rateB"]=last(acb)["rateC"]=maximum(b for b in cable_rateA[string(last(acb)["f_bus"])*"_"*string(last(acb)["t_bus"])])
		last(acb)["source_id"][2]=i
		push!(temp_cables2,string(i)=>last(acb))
        data["branch"][string(i)]=last(acb)
	end
	#data["branch"]=temp_cables2
    return data
end

#for each AC candidate capacity an appropriate cable is selected and characteristics stored
function candidateIC_cost_impedance_AC(bac,z_base,s_base)
    cb=AC_cbl(bac["rate_a"], bac["length"])
    bac["construction_cost"]=cb.costs.ttl
    bac["br_r"]=((cb.elec.ohm/cb.num)*cb.length)/z_base
    bac["br_x"]=((cb.elec.xl/cb.num)*cb.length)/z_base
    bac["rate_c"]=bac["rate_b"]=bac["rate_a"]=(cb.num*cb.elec.mva)/s_base
    return bac
end
#for each existing AC line capacity an appropriate cable is selected and characteristics stored
function IC_cost_impedance_AC(bac,z_base,s_base)
    cb=AC_cbl(bac["rateA"], bac["length"])
    bac["construction_cost"]=0.0
    bac["br_r"]=((cb.elec.ohm/cb.num)*cb.length)/z_base
    bac["br_x"]=((cb.elec.xl/cb.num)*cb.length)/z_base
    bac["rateC"]=bac["rateB"]=bac["rateA"]=(cb.num*cb.elec.mva)/s_base
    return bac
end

#Sets AC candidate dictionaries with desired candidate qualities
function additional_candidatesICS_AC(data,candidates,ic_data)
    #DC, IC
    ics=[]
    data["ne_branch"]=sort!(OrderedCollections.OrderedDict(data["ne_branch"]), by=x->parse(Int64,x))
    for (i,dcb) in data["ne_branch"]; push!(ics,deepcopy(dcb));end

    data["ne_branch"]=Dict{String,Any}()
    for (i,ic) in enumerate(ics)
        for j=1:1:length(candidates);
            ic["source_id"][2]=j+length(candidates)*(i-1);
            ic["index"]=j+length(candidates)*(i-1);
            ic["rate_a"]=candidates[j]*first(ic_data[i]);
            ic["length"]=last(ic_data[i])[1];
            push!(data["ne_branch"],string(j+length(candidates)*(i-1))=>deepcopy(ic));
        end
    end
    return data
end

function unique_candidateIC_AC(cand_ics)
    copy_cand_ics=deepcopy(cand_ics)
    for (i,dcb) in cand_ics
        for (j,tdcb) in copy_cand_ics
            if ((i!=j && dcb["f_bus"]==tdcb["f_bus"] && dcb["t_bus"]==tdcb["t_bus"] &&  isapprox(dcb["rate_a"],tdcb["rate_a"]; atol = 1)) || isapprox(tdcb["rate_a"],0; atol = 1))
                delete!(copy_cand_ics,j)
                break
            end
        end
    end
    return copy_cand_ics
end

function print_topology_data_AC(data_mip,markets_wfs)
    println("%%%%%%%%%%%%%%%%%%%%%%%%% Nodes %%%%%%%%%%%%%%%%%%%%%%%")
    for (i,n) in enumerate(markets_wfs[1])
        println(string(i)*" - "*n)
    end
    for (i,n) in enumerate(markets_wfs[2])
        println(string(length(markets_wfs[1])+i)*" - OWPP_"*n)
    end
    println("%%%%%%%%%%%%%%%%%%%%%%%% Cables %%%%%%%%%%%%%%%%%%%%%%%")
    for (i,br) in sort(OrderedCollections.OrderedDict(data_mip["ne_branch"]), by=x->parse(Int64,x))
        println(string(i)*": "*string(br["f_bus"])*" - "*string(br["t_bus"])*" MVA: "*string(br["rate_a"])*" Length: "*string(br["length"])*" Cost: "*string(br["construction_cost"])*" Status: "*string(br["br_status"]))
    end
    println("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
end


################################# HVDC Cables
function DC_cable_options_IEEE(data,candidate_ics_dc,ics_dc,pu)
    z_base_dc=(data["busdc"]["1"]["basekVdc"])^2/pu
    data=additional_candidatesICS_DC(data,candidate_ics_dc,ics_dc)#adds additional candidates
    for (i,bdc) in data["branchdc_ne"]
    data["branchdc_ne"][i]=candidateIC_cost_impedance_DC(bdc,z_base_dc);end
    data["branchdc_ne"]=unique_candidateIC_DC(data["branchdc_ne"])#keep only unique candidates
	temp_cables_ne=Dict{String,Any}()
	temp_cables=Dict{String,Any}()
	cable_pu_costs=Dict{String,Any}()
	cable_pu_r=Dict{String,Any}()
    cable_rateA=Dict{String,Any}()
	for (i,acb) in enumerate(sort(OrderedCollections.OrderedDict(data["branchdc_ne"]), by=x->parse(Int64,x)))
		last(acb)["source_id"][2]=i
		#last(acb)["status"]=0
		push!(temp_cables_ne,string(i)=>last(acb))
		for (j,acb_con) in enumerate(sort(OrderedCollections.OrderedDict(data["branchdc"]), by=x->parse(Int64,x)))
			if (last(acb)["fbusdc"]==last(acb_con)["fbusdc"] && last(acb)["tbusdc"]==last(acb_con)["tbusdc"])
				last(acb_con)["source_id"][2]=j
				push!(temp_cables,string(j)=>last(acb_con))
				break
			end
		end
		if (haskey(cable_pu_costs,string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])))
			push!(cable_pu_costs[string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])],last(acb)["cost"]/(last(acb)["rateA"]/pu))
			push!(cable_pu_r[string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])],last(acb)["r"])
            push!(cable_rateA[string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])],last(acb)["rateA"])
		else
			push!(cable_pu_costs,string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])=>[last(acb)["cost"]/(last(acb)["rateA"]/pu)])
			push!(cable_pu_r,string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])=>[last(acb)["r"]])
            push!(cable_rateA,string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])=>[last(acb)["rateA"]])
		end
	end
	data["branchdc_ne"]=temp_cables_ne
	temp_cables2=Dict{String,Any}()
	for (i,acb) in enumerate(sort(OrderedCollections.OrderedDict(temp_cables), by=x->parse(Int64,x)))
		trms=length(cable_pu_costs[string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])])
		trms_total=sum(b for b in cable_pu_costs[string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])])
		#trms_max=minimum(b for b in cable_pu_costs[string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])])
		trms_R=length(cable_pu_r[string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])])
		trms_total_R=sum(r for r in cable_pu_r[string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])])
		last(acb)["cost"]=trms_total/trms
		#last(acb)["cost"]=trms_max
		last(acb)["r"]=trms_total_R/trms_R
		last(acb)["source_id"][2]=i
        last(acb)["rateA"]=maximum(r for r in cable_rateA[string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])])
		push!(temp_cables2,string(i)=>last(acb))
	end
    for (k,b) in data["branchdc"]
        if (b["status"]==1)
            push!(temp_cables2,k=>deepcopy(b))
        end
    end
	data["branchdc"]=temp_cables2
    return data
end

function filter_DClines(data,edges,nodes,edges_existing)
    #size and length
    ics_dc=Tuple{Int64,Int64}[]
    dcc=filter(x->!ismissing(x),edges[!,"DC_mva"])
    for (k, s) in enumerate(dcc)
        from_xy=utm_gps2xy((nodes[!,"lat"][edges[!,"DC_from"][k]],nodes[!,"long"][edges[!,"DC_from"][k]]))
        to_xy=utm_gps2xy((nodes[!,"lat"][edges[!,"DC_to"][k]],nodes[!,"long"][edges[!,"DC_to"][k]]))
        push!(ics_dc,(s,round(Int64,Geodesy.euclidean_distance(from_xy, to_xy, 31, true, Geodesy.wgs84)/1000*1.25)))
    end

    #filter dc connections
    dccbles2keep_ne=Dict[]
	dccbles2keep=Dict[]
    for (r,s) in enumerate(dcc)
        for (k,b) in data["branchdc_ne"]
            if (edges[!,"DC_from"][r]==b["fbusdc"] && edges[!,"DC_to"][r]==b["tbusdc"])
                push!(dccbles2keep_ne,deepcopy(b))
                break;
            end
        end
		for (k,b) in data["branchdc"]
            if (edges[!,"DC_from"][r]==b["fbusdc"] && edges[!,"DC_to"][r]==b["tbusdc"])
                push!(dccbles2keep,deepcopy(b))
                break;
            end
        end
    end

    edcc=filter(x->!ismissing(x),edges_existing[!,"DC_mva"])
    for (r,s) in enumerate(edcc)
		for (k,b) in data["branchdc"]
            if (edges_existing[!,"DC_from"][r]==b["fbusdc"] && edges_existing[!,"DC_to"][r]==b["tbusdc"])
                push!(dccbles2keep,deepcopy(b))
                break;
            end
        end
    end
    data["branchdc_ne"]=Dict{String,Any}()
    for (k,c) in enumerate(dccbles2keep_ne)
        c["source_id"][2]=k
        push!(data["branchdc_ne"],string(k)=>c)
    end
	data["branchdc"]=Dict{String,Any}()
    for (k,c) in enumerate(dccbles2keep)
        c["source_id"][2]=k
        push!(data["branchdc"],string(k)=>c)
    end
    return data, ics_dc
end

#Sets DC candidate dictionaries with desired candidate qualities
function additional_candidatesICS_DC(data,candidates,ic_data)
    #DC, IC
    ics=[]
    data["branchdc_ne"]=sort!(OrderedCollections.OrderedDict(data["branchdc_ne"]), by=x->parse(Int64,x))
    for (i,dcb) in data["branchdc_ne"]; push!(ics,deepcopy(dcb));end

    data["branchdc_ne"]=Dict{String,Any}()
    for (i,ic) in enumerate(ics)
        for j=1:1:length(candidates);
            ic["source_id"][2]=j+length(candidates)*(i-1);
            ic["index"]=j+length(candidates)*(i-1);
            ic["rateA"]=candidates[j]*first(ic_data[i]);
            ic["length"]=last(ic_data[i])[1];
            push!(data["branchdc_ne"],string(j+length(candidates)*(i-1))=>deepcopy(ic));
        end
    end
    return data
end

#for each DC candidate capacity an appropriate cable is selected and characteristics stored
function candidateIC_cost_impedance_DC(bdc,z_base)
    cb=DC_cbl(bdc["rateA"], bdc["length"])
    #bdc["cost"]=cb.costs.cpx_i+cb.costs.cpx_p
    bdc["cost"]=cb.costs.ttl
    #bdc["r"]=((cb.elec.ohm*10^3/cb.num)*cb.length)/z_base
    bdc["r"]=((cb.elec.ohm/cb.num)*cb.length)/z_base
    bdc["rateC"]=bdc["rateB"]=bdc["rateA"]=cb.num*cb.elec.mva
    return bdc
end

#ensures that the only candidates considered are unique cable sizes
function unique_candidateIC_DC(cand_ics)
    copy_cand_ics=deepcopy(cand_ics)
    for (i,dcb) in cand_ics
        for (j,tdcb) in copy_cand_ics
            if (i!=j && dcb["fbusdc"]==tdcb["fbusdc"] && dcb["tbusdc"]==tdcb["tbusdc"] &&  isapprox(dcb["rateA"],tdcb["rateA"]; atol = 1))
                delete!(copy_cand_ics,j)
                break
            end
        end
    end
    return copy_cand_ics
end


function print_topology_data_DC(data_mip,markets_wfs)
    println("%%%%%%%%%%%%%%%%%%%%%%%%% Nodes %%%%%%%%%%%%%%%%%%%%%%%")
    for (i,n) in enumerate(markets_wfs[1])
        println(string(i)*" - "*n)
    end
    for (i,n) in enumerate(markets_wfs[2])
        println(string(length(markets_wfs[1])+i)*" - OWPP_"*n)
    end
    println("%%%%%%%%%%%%%%%%%% Converters %%%%%%%%%%%%%%%%%%%%")
    for (i,cv) in sort(OrderedCollections.OrderedDict(data_mip["convdc"]), by=x->parse(Int64,x))
            println(string(i)*": "*string(cv["cost"]))
    end;
    println("%%%%%%%%%%%%%%%%%%%%%%%% Cables %%%%%%%%%%%%%%%%%%%%%%%")
    for (i,br) in sort(OrderedCollections.OrderedDict(data_mip["branchdc_ne"]), by=x->parse(Int64,x))
        println(string(i)*": "*string(br["fbusdc"])*" - "*string(br["tbusdc"])*" MVA: "*string(br["rateA"])*" Length: "*string(br["length"])*" cost: "*string(br["cost"])*" status: "*string(br["status"]))
    end
    println("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
end
########################################## Generators ##############################################################

function divide_onshore_offshore(s)
	s["onshore_nodes"]=[];s["offshore_nodes"]=[];
    markets_wfs=[String[],String[]]#UK,DE,DK must be in same order as .m file gens
    for (k,cuntree) in enumerate(s["nodes"][!,"country"])
        if (s["nodes"][!,"type"][k]==1)
            push!(markets_wfs[1],cuntree);push!(s["onshore_nodes"],k);
        elseif (s["nodes"][!,"type"][k]==2)
            push!(s["onshore_nodes"],k);
        elseif (s["nodes"][!,"type"][k]==0)
            push!(markets_wfs[2],cuntree);push!(s["offshore_nodes"],k);
        end
    end
	return s, markets_wfs
end

function gen_types_IEEE(data,scenario_data,s)
	s, markets_wfs = divide_onshore_offshore(s)
	base_gens=deepcopy(data["gen"])

    #creating space
    s["map_gen_types"]=Dict{String,Any}();push!(s["map_gen_types"],"type"=>Tuple[]);
	all_gens=Dict{String, Any}()
	push!(all_gens,"onshore"=>Dict())
	for (gen,country) in enumerate(markets_wfs[1])

        #creating space!
		push!(all_gens["onshore"],country=>Dict())
		if !(haskey(s["map_gen_types"],"countries"));push!(s["map_gen_types"],"countries"=>Dict());end
		if !(haskey(s["map_gen_types"]["countries"],country));push!(s["map_gen_types"]["countries"],country=>[]);end

		for (t,type) in enumerate(scenario_data["Generation"]["keys"])
			generator_number=string((gen-1)*length(scenario_data["Generation"]["keys"])+t)
			push!(all_gens["onshore"][country],type=>Dict())
			push!(all_gens["onshore"][country][type],generator_number=>copy(base_gens[string(gen)]))
			all_gens["onshore"][country][type][generator_number]["source_id"]=["gen",parse(Int64,generator_number)]
			all_gens["onshore"][country][type][generator_number]["index"]=parse(Int64,generator_number)
			all_gens["onshore"][country][type][generator_number]["gen_status"]=1
			push!(s["map_gen_types"]["type"],(generator_number,type))
			push!(s["map_gen_types"]["countries"][country],generator_number)
		end
	end

	push!(all_gens,"offshore"=>Dict())
	for (gen,country) in enumerate(markets_wfs[2])
		if !(haskey(all_gens["offshore"],country))
			push!(all_gens["offshore"],country=>Dict());end
		if !(haskey(s["map_gen_types"],"offshore"));push!(s["map_gen_types"],"offshore"=>Dict());end
		if !(haskey(s["map_gen_types"]["offshore"],country));push!(s["map_gen_types"]["offshore"],country=>[]);end
		generator_number=string(length(all_gens["onshore"])*length(scenario_data["Generation"]["keys"])+gen)
		push!(all_gens["offshore"][country],generator_number=>copy(base_gens[string(length(markets_wfs[1])+gen)]))
		all_gens["offshore"][country][generator_number]["source_id"]=["gen",parse(Int64,generator_number)]
		all_gens["offshore"][country][generator_number]["index"]=parse(Int64,generator_number)
		all_gens["offshore"][country][generator_number]["gen_status"]=1
		push!(s["map_gen_types"]["type"],(generator_number,"Offshore Wind"))
		push!(s["map_gen_types"]["offshore"][country],generator_number)
	end
    s["map_gen_types"]["markets"]=markets_wfs
	s["map_gen_types"]["costs"]=scenario_data["Generation"]["costs"]
    return all_gens, s
end



################################################ Converters #####################################
#adds DC grid to PMACDC

function additional_params_PMACDC(data)
    _PMACDC.process_additional_data!(data)#add extra DC model data
    converter_parameters_rxb(data)#sets converter parameters for loss calc
end


#Converts parameters of a converter - left over from Jay Dave
function converter_parameters_rxb(data)
    for (c,conv) in data["convdc_ne"]

        bus = conv["busac_i"]
        base_kV = data["bus"]["$bus"]["base_kv"]
        base_S = sqrt((100*conv["Pacmax"])^2+(100*conv["Qacmax"])^2) #base MVA = 100
        base_Z = base_kV^2/base_S # L-L votlage/3 phase power
        base_Y= 1/base_Z
        conv["xtf"] = 0.10*100/base_S #new X =old X *(100MVA/old Sbase)
        conv["rtf"] = conv["xtf"]/100
        conv["bf"] = 0.08*base_S/100
        conv["xc"] = 0.07*100/base_S #new X =old X *(100MVA/old Zbase)
        conv["rc"] = conv["xc"]/100 #new X =old X *(100MVA/old Zbase)
        rtf = conv["rtf"]
        xtf = conv["xtf"]
        bf = conv["bf"]
        Pmax = conv["Pacmax"]
        Pmin =  conv["Pacmin"]
        Qmax = conv["Qacmax"]
        Qmin =  conv["Qacmin"]

        conv["Imax"] = sqrt(Pmax^2+Qmax^2)
        xc = conv["xc"]
        rc = conv["rc"]
        Imax = conv["Imax"]

    end
    for (c,conv) in data["convdc"]

        bus = conv["busac_i"]
        base_kV = data["bus"]["$bus"]["base_kv"]
        base_S = sqrt((100*conv["Pacmax"])^2+(100*conv["Qacmax"])^2) #base MVA = 100
        base_Z = base_kV^2/base_S # L-L votlage/3 phase power
        base_Y= 1/base_Z
        conv["xtf"] = 0.10*100/base_S #new X =old X *(100MVA/old Sbase)
        conv["rtf"] = conv["xtf"]/100
        conv["bf"] = 0.08*base_S/100
        conv["xc"] = 0.07*100/base_S #new X =old X *(100MVA/old Zbase)
        conv["rc"] = conv["xc"]/100 #new X =old X *(100MVA/old Zbase)
        rtf = conv["rtf"]
        xtf = conv["xtf"]
        bf = conv["bf"]
        Pmax = conv["Pacmax"]
        Pmin =  conv["Pacmin"]
        Qmax = conv["Qacmax"]
        Qmin =  conv["Qacmin"]

        conv["Imax"] = sqrt(Pmax^2+Qmax^2)
        xc = conv["xc"]
        rc = conv["rc"]
        Imax = conv["Imax"]

    end
end


############################################# Convex solution to MIP ###############################################
function convex2mip(result_mip, data, mn_data, s)
    s["agent"]=""
    s["relax_problem"]=false
    s["output"]["duals"]=false
    if (s["AC"]=="1")
        data["ne_branch"]=convex2mip_AC(result_mip, data);end
    data["branchdc_ne"]=convex2mip_DC(result_mip, data)

    for (k,nw) in mn_data["nw"]
        br_nes=deepcopy(data["ne_branch"])
        br_dc_nes=deepcopy(data["branchdc_ne"])
        br_nes2=Dict{String,Any}();br_dc_nes2=Dict{String,Any}()
        for (i,(k,br_ne)) in enumerate(br_nes)
            br_ne["construction_cost"]=nw["ne_branch"][k]["construction_cost"]
            br_ne["source_id"][2]=i
            br_ne["br_status"]= s["AC"]=="0" ? 0 : 1
            push!(br_nes2,string(i)=>br_ne)
        end
        for (i,(k,br_dc_ne)) in enumerate(br_dc_nes)
            br_dc_ne["cost"]=nw["branchdc_ne"][k]["cost"]
            br_dc_ne["source_id"][2]=i
            br_dc_ne["br_status"]=1
            push!(br_dc_nes2,string(i)=>br_dc_ne)
        end
        nw["ne_branch"]=deepcopy(br_nes2)
        nw["branchdc_ne"]=deepcopy(br_dc_nes2)
        for (i,br) in nw["branch"]
            br["br_status"]=0
        end
        for (i,br) in nw["branchdc"]
            br["status"]=0
        end
    end
    data["ne_branch"]=mn_data["nw"]["1"]["ne_branch"]
    data["branchdc_ne"]=mn_data["nw"]["1"]["branchdc_ne"]
    return mn_data, data, s
end


function convex2mip_DC(result_mip, data)
    dc_cables=Dict{String,Any}()
    for (j,dc_br) in result_mip["solution"]["nw"][string(length(result_mip["solution"]["nw"]))]["branchdc"]
        dc_min=[];dc_max=[]
        for (k,dc_br_ne) in data["branchdc_ne"]
            if (dc_br_ne["fbusdc"]==data["branchdc"][j]["fbusdc"] && dc_br_ne["tbusdc"]==data["branchdc"][j]["tbusdc"])
                dif=dc_br["p_rateA"]-dc_br_ne["rateA"]

                if (dif>0)
                    push!(dc_min,(k,dif))
                else
                    push!(dc_max,(k,dif))
                end
            end
        end
        if (length(last.(dc_min))>0)
            push!(dc_cables, first.(dc_min)[argmin(last.(dc_min))] => data["branchdc_ne"][first.(dc_min)[argmin(last.(dc_min))]])
        end
        if (length(last.(dc_max))>0)
            push!(dc_cables, first.(dc_max)[argmax(last.(dc_max))] => data["branchdc_ne"][first.(dc_max)[argmax(last.(dc_max))]])
        end
    end
    dc_cables=unique_candidateIC_DC(dc_cables)
    return dc_cables
end

function convex2mip_AC(result_mip, data)
    ac_cables=Dict{String,Any}()
    for (j,ac_br) in result_mip["solution"]["nw"][string(length(result_mip["solution"]["nw"]))]["branch"]
        ac_min=[];ac_max=[]
        for (k,ac_br_ne) in data["ne_branch"]
            if (ac_br_ne["f_bus"]==data["branch"][j]["f_bus"] && ac_br_ne["t_bus"]==data["branch"][j]["t_bus"])
                dif=ac_br["p_rateAC"]-ac_br_ne["rate_a"]

                if (dif>0)
                    push!(ac_min,(k,dif))
                else
                    push!(ac_max,(k,dif))
                end
            end
        end
        if (length(last.(ac_min))>0)
            push!(ac_cables, first.(ac_min)[argmin(last.(ac_min))] => data["ne_branch"][first.(ac_min)[argmin(last.(ac_min))]])
        end
        if (length(last.(ac_max))>0)
            push!(ac_cables, first.(ac_max)[argmax(last.(ac_max))] => data["ne_branch"][first.(ac_max)[argmax(last.(ac_max))]])
        end
    end
    ac_cables=unique_candidateIC_AC(ac_cables)
    return ac_cables
end

function remove_integers(result_mip,mn_data,data,s)
    for (sc,tss) in sort(OrderedCollections.OrderedDict(mn_data["scenario"]), by=x->parse(Int64,x))
        for (t,ts) in sort(OrderedCollections.OrderedDict(tss), by=x->parse(Int64,x))
            #dc cables
            for (bc,brc) in data["branchdc"]
                for (b,br) in result_mip["solution"]["nw"][string(ts)]["branchdc_ne"];
                    if (brc["fbusdc"]==data["branchdc_ne"][b]["fbusdc"] && brc["tbusdc"]==data["branchdc_ne"][b]["tbusdc"])
                        if (br["isbuilt"]>0)
                            s["xd"]["branchdc"][bc]["rateA"][1,ts]=data["branchdc_ne"][b]["rateA"]
                            s["xd"]["branchdc"][bc]["r"][1,ts]=data["branchdc_ne"][b]["r"]
                            s["xd"]["branchdc"][bc]["cost"][1,ts]=0.0;
                            break
                        else
                            s["xd"]["branchdc"][bc]["cost"][1,ts]=0.0;
                            s["xd"]["branchdc"][bc]["rateA"][1,ts]=0.0
                        end
                    end;end;end

            #ac cables
            for (bc,brc) in data["branch"]
                if (haskey(result_mip["solution"]["nw"][string(ts)],"ne_branch"))
                for (b,br) in result_mip["solution"]["nw"][string(ts)]["ne_branch"];
                        if (brc["f_bus"]==data["ne_branch"][b]["f_bus"] && brc["t_bus"]==data["ne_branch"][b]["t_bus"])
                                if (br["built"]>0)
                                    s["xd"]["branch"][bc]["rateA"][1,ts]=data["ne_branch"][b]["rate_a"]
                                    s["xd"]["branch"][bc]["br_r"][1,ts]=data["ne_branch"][b]["br_r"]
                                    s["xd"]["branch"][bc]["cost"][1,ts]=0.0;
                                    break
                                else
                                    s["xd"]["branch"][bc]["rateA"][1,ts]=0
                                    s["xd"]["branch"][bc]["cost"][1,ts]=0.0;
                                end

                    end;end;end;end
    end;end
    return s, mn_data
end

function remove_integers_new_market(result_mip,mn_data,data,s)
    for (sc,tss) in sort(OrderedCollections.OrderedDict(mn_data["scenario"]), by=x->parse(Int64,x))
        for (t,ts) in sort(OrderedCollections.OrderedDict(tss), by=x->parse(Int64,x))
            
            #dc cables
            for (bs,brs) in result_mip["solution"]["nw"][string(ts)]["branchdc"];
                if (brs["p_rateA"]>0.5)
                    brd=data["branchdc"][bs]
                    for (b_ne,br_ne) in data["branchdc_ne"]
                        if (brd["fbusdc"]==br_ne["fbusdc"] && brd["tbusdc"]==br_ne["tbusdc"] && (brs["p_rateA"] <= br_ne["rateA"]+1 && br_ne["rateA"]-1 <= brs["p_rateA"]))
                            s["xd"]["branchdc"][bs]["rateA"][1,ts]=brs["p_rateA"]
                            s["xd"]["branchdc"][bs]["r"][1,ts]=br_ne["r"]
                            s["xd"]["branchdc"][bs]["cost"][1,ts]=0.0;
                        end
                    end;
                else
                    s["xd"]["branchdc"][bs]["rateA"][1,ts]=0.0
                    s["xd"]["branchdc"][bs]["cost"][1,ts]=0.0;
                end;
            end;

            #ac cables
            for (bs,brs) in result_mip["solution"]["nw"][string(ts)]["branch"];
                if (brs["p_rateAC"]>0.5)
                    brd=data["branch"][bs]
                    for (b_ne,br_ne) in data["ne_branch"]
                        if (brd["f_bus"]==br_ne["f_bus"] && brd["t_bus"]==br_ne["t_bus"] && (brs["p_rateAC"] <= br_ne["rate_a"]+1 && br_ne["rate_a"]-1 <= brs["p_rateAC"]))
                            s["xd"]["branch"][bs]["rateA"][1,ts]=brs["p_rateAC"]
                            s["xd"]["branch"][bs]["br_r"][1,ts]=br_ne["br_r"]
                            s["xd"]["branch"][bs]["cost"][1,ts]=0.0;
                        end
                    end;
                else
                    s["xd"]["branch"][bs]["rateA"][1,ts]=0.0
                    s["xd"]["branch"][bs]["cost"][1,ts]=0.0;
                end;
            end;
    end;end
    return s, mn_data
end


function set_intra_zonal_grid(result_mip,mn_data,s)
    for (sc,tss) in sort(OrderedCollections.OrderedDict(mn_data["scenario"]), by=x->parse(Int64,x))
        for (t,ts) in sort(OrderedCollections.OrderedDict(tss), by=x->parse(Int64,x))
            #dc cables
            for (b,br) in result_mip["solution"]["nw"][string(ts)]["branchdc_ne"];
                if (is_intra_zonal(mn_data["nw"][string(ts)]["branchdc_ne"][b]["fbusdc"],mn_data["nw"][string(ts)]["branchdc_ne"][b]["tbusdc"],s["home_market"]))
                    if (br["isbuilt"]>0)
                            s["xd"]["branchdc_ne"][b]["cost"][1,ts]=0.0;
                    else
                            s["xd"]["branchdc_ne"][b]["cost"][1,ts]=s["xd"]["branchdc_ne"][b]["cost"][1,ts]*100;
                    end
                end;end;

            #ac cables
            if (haskey(result_mip["solution"]["nw"][string(ts)],"ne_branch"))
            for (b,br) in result_mip["solution"]["nw"][string(ts)]["ne_branch"];
                if (is_intra_zonal(mn_data["nw"][string(ts)]["ne_branch"][b]["f_bus"],mn_data["nw"][string(ts)]["ne_branch"][b]["t_bus"],s["home_market"]))
                if (br["built"]>0)
                        s["xd"]["ne_branch"][b]["cost"][1,ts]=0.0;
                else
                    s["xd"]["ne_branch"][b]["construction_cost"][1,ts]=s["xd"]["ne_branch"][b]["construction_cost"][1,ts]*100;
                end;end;
            end;end
            #converters
            if (haskey(result_mip["solution"]["nw"][string(ts)],"convdc"))
                for (c,cnv) in result_mip["solution"]["nw"][string(ts)]["convdc"];
                    if (cnv["p_pacmax"]>0)
                            s["xd"]["convdc"][c]["Pacmin"][1,ts]=cnv["p_pacmax"];
                    end;end;end
    end;end
    return mn_data, s
end

function set_inter_zonal_grid(result_mip,mn_data,s)
    for (sc,tss) in sort(OrderedCollections.OrderedDict(mn_data["scenario"]), by=x->parse(Int64,x))
        for (t,ts) in sort(OrderedCollections.OrderedDict(tss), by=x->parse(Int64,x))
            #dc cables
            for (b,br) in result_mip["solution"]["nw"][string(ts)]["branchdc_ne"];
                if !(is_intra_zonal(mn_data["nw"][string(ts)]["branchdc_ne"][b]["fbusdc"],mn_data["nw"][string(ts)]["branchdc_ne"][b]["tbusdc"],s["home_market"]))
                    if (br["isbuilt"]>0)
                            s["xd"]["branchdc_ne"][b]["cost"][1,ts]=0.0;
                    else
                            s["xd"]["branchdc_ne"][b]["cost"][1,ts]=s["xd"]["branchdc_ne"][b]["cost"][1,ts]*100;
                    end
                end;end;

            #ac cables
            if (haskey(result_mip["solution"]["nw"][string(ts)],"ne_branch"))
            for (b,br) in result_mip["solution"]["nw"][string(ts)]["ne_branch"];
                if !(is_intra_zonal(mn_data["nw"][string(ts)]["ne_branch"][b]["f_bus"],mn_data["nw"][string(ts)]["ne_branch"][b]["t_bus"],s["home_market"]))
                if (br["built"]>0)
                        s["xd"]["ne_branch"][b]["construction_cost"][1,ts]=0.0;
                else
                    s["xd"]["ne_branch"][b]["construction_cost"][1,ts]=s["xd"]["ne_branch"][b]["construction_cost"][1,ts]*100;
                end;end;
            end;end
    end;end
    return mn_data, s
end


#=function set_rebalancing_grid(result_mip,mn_data,s)
    for (sc,tss) in sort(OrderedCollections.OrderedDict(mn_data["scenario"]), by=x->parse(Int64,x))
        for (t,ts) in sort(OrderedCollections.OrderedDict(tss), by=x->parse(Int64,x))
            #dc cables
            for (b,br) in result_mip["solution"]["nw"][string(ts)]["branchdc_ne"];
                if (br["isbuilt"]>0)
                        s["xd"]["branchdc_ne"][b]["cost"][1,ts]=0.0;
                    end
                end;

            #ac cables
            if (haskey(result_mip["solution"]["nw"][string(ts)],"ne_branch"))
            for (b,br) in result_mip["solution"]["nw"][string(ts)]["ne_branch"];
                if (br["built"]>0)
                        s["xd"]["ne_branch"][b]["construction_cost"][1,ts]=0.0;
                end;end;end
            #converters
            if (haskey(result_mip["solution"]["nw"][string(ts)],"convdc"))
                for (c,cnv) in result_mip["solution"]["nw"][string(ts)]["convdc"];
                    if (cnv["p_pacmax"]>0)
                            s["xd"]["convdc"][c]["Pacmin"][1,ts]=round(cnv["p_pacmax"]);
                            s["xd"]["convdc"][c]["Pacmax"][1,ts]=round(cnv["p_pacmax"]);
                    else
                            s["xd"]["convdc"][c]["Pacmin"][1,ts]=0;
                            s["xd"]["convdc"][c]["Pacmax"][1,ts]=0;
                    end;end;end
            #storage
            if (haskey(result_mip["solution"]["nw"][string(ts)],"storage"))
                for (b,strg) in result_mip["solution"]["nw"][string(ts)]["storage"];
                    if (strg["e_absmax"]>0)
                            s["xd"]["storage"][b]["pmin"][1,ts]=round(strg["e_absmax"]);
                            s["xd"]["storage"][b]["pmax"][1,ts]=round(strg["e_absmax"]);
                    else
                            s["xd"]["storage"][b]["pmin"][1,ts]=0;
                            s["xd"]["storage"][b]["pmax"][1,ts]=0;
                    end;end;end
            for wf in s["wfz"]
                s["xd"]["gen"][string(first(wf))]["wf_pmax"][1,ts]=round(result_mip["solution"]["nw"][string(ts)]["gen"][string(first(wf))]["wf_pacmax"]);end;
                #s["xd"]["gen"][string(first(wf))]["wf_pmax"][1,ts]=result_mip["solution"]["nw"][string(1)]["gen"][string(first(wf))]["wf_pacmax"];end;
    end;end
    return mn_data, s
end=#

function set_rebalancing_grid(result_mip,mn_data,s)
    for (sc,tss) in sort(OrderedCollections.OrderedDict(mn_data["scenario"]), by=x->parse(Int64,x))
        for (t,ts) in sort(OrderedCollections.OrderedDict(tss), by=x->parse(Int64,x))
            #dc cables
            for (b,br) in result_mip["solution"]["nw"][string(ts)]["branchdc_ne"];
                if (br["isbuilt"]>0.9)
                        s["xd"]["branchdc_ne"][b]["cost"][1,ts]=0.0;
                end
            end;

            #ac cables
            if (haskey(result_mip["solution"]["nw"][string(ts)],"ne_branch"))
                for (b,br) in result_mip["solution"]["nw"][string(ts)]["ne_branch"];
                    if (br["built"]>0.9)
                            s["xd"]["ne_branch"][b]["construction_cost"][1,ts]=0.0;
                    end;end;end
            #converters
            if (haskey(result_mip["solution"]["nw"][string(ts)],"convdc"))
                for (c,cnv) in result_mip["solution"]["nw"][string(ts)]["convdc"];
                    if (cnv["p_pacmax"]>0)
                            s["xd"]["convdc"][c]["Pacmin"][1,ts]=round(cnv["p_pacmax"],digits = 6);
                            s["xd"]["convdc"][c]["Pacmax"][1,ts]=round(cnv["p_pacmax"],digits = 6);
                    else
                            s["xd"]["convdc"][c]["Pacmin"][1,ts]=0;
                            s["xd"]["convdc"][c]["Pacmax"][1,ts]=0;
                    end;end;end
            #storage
            if (haskey(result_mip["solution"]["nw"][string(ts)],"storage"))
                for (b,strg) in result_mip["solution"]["nw"][string(ts)]["storage"];
                    if (strg["e_absmax"]>0)
                            s["xd"]["storage"][b]["pmin"][1,ts]=round(strg["e_absmax"],digits = 6);
                            s["xd"]["storage"][b]["pmax"][1,ts]=round(strg["e_absmax"],digits = 6);
                    else
                            s["xd"]["storage"][b]["pmin"][1,ts]=0;
                            s["xd"]["storage"][b]["pmax"][1,ts]=0;
                    end;end;end
            for wf in s["wfz"]
                s["xd"]["gen"][string(first(wf))]["wf_pmax"][1,ts]=round(result_mip["solution"]["nw"][string(ts)]["gen"][string(first(wf))]["wf_pacmax"],digits = 6);
            end;end;
    end
    return mn_data, s
end



function combine_solutions(result_mip_hm,result_mip_wf)
    for (n,nw) in result_mip_wf["solution"]["nw"]
        for (b,br) in nw["branchdc_ne"]
            if (br["isbuilt"]==1)
                result_mip_hm["solution"]["nw"][n]["branchdc_ne"][b]=br
            end
        end
        for (b,br) in nw["ne_branch"]
            if (br["built"]==1)
                result_mip_hm["solution"]["nw"][n]["ne_branch"][b]=br
            end
        end
    end
    return result_mip_hm
end

function hm_market_prices(result_mip, result_mip_hm_prices)
    for (n,nw) in result_mip_hm_prices["solution"]["nw"]
        for (b,bs) in nw["bus"]
            result_mip["solution"]["nw"][n]["bus"][b]["lam_kcl_r"]=deepcopy(bs["lam_kcl_r"])
        end
    end
    return result_mip
end

function set_cable_impedance(data,result_mip)
    last_step=result_mip["solution"]["nw"][string(maximum(parse.(Int64,keys(result_mip["solution"]["nw"]))))]
    #DC cables
    for (b_ne,br_ne) in last_step["branchdc_ne"]
        if (br_ne["isbuilt"]==1)
            for (b,br) in data["branchdc"]
                if (br["fbusdc"]==data["branchdc_ne"][b_ne]["fbusdc"] && br["tbusdc"]==data["branchdc_ne"][b_ne]["tbusdc"])
                    data["branchdc"][b]["r"]=data["branchdc_ne"][b_ne]["r"]
                end
            end
    end;end
    #AC cables
    #NOTE uncomment AC cables!!!!!!!!!!!!!!!!! 1043 post_process.jl
    if (haskey(last_step,"ne_branch"))
        for (b_ne,br_ne) in last_step["ne_branch"]
            if (br_ne["built"]==1)
                for (b,br) in data["branch"]
                    if (br["f_bus"]==data["ne_branch"][b_ne]["f_bus"] && br["t_bus"]==data["ne_branch"][b_ne]["t_bus"])
                        data["branch"][b]["br_r"]=data["ne_branch"][b_ne]["br_r"]
                        data["branch"][b]["br_x"]=data["ne_branch"][b_ne]["br_x"]
                    end
                end
        end;end;end
    return data
end

#seperates wfs from genz and defines markets/wfs zones
function data_update_IEEE(s,result_mip)
    data, s = get_topology_data_IEEE(s)#topology.m file
    scenario_data = get_scenario_data_IEEE(s)#scenario time series
	###########################################################################
	all_gens,s = gen_types_IEEE(data,scenario_data,s)
    #################### Calculates cable options for AC lines
    data = AC_cable_options_IEEE(data,s["candidate_ics_ac"],s["ics_ac"],data["baseMVA"])
    #################### Calculates cable options for DC lines
    data = DC_cable_options_IEEE(data,s["candidate_ics_dc"],s["ics_dc"],data["baseMVA"])
    ############# Sets convex able impedance to the MIP solution ##############
    data = set_cable_impedance(data, result_mip)
    additional_params_PMACDC(data)
    print_topology_data_AC(data,s["map_gen_types"]["markets"])#print to verify
    print_topology_data_DC(data,s["map_gen_types"]["markets"])#print to verify
    ##################### load time series data ##############################
    scenario_data = load_time_series_gentypes_IEEE(s, scenario_data)
    ##################### multi period setup #################################
	s = update_settings_wgenz(s, data)
    mn_data, s  = multi_period_setup_wgen_type_IEEE(scenario_data, data, all_gens, s);
	push!(s,"max_invest_per_year"=>max_invest_per_year(s))
    return  mn_data, data, s
end

function data_setup_IEEE(s)
    data, s = get_topology_data_IEEE(s)#topology.m file
    scenario_data = get_scenario_data_IEEE(s)#scenario time series
	###########################################################################
	all_gens,s = gen_types_IEEE(data,scenario_data,s)
    #################### Calculates cable options for AC lines
    data = AC_cable_options_IEEE(data,s["candidate_ics_ac"],s["ics_ac"],data["baseMVA"])
    #################### Calculates cable options for DC lines
    data = DC_cable_options_IEEE(data,s["candidate_ics_dc"],s["ics_dc"],data["baseMVA"])
    if (haskey(s, "home_market") && length(s["home_market"])>0);data = keep_only_hm_cables(s,data);end#if home market reduce to only those in
    additional_params_PMACDC(data)
    print_topology_data_AC(data,s["map_gen_types"]["markets"])#print to verify
    print_topology_data_DC(data,s["map_gen_types"]["markets"])#print to verify
    ##################### load time series data ##############################
    scenario_data = load_time_series_gentypes_IEEE(s, scenario_data)
    ##################### multi period setup #################################
	s = update_settings_wgenz(s, data)
    mn_data, s  = multi_period_setup_wgen_type_IEEE(scenario_data, data, all_gens, s);
	push!(s,"max_invest_per_year"=>max_invest_per_year(s))
    return  mn_data, data, s
end

################################################################################
function hidden_settings(s)
    push!(s,"AC"=>"1")#,0=false, 1=true
    push!(s,"output" => Dict("branch_flows" => false))
    push!(s,"eps"=>0.0001)
    push!(s,"beta"=>5.5)
    push!(s,"conv_losses_mp" => true)
    push!(s,"process_data_internally" => false)
    push!(s,"onshore_grid"=>true)
    return s
end

function get_topology_data(s, scenario_data)
    if (haskey(s,"ntc_mva_scale"))
        ntc_mva_scale=s["ntc_mva_scale"]
    else
        ntc_mva_scale=1.0
    end
    ################# Load topology files ###################################
    #topology_df(s["rt_ex"], s["relax_problem"], s["AC"], scenario_data)#creates .m file
    topology_df(s, scenario_data)#creates .m file
    data, s["ics_ac"], s["ics_dc"], s["nodes"] = filter_mfile_cables(s["rt_ex"], scenario_data, ntc_mva_scale)#loads resulting topology and filters for candidate cables
    return data, s
end


function topology_df(s, scenario_data)
	ac_cable_df = DataFrames.DataFrame(XLSX.readtable(s["rt_ex"]*"input.xlsx", "CABLES_AC_SET_UP"))
	dc_cable_df = DataFrames.DataFrame(XLSX.readtable(s["rt_ex"]*"input.xlsx", "CABLES_DC_SET_UP"))
	rem_df = DataFrames.DataFrame(XLSX.readtable(s["rt_ex"]*"input.xlsx", "REMAINDER"))
	if (haskey(s,"collection_circuit") && s["collection_circuit"]==true)
		nodes_df = DataFrames.DataFrame(XLSX.readtable(s["rt_ex"]*"input.xlsx", "node_generation"))
		rem_df, scenario_data = pcc_connection(rem_df, nodes_df, scenario_data)
	else
		rem_df, scenario_data = surrounding_countries(rem_df, scenario_data)
	end
	ppf_mainACDCStorage2mfile(rem_df, ac_cable_df, dc_cable_df, s)
end

function surrounding_countries(rem_df, scenario_data)
	start_bus=parse(Int64,rem_df[!,:bus][end])
	_buses=[]
	for (count,nodes) in enumerate(scenario_data["Generation"]["nodes"][!,:node_id])
	_bus=start_bus+count
	push!(_buses,_bus)
	_row=[string(_bus),string(_bus),string(_bus)*" 1",missing,string(0),"1 0",missing,string(_bus)*" "*string(_bus),string(_bus)*" "*string(_bus)*" 19.25",string(_bus),"39"]
	push!(rem_df,_row)
	end
	scenario_data["Generation"]["nodes"][!,:bus]=_buses
	return rem_df, scenario_data
end

function filter_mfile_cables(rt_ex, scenario_data, ntc_mva_scale::Float64=1.0)
    nodes = DataFrames.DataFrame(XLSX.readtable(rt_ex*"input.xlsx", "node_generation"))
	edges = DataFrames.DataFrame(XLSX.readtable(rt_ex*"input.xlsx", "connections_acdc"))
    #try edges_existing = DataFrames.DataFrame(XLSX.readtable(rt_ex*"input.xlsx", "existing_lines")...) catch; println("No onshore net transfer capacities specified.") end
    edges_existing = add_ntc_edges(nodes,scenario_data, ntc_mva_scale)
    nodes = add_ntc_nodes(nodes,scenario_data)
    file = rt_ex*"topology.m"
	data = PowerModels.parse_file(file)
    data,edges_existing=add_ntcs(data,edges_existing)
	data,ics_ac=filter_AClines(data,edges,nodes)
	data,ics_dc=filter_DClines(data,edges,nodes,edges_existing)
    return data, ics_ac, ics_dc, nodes
end

#**#
function add_ntc_edges(nodes,scenario_data, mva_scale::Float64=1.0)
    edges_existing = DataFrames.DataFrame("DC_from"=>[], "DC_to"=>[], "DC_mva"=>[], "AC_from"=>[], "AC_to"=>[], "AC_mva"=>[])
    #adds TYNPD grid
    for _row in eachrow(scenario_data["Generation"]["ntcs"])
        end_points=_row[Symbol("Border Names Based on PEMMDB 3.0 convention")]
        start_end=split(end_points,"-")
        capacity=_row[Symbol("Final Value for NTC (MW)")]*mva_scale
        bus_start=filter(Symbol("node_id")=>x->x==first(start_end),scenario_data["Generation"]["nodes"])[!,:bus]
        bus_end=filter(Symbol("node_id")=>x->x==last(start_end),scenario_data["Generation"]["nodes"])[!,:bus]
        if !(isempty(bus_start) || isempty(bus_end))
            push!(edges_existing, [Int64(bus_start[1]), Int64(bus_end[1]), Int64(capacity), missing, missing, missing])
        end
    end
    #adds copper plate between dummy nodes and market nodes
    dummy_nodes=filter(Symbol("type")=>x->x==2,nodes)
    for dummy_node in eachrow(dummy_nodes)
        dummy_bus=dummy_node[:node]
        dummy_country=dummy_node[:country]
        country_row=filter(Symbol("node_id")=>x->x==dummy_country,scenario_data["Generation"]["nodes"])
        country_bus=country_row[!,:bus][1]
        if (length(dummy_bus)!=0 && length(country_bus)!=0)
            push!(edges_existing, [Int64(dummy_bus), Int64(country_bus), 50000, missing, missing, missing])
        end
    end
    return edges_existing
end

#**#
function add_ntc_nodes(nodes,scenario_data)
    nodes
    nodes_existing = DataFrames.DataFrame("node"=>[], "gen"=>[], "load"=>[], "node_price"=>[], "type"=>[], "country"=>[], "lat"=>[], "long"=>[], "gen_invest"=>[], "storage"=>[])
    for _row in eachrow(scenario_data["Generation"]["nodes"])
        _node=_row[:bus]
        _node_id=_row[:node_id]
        _lat=_row[:latitude]
        _long=_row[:longitude]
        push!(nodes_existing,[_node,1,0,0,1,_node_id,_lat,_long,0, 1])
    end
    nodes=vcat(nodes,nodes_existing)
    return nodes
end 

function reduce_nonstoch_gens(scenario_data)
    new_gens_map=reduce_to_nonstoch_costs_keys(scenario_data)
    reduce_to_nonstoch_scenarios(scenario_data,new_gens_map) 
end

#***#
function reduce_to_nonstoch_scenarios(scenario_data,new_gens_map)
    for scene in keys(scenario_data["Generation"]["Scenarios"])
        #for year in keys(scenario_data["Generation"]["Scenarios"][scene])
            for country in keys(scenario_data["Generation"]["Scenarios"][scene])
                non_stoch_totals=Dict()
                for gen_type in eachrow(scenario_data["Generation"]["Scenarios"][scene][country])
                    for non_stoch in keys(new_gens_map)
                        if !(haskey(non_stoch_totals, non_stoch))
                            push!(non_stoch_totals,non_stoch=>0)
                        end
                        if issubset([gen_type[:Generation_Type]],new_gens_map[non_stoch])
                            if (non_stoch!="SLACK")
                                non_stoch_totals[non_stoch]=non_stoch_totals[non_stoch]+gen_type[:Capacity]
                            else
                                non_stoch_totals[non_stoch]=gen_type[:Capacity]
                            end
                        end
                    end
                end
                df=DataFrames.DataFrame(:Generation_Type=>String[],:Capacity=>Float64[])
                for gen_type in keys(non_stoch_totals)
                    if (non_stoch_totals[gen_type]!=0)
                        push!(df,[gen_type,non_stoch_totals[gen_type]])
                        #delete!(non_stoch_totals,gen_type)
                    end
                end
                scenario_data["Generation"]["Scenarios"][scene][country]=df
            end
        #end
    end
end

#***#
function reduce_to_nonstoch_costs_keys(scenario_data)
    costs=unique!([scenario_data["Generation"]["costs"][k] for k in keys(scenario_data["Generation"]["costs"])])#extract unique costs
    new_gens_map=Dict()
    new_gen_costs=Dict()
    for cost in costs
        k="nonStochGen"*string(cost)
        push!(new_gens_map,k=>[k_type for k_type in keys(scenario_data["Generation"]["costs"]) if (scenario_data["Generation"]["costs"][k_type]==cost && !(issubset([k_type],keys(scenario_data["Generation"]["RES"]))))])
        push!(new_gen_costs,k=>cost)
    end
    for k in keys(scenario_data["Generation"]["RES"])
        push!(new_gens_map,k=>[k])
        push!(new_gen_costs,k=>scenario_data["Generation"]["costs"][k])
    end
    k="nonStochGen"*string(scenario_data["Generation"]["costs"]["SLACK"])
    push!(new_gen_costs,"SLACK"=>new_gen_costs[k])
    push!(new_gens_map,"SLACK"=>["SLACK"])
    delete!(new_gen_costs,k)
    delete!(new_gens_map,k)
    scenario_data["Generation"]["costs"]=new_gen_costs
    scenario_data["Generation"]["keys"]=keys(new_gen_costs)
    return new_gens_map
end


#***#
#i="6";data["ne_branch"][i]
function AC_cable_options(data,s)
    candidate_ics_ac=s["candidate_ics_ac"]
    ics_ac=s["ics_ac"]
    pu=data["baseMVA"]
    kV=haskey(s,"collection_voltage") ? s["collection_voltage"] : 220
    z_base_ac=(data["bus"]["1"]["base_kv"])^2/pu
    data=additional_candidatesICS_AC(data,candidate_ics_ac,ics_ac)#adds additional candidates
    for (i,bac) in data["ne_branch"]
    data["ne_branch"][i]=candidateIC_cost_impedance_AC(bac,z_base_ac,pu,kV);end
    data["ne_branch"]=unique_candidateIC_AC(data["ne_branch"])#keep only unique candidates
	temp_cables_ne=Dict{String,Any}()
	temp_cables=Dict{String,Any}()
	cable_pu_costs=Dict{String,Any}()
	cable_pu_r=Dict{String,Any}()
	cable_pu_x=Dict{String,Any}()
    cable_rateA=Dict{String,Any}()

	for (i,acb) in enumerate(sort(OrderedCollections.OrderedDict(data["ne_branch"]), by=x->parse(Int64,x)))
		last(acb)["source_id"][2]=i
		#last(acb)["br_status"]=0
		push!(temp_cables_ne,string(i)=>last(acb))
		for (j,acb_con) in enumerate(sort(OrderedCollections.OrderedDict(data["branch"]), by=x->parse(Int64,x)))
			if (last(acb)["f_bus"]==last(acb_con)["f_bus"] && last(acb)["t_bus"]==last(acb_con)["t_bus"])
				last(acb_con)["source_id"][2]=j
				push!(temp_cables,string(j)=>last(acb_con))
				if (haskey(cable_pu_costs,string(last(acb_con)["f_bus"])*"_"*string(last(acb_con)["t_bus"])))
					push!(cable_pu_costs[string(last(acb_con)["f_bus"])*"_"*string(last(acb_con)["t_bus"])],last(acb)["construction_cost"]/(last(acb)["rate_a"]))
					push!(cable_pu_r[string(last(acb_con)["f_bus"])*"_"*string(last(acb_con)["t_bus"])],last(acb)["br_r"])
					push!(cable_pu_x[string(last(acb_con)["f_bus"])*"_"*string(last(acb_con)["t_bus"])],last(acb)["br_x"])
                    push!(cable_rateA[string(last(acb_con)["f_bus"])*"_"*string(last(acb_con)["t_bus"])],last(acb)["rate_a"])
				else
					push!(cable_pu_costs,string(last(acb_con)["f_bus"])*"_"*string(last(acb_con)["t_bus"])=>[last(acb)["construction_cost"]/(last(acb)["rate_a"])])
					push!(cable_pu_r,string(last(acb_con)["f_bus"])*"_"*string(last(acb_con)["t_bus"])=>[last(acb)["br_r"]])
					push!(cable_pu_x,string(last(acb_con)["f_bus"])*"_"*string(last(acb_con)["t_bus"])=>[last(acb)["br_x"]])
                    push!(cable_rateA,string(last(acb_con)["f_bus"])*"_"*string(last(acb_con)["t_bus"])=>[last(acb)["rate_a"]])
				end
				break
			end
		end
	end
	#println(cable_pu_costs)
	data["ne_branch"]=temp_cables_ne
	temp_cables2=Dict{String,Any}()
	for (i,acb) in enumerate(sort(OrderedCollections.OrderedDict(temp_cables), by=x->parse(Int64,x)))
		trms=length(cable_pu_costs[string(last(acb)["f_bus"])*"_"*string(last(acb)["t_bus"])])
		trms_total=sum(b for b in cable_pu_costs[string(last(acb)["f_bus"])*"_"*string(last(acb)["t_bus"])])

		trms_R=length(cable_pu_r[string(last(acb)["f_bus"])*"_"*string(last(acb)["t_bus"])])
		trms_total_R=sum(b for b in cable_pu_r[string(last(acb)["f_bus"])*"_"*string(last(acb)["t_bus"])])

		trms_X=length(cable_pu_x[string(last(acb)["f_bus"])*"_"*string(last(acb)["t_bus"])])
		trms_total_X=sum(b for b in cable_pu_x[string(last(acb)["f_bus"])*"_"*string(last(acb)["t_bus"])])

		last(acb)["br_r"]=(trms_total_R/trms_R)
		last(acb)["br_x"]=(trms_total_X/trms_X)
		last(acb)["cost"]=(trms_total/trms)
        last(acb)["rateA"]=last(acb)["rateB"]=last(acb)["rateC"]=maximum(b for b in cable_rateA[string(last(acb)["f_bus"])*"_"*string(last(acb)["t_bus"])])
		last(acb)["source_id"][2]=i
		push!(temp_cables2,string(i)=>last(acb))
        data["branch"][string(i)]=last(acb)
	end
	#data["branch"]=temp_cables2
    return data
end

function candidateIC_cost_impedance_AC(bac,z_base,s_base,kV::Int64=220)
    cb=_ECO.AC_cbl(bac["rate_a"], bac["length"],kV)
    bac["construction_cost"]=cb.costs.ttl
    bac["br_r"]=((cb.elec.ohm/cb.num)*cb.length)/z_base
    bac["br_x"]=((cb.elec.xl/cb.num)*cb.length)/z_base
    bac["rate_c"]=bac["rate_b"]=bac["rate_a"]=(cb.num*cb.elec.mva)/s_base
    return bac
end


#***#
function DC_cable_options(data,candidate_ics_dc,ics_dc,pu)
    z_base_dc=(data["busdc"]["1"]["basekVdc"])^2/pu
    data=additional_candidatesICS_DC(data,candidate_ics_dc,ics_dc)#adds additional candidates
    for (i,bdc) in data["branchdc_ne"]
    data["branchdc_ne"][i]=candidateIC_cost_impedance_DC(bdc,z_base_dc);end
    data["branchdc_ne"]=unique_candidateIC_DC(data["branchdc_ne"])#keep only unique candidates
	temp_cables_ne=Dict{String,Any}()
	temp_cables=Dict{String,Any}()
	cable_pu_costs=Dict{String,Any}()
	cable_pu_r=Dict{String,Any}()
    cable_rateA=Dict{String,Any}()
	for (i,acb) in enumerate(sort(OrderedCollections.OrderedDict(data["branchdc_ne"]), by=x->parse(Int64,x)))
		last(acb)["source_id"][2]=i
		push!(temp_cables_ne,string(i)=>last(acb))
		for (j,acb_con) in enumerate(sort(OrderedCollections.OrderedDict(data["branchdc"]), by=x->parse(Int64,x)))
			if (last(acb)["fbusdc"]==last(acb_con)["fbusdc"] && last(acb)["tbusdc"]==last(acb_con)["tbusdc"])
				last(acb_con)["source_id"][2]=j
				push!(temp_cables,string(j)=>last(acb_con))
				break
			end
		end
		if (haskey(cable_pu_costs,string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])))
			push!(cable_pu_costs[string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])],last(acb)["cost"]/(last(acb)["rateA"]/pu))
			push!(cable_pu_r[string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])],last(acb)["r"])
            push!(cable_rateA[string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])],last(acb)["rateA"])
		else
			push!(cable_pu_costs,string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])=>[last(acb)["cost"]/(last(acb)["rateA"]/pu)])
			push!(cable_pu_r,string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])=>[last(acb)["r"]])
            push!(cable_rateA,string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])=>[last(acb)["rateA"]])
		end
	end
	data["branchdc_ne"]=temp_cables_ne
	temp_cables2=Dict{String,Any}()
	for (i,acb) in enumerate(sort(OrderedCollections.OrderedDict(temp_cables), by=x->parse(Int64,x)))
		trms=length(cable_pu_costs[string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])])
		trms_total=sum(b for b in cable_pu_costs[string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])])
		trms_R=length(cable_pu_r[string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])])
		trms_total_R=sum(r for r in cable_pu_r[string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])])
		last(acb)["cost"]=trms_total/trms
		last(acb)["r"]=trms_total_R/trms_R
		last(acb)["source_id"][2]=i
        last(acb)["rateA"]=maximum(r for r in cable_rateA[string(last(acb)["fbusdc"])*"_"*string(last(acb)["tbusdc"])])
		push!(temp_cables2,string(i)=>last(acb))
	end
    for (k,b) in data["branchdc"]
        if (b["status"]==1)
            push!(temp_cables2,k=>deepcopy(b))
        end
    end
	data["branchdc"]=temp_cables2
    return data
end


#load Time series data
#***#
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

function reduce_DEMAND_to_k_days(_dict,_countries,_tss2keep);
    clmns2keep=[count for count in _countries];
    push!(clmns2keep,"time_stamp")
    for scenario in keys(_dict);
        #for yr in keys(_dict[scenario]);
            offset2020=Dates.Year(Dates.year(_dict[scenario][!,:time_stamp][1])-2020)
            _dict[scenario][!,:time_stamp]=_dict[scenario][!,:time_stamp].-offset2020;
            filter!(:time_stamp=>x->issubset([x],_tss2keep),_dict[scenario]);
            cs2delete=[name for name in names(_dict[scenario]) if !(issubset([name],clmns2keep))]
            DataFrames.select!(_dict[scenario],DataFrames.Not(cs2delete))
        #end;
    end
    return _dict
end


function reduce_RES_to_k_days(_dict,_s)
    #keep only k specified days, shift year to 2020 (base year for all simmulations)
    ks=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\yearly_cluster_4EU.jld2")
    tss2keep=[]
    #RES sources
    for country in unique(vcat(collect(keys(_dict["Offshore Wind"])),collect(keys(_dict["Onshore Wind"])),collect(keys(_dict["Solar PV"]))))
        for year in unique(vcat(collect(keys(_dict["Offshore Wind"][country])),collect(keys(_dict["Onshore Wind"][country])),collect(keys(_dict["Solar PV"][country]))))
            if haskey(_dict["Offshore Wind"][country],year)
                ts2keep=_s["k"]<365 ? ks[year][_s["k"]] : _dict["Offshore Wind"][country][year].time_stamp;
            elseif haskey(_dict["Onshore Wind"][country],year)
                ts2keep=_s["k"]<365 ? ks[year][_s["k"]] : _dict["Onshore Wind"][country][year].time_stamp;
            else haskey(_dict["Solar PV"][country],year)
                ts2keep=_s["k"]<365 ? ks[year][_s["k"]] : _dict["Solar PV"][country][year].time_stamp;end
            if (haskey(_s, "test") && _s["test"]==true)
                if (haskey(_s,"collection_circuit") && (_s["collection_circuit"]==true))
                    ts2keep=ts2keep[1:1]
                elseif (haskey(_s,"clustered") && (_s["clustered"]==true))
                    if (year=="2014")
                        ts2keep=Any[Dates.DateTime("2014-01-28T07:00:00"), Dates.DateTime("2014-02-01T20:00:00"), Dates.DateTime("2014-08-08T06:00:00"), Dates.DateTime("2014-11-20T18:00:00")]
                    elseif (year=="2015")
                        ts2keep=Any[Dates.DateTime("2015-02-23T19:00:00"), Dates.DateTime("2015-04-01T17:00:00"), Dates.DateTime("2015-08-12T07:00:00"), Dates.DateTime("2015-12-13T14:00:00")]
                    end
                    println(ts2keep)
                else
                    ts2keep=ts2keep[1:2]
                end
            end
            for res_type in keys(_dict)
                if haskey(_dict[res_type][country],year)
                filter!(:time_stamp=>x->issubset([x],ts2keep),_dict[res_type][country][year])
                if (!(isempty(_dict[res_type][country][year])) && haskey(_s, "test") && _s["test"]==true && res_type=="Offshore Wind")
                    if (haskey(_s,"collection_circuit") && (_s["collection_circuit"]==true))
                        _dict[res_type][country][year][!,Symbol(last(names(_dict[res_type][country][year])))]=[1]
                    elseif (haskey(_s,"clustered") && (_s["clustered"]==true))
                        #_dict[res_type][country][year][!,Symbol(last(names(_dict[res_type][country][year])))]=[1,0]
                        wind_profile=_dict[res_type][country][year][!,Symbol(last(names(_dict[res_type][country][year])))]
                        wind_profile[argmax(wind_profile)]=0.95
                        _dict[res_type][country][year][!,Symbol(last(names(_dict[res_type][country][year])))]=wind_profile
                        println(_dict[res_type][country][year][!,Symbol(last(names(_dict[res_type][country][year])))])
                    else
                        _dict[res_type][country][year][!,Symbol(last(names(_dict[res_type][country][year])))]=[1,0]
                    end
                end
                #place common timestamp in 2020
			    offset2020=Dates.Year(2020-parse(Int64,year))
                _dict[res_type][country][year][!,:time_stamp]=_dict[res_type][country][year][!,:time_stamp].+offset2020
			    tss2keep=vcat(tss2keep,ts2keep.+offset2020);end
            end
        end
    end    
    return _dict,unique!(tss2keep)
end


#***#
function multi_period_setup_wgen_type(scenario_data,data, all_gens, s)
    #################### Multi-period input parameters #######################
    data, s = multi_period_stoch_year_setup_wgen_type(s,data);
    extradata, data = create_profile_sets_mesh_wgen_type(data, all_gens, scenario_data, s)
    extradata = create_profile_sets_rest_wgen_type(extradata, data, s)
    #########################################################################
    #################### Scale cost data
    scale_cost_data_hourly!(extradata, s["scenario"])
    s["xd"]=costs_datas_wREZ(extradata, s)

    ######################################################
    xtradata = Dict{String,Any}()
    xtradata["dim"] = Dict{String,Any}()
    xtradata["dim"] = s["dim"]
    ######################################################
    # Create data dictionary where time series data is included at the right place
    mn_data = _PMACDC.multinetwork_data(data, xtradata, Set{String}(["source_type", "scenario", "scenario_prob", "name", "source_version", "per_unit"]))
    for (g,gen) in mn_data["nw"]
		gen["gen"]=Dict(gen["gen"]);end
    return mn_data, s
end



function create_profile_sets_mesh_wgen_type(data_orig, all_gens, scenario_data, s)
	genz=[];wfz=[]
    pu=data_orig["baseMVA"]
    e2me=1000000/pu#into ME/PU
    extradata = Dict{String,Any}()
    data=Dict{String,Any}();data["gen"]=Dict{String,Any}()
    extradata["dim"] = Dict{String,Any}()
    extradata["dim"] = s["dim"]
    extradata["gen"] = Dict{String,Any}()
	#demand_curve = Dict{String,Any}()
    
	for (c,country) in all_gens["onshore"];
		for (fuel,type) in country;
			for (num,g) in type;
				push!(data["gen"],num=>g)
				;end;end;end

	for (c,country) in all_gens["offshore"];
		for (num,g) in country;
		push!(data["gen"],num=>g);end;end

    data["gen"]=sort!(OrderedCollections.OrderedDict(data["gen"]), by=x->parse(Int64,x))
	for (g, gen) in data["gen"]
        extradata["gen"][string(g)] = Dict{String,Any}()
        extradata["gen"][string(g)]["pmax"] = Array{Float64,2}(undef, 1, s["dim"])
        extradata["gen"][string(g)]["pmin"] = Array{Float64,2}(undef, 1, s["dim"])
		extradata["gen"][string(g)]["cost"] = [Vector{Float64}() for i=1:s["dim"]]
		if (gen["type"]==0)
		extradata["gen"][string(g)]["invest"] = Array{Float64,2}(undef, 1, s["dim"]);
        extradata["gen"][string(g)]["wf_pmax"] = Array{Float64,2}(undef, 1, s["dim"]);end
    end
    
    
    for (k_sc,sc) in s["scenario"]["sc_names"]
		for (k_yr,yr) in sc
			k_yr_sd=k_yr=="2020" ? "2025" : k_yr;
			k_sc_sd=k_yr=="2020" ? "NT" : k_sc[1:2]
            if (issubset([string(k_sc_sd)*string(k_yr_sd)],s["scenario_names"]))
                for (h,d) in enumerate(yr)
                    #Day ahead BE
                    #onshore generators
                    for (xy, country) in all_gens["onshore"]
                        for (fuel, type) in country
                            for (g, gen) in type
                                #market generator onshore
                                S_row=filter(:Generation_Type=>x->x==fuel, scenario_data["Generation"]["Scenarios"][string(k_sc_sd)*string(k_yr_sd)][xy])[!,:Capacity]
                                if isempty(S_row)
                                    extradata["gen"][string(g)]["pmax"][1, d] = 0
                                    extradata["gen"][string(g)]["cost"][d] = [0,0]
                                    extradata["gen"][string(g)]["pmin"][1, d] = 0
                                else
                                    if issubset([fuel],keys(scenario_data["Generation"]["RES"]))
                                        CF=scenario_data["Generation"]["RES"][fuel][xy][k_sc[3:6]][!,Symbol(xy)][h]
                                        extradata["gen"][string(g)]["pmax"][1, d] = CF*S_row[1]/pu
                                    else
                                        extradata["gen"][string(g)]["pmax"][1, d] = S_row[1]/pu
                                    end
                                    extradata["gen"][string(g)]["pmin"][1, d] = 0
                                    extradata["gen"][string(g)]["cost"][d] = [scenario_data["Generation"]["costs"][fuel]/e2me,0]
                                    push!(genz,(parse(Int64,g),S_row[1]/pu))
                                end
                            end;
                        end;
                    end
                
                    #Wind power Plants
                    for (j,(xy, country)) in enumerate(all_gens["offshore"])
                        for (i,(g, gen)) in enumerate(country)
                            #wind gen
                            CF=scenario_data["Generation"]["RES"]["Offshore Wind"][xy][k_sc[3:6]][!,Symbol(xy)][h]
                            extradata["gen"][string(g)]["pmax"][1, d] = CF
                            extradata["gen"][string(g)]["pmin"][1, d] = 0
                            extradata["gen"][string(g)]["cost"][d] = [0,0]
                            extradata["gen"][string(g)]["invest"][1, d] = gen["invest"]
                            #extradata["gen"][string(g)]["wf_pmax"][1, d] = s["owpp_mva"][j]/pu
                            extradata["gen"][string(g)]["wf_pmax"][1, d] = gen["pmax"]*pu
                            #push!(wfz,(parse(Int64,g),s["owpp_mva"][j]/pu))
                            push!(wfz,(parse(Int64,g),gen["pmax"]*pu))
                        end;
                    end
                end
            end
        end
    end
	#set ["type"]
    for (g, gen) in data["gen"]
		if (isapprox(sum(extradata["gen"][g]["pmax"]),0,atol=10e-3) && isapprox(sum(extradata["gen"][g]["pmin"]),0,atol=10e-3))
			gen["gen_status"]=0;
		else
		end
    end

	num_of_gens=length(data["gen"])
	if !(haskey(s["map_gen_types"],"loads"));push!(s["map_gen_types"],"loads"=>Dict());end
	loads=Dict{String,Any}()
	for _row in eachrow(filter(:type=>x->x==1,s["nodes"]))
		if !(haskey(loads,_row[:country]));push!(loads,_row[:country]=>Dict());end
		load=deepcopy(first(first(all_gens["onshore"][_row[:country]])[2])[2])
		#for row in eachrow(df)
			#reset load parameters
	    	load["type"]=1
			load["gen_status"]=1
	        load["index"]=num_of_gens+1
	        load["source_id"][2]=num_of_gens+1
	        load["pmin"]=-1
            load["pmax"]=-1
	        #load["pmax"]=0
			#load["cost"]=[deepcopy(row[:fuel_cost]),0]
            load["cost"]=[0.015,0]
	        push!(loads[_row[:country]],string(num_of_gens+1)=>deepcopy(load))
	        num_of_gens=num_of_gens+1

			#map load to country
			if !(haskey(s["map_gen_types"]["loads"],_row[:country]));push!(s["map_gen_types"]["loads"],_row[:country]=>[]);end
			push!(s["map_gen_types"]["loads"][_row[:country]],num_of_gens)
	end;#end
    
	for (cuntree, dic) in loads
    	for (l, load) in dic
	        extradata["gen"][string(l)] = Dict{String,Any}()
	        extradata["gen"][string(l)]["pmax"] = Array{Float64,2}(undef, 1, s["dim"])
	        extradata["gen"][string(l)]["pmin"] = Array{Float64,2}(undef, 1, s["dim"])
	        extradata["gen"][string(l)]["cost"] = [Vector{Float64}() for i=1:s["dim"]]
    end;end

	#onshore loads
	for (k_sc,sc) in s["scenario"]["sc_names"]
		for (k_yr,yr) in sc
			k_yr_sd=k_yr=="2020" ? "2025" : k_yr;
			k_sc_sd=k_yr=="2020" ? "NT" : k_sc[1:2]
            if (issubset([string(k_sc_sd)*string(k_yr_sd)],s["scenario_names"]))
                for (h,d) in enumerate(yr)
                    #loads
                    for (cuntree, dic) in loads
                        for (l, load) in sort!(OrderedCollections.OrderedDict(dic), by=x->parse(Int64,x))
                            #NOTE: Left here ts is off - 2014 time stamp vs 2020 BLNK time stamp would work but...
                            #Just this final load to be done, however, the rest still needs to be confirmed! 
                            if (cuntree=="BLNK")
                                ts=scenario_data["Generation"]["RES"]["Onshore Wind"][first(keys(scenario_data["Generation"]["RES"]["Onshore Wind"]))][k_sc[3:6]][!,:time_stamp][h]
                            else
                                ts=scenario_data["Generation"]["RES"]["Onshore Wind"][cuntree][k_sc[3:6]][!,:time_stamp][h]
                            end
                            println(ts)
                            S_row=filter(:time_stamp=>x->x==ts,scenario_data["Demand"][k_sc_sd*k_yr_sd])[!,Symbol(cuntree)]
                            extradata["gen"][string(l)]["pmax"][1, d] = load["pmax"]*S_row[1]/pu
                            extradata["gen"][string(l)]["pmin"][1, d] = load["pmin"]*S_row[1]/pu
                            #println(string(extradata["gen"][string(l)]["pmax"][1, d])*" "*string(extradata["gen"][string(l)]["pmin"][1, d]))
                            extradata["gen"][string(l)]["cost"][d] = load["cost"]
                            push!(data["gen"],string(l)=>load)
                            push!(genz,(parse(Int64,l),S_row[1]/pu))
                        end
                    end
                end
            end;
        end;
    end
	unique!(x->first(x),genz)
	unique!(x->first(x),wfz)
    sort!(wfz,by=x->first(x))
	push!(s,"genz"=>genz)
    push!(s,"wfz"=>wfz)
	data_orig["gen"]=data["gen"]
    return extradata, data_orig
end


#***#
function gen_types(data,scenario_data,s)
	s, markets_wfs = divide_onshore_offshore(s)
	base_gens=deepcopy(data["gen"])

    #creating space
    s["map_gen_types"]=Dict{String,Any}();push!(s["map_gen_types"],"type"=>Tuple[]);
	all_gens=Dict{String, Any}()
    push!(all_gens,"offshore"=>Dict())
    number_of_gens_offshore=0
	for (gen,_row) in enumerate(eachrow(filter(:type=>x->x==0,s["nodes"])))
		if !(haskey(all_gens["offshore"],_row[:country]))
			push!(all_gens["offshore"],_row[:country]=>Dict());end
		if !(haskey(s["map_gen_types"],"offshore"));push!(s["map_gen_types"],"offshore"=>Dict());end
		if !(haskey(s["map_gen_types"]["offshore"],_row[:country]));push!(s["map_gen_types"]["offshore"],_row[:country]=>[]);end
		generator_number=string(gen)
		push!(all_gens["offshore"][_row[:country]],generator_number=>copy(base_gens[string(gen)]))
		all_gens["offshore"][_row[:country]][generator_number]["source_id"]=["gen",parse(Int64,generator_number)]
		all_gens["offshore"][_row[:country]][generator_number]["index"]=parse(Int64,generator_number)
		all_gens["offshore"][_row[:country]][generator_number]["gen_status"]=1
		push!(s["map_gen_types"]["type"],(generator_number,"Offshore Wind"))
		push!(s["map_gen_types"]["offshore"][_row[:country]],generator_number)
        number_of_gens_offshore=number_of_gens_offshore+1
	end

	push!(all_gens,"onshore"=>Dict())
	for (gen,_row) in enumerate(eachrow(filter(:type=>x->x==1,s["nodes"])))

        #creating space!
		push!(all_gens["onshore"],_row[:country]=>Dict())
		if !(haskey(s["map_gen_types"],"countries"));push!(s["map_gen_types"],"countries"=>Dict());end
		if !(haskey(s["map_gen_types"]["countries"],_row[:country]));push!(s["map_gen_types"]["countries"],_row[:country]=>[]);end

		for (t,type) in enumerate(scenario_data["Generation"]["keys"])
			generator_number=string(number_of_gens_offshore+(gen-1)*length(scenario_data["Generation"]["keys"])+t)
			push!(all_gens["onshore"][_row[:country]],type=>Dict())
			push!(all_gens["onshore"][_row[:country]][type],generator_number=>copy(base_gens[string(number_of_gens_offshore+gen)]))
			all_gens["onshore"][_row[:country]][type][generator_number]["source_id"]=["gen",parse(Int64,generator_number)]
			all_gens["onshore"][_row[:country]][type][generator_number]["index"]=parse(Int64,generator_number)
			all_gens["onshore"][_row[:country]][type][generator_number]["gen_status"]=1
			push!(s["map_gen_types"]["type"],(generator_number,type))
			push!(s["map_gen_types"]["countries"][_row[:country]],generator_number)
		end
	end

    s["map_gen_types"]["markets"]=markets_wfs
	s["map_gen_types"]["costs"]=scenario_data["Generation"]["costs"]
    return all_gens, s
end

function get_scenario_data(s)
    ############### defines size and market of genz and wfs ###################
	scenario_data=FileIO.load(s["scenario_data_file"])
    ######## Batteries are removed and modeled seperately time series #########
    for (k_sc,sc) in scenario_data["Generation"]["Scenarios"]; for (k_cunt,cuntree) in sc;
        filter!(:Generation_Type=>x->x!="Battery", cuntree);
        filter!(:Generation_Type=>x->x!="VOLL", cuntree);
        push!(cuntree,["SLACK",1000000])
    end;end
        push!(scenario_data["Generation"]["keys"],"SLACK")
        delete!(scenario_data["Generation"]["costs"],"VOLL");
        #push!(scenario_data["Generation"]["costs"],"SLACK"=>maximum(values(scenario_data["Generation"]["costs"])))
        push!(scenario_data["Generation"]["costs"],"SLACK"=>5000)

    ####################### Freeze offshore expansion of data #################
    if (haskey(s,"collection_circuit") && s["collection_circuit"]==true)
        nodes_df = DataFrames.DataFrame(XLSX.readtable(s["rt_ex"]*"input.xlsx", "node_generation")...)
        scenario_data=keep_only_wf_pcc(s,scenario_data)
        offshore_nodes=filter(:type=>x->x==0,nodes_df)
        wf_capacity=sum(offshore_nodes[!,:gen])*100
        onshore_demand=[wf_capacity for i=1:1:length(scenario_data["Demand"][s["scenario_names"][1]][!,last(offshore_nodes[!,:country])])]

        scenario_data["Demand"][s["scenario_names"][1]][!,last(offshore_nodes[!,:country])]=onshore_demand
        
        #scenario_data["Generation"]["costs"]["SLACK"]=5000
    end
    return scenario_data
end