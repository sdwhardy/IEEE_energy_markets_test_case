
function get_scenario_data4YUSO(s, array_of_zones)
    ############### defines size and market of genz and wfs ###################
    scenario_data=FileIO.load(s["scenario_data_file"])

    scenario_data["Generation"]["nodes"]

    strip.(split(scenario_data["Generation"]["nodes"][!,:Region][10],","))

    filter!(:Region=>x->!(isempty(intersect!(strip.(split(x,",")),array_of_zones))), scenario_data["Generation"]["nodes"])

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

function reduce_toRegions4YUSO(scenario_data)

    filter!(p -> issubset([first(p)],scenario_data["Generation"]["nodes"][!,:node_id]), scenario_data["Generation"]["RES"]["Offshore Wind"])
    
    filter!(p -> issubset([first(p)],scenario_data["Generation"]["nodes"][!,:node_id]), scenario_data["Generation"]["RES"]["Onshore Wind"])
    
    filter!(p -> issubset([first(p)],scenario_data["Generation"]["nodes"][!,:node_id]), scenario_data["Generation"]["RES"]["Solar PV"])
    
    filter!(p -> issubset([first(p)],scenario_data["Generation"]["nodes"][!,:node_id]), scenario_data["Generation"]["Scenarios"]["NT2025"])
    
    filter!(p -> issubset([first(p)],scenario_data["Generation"]["nodes"][!,:node_id]), scenario_data["Generation"]["Scenarios"]["NT2030"])
    
    filter!(p -> issubset([first(p)],scenario_data["Generation"]["nodes"][!,:node_id]), scenario_data["Generation"]["Scenarios"]["NT2040"])
    
    filter!(p -> issubset([first(p)],scenario_data["Generation"]["nodes"][!,:node_id]), scenario_data["Generation"]["Scenarios"]["DE2030"])
    
    filter!(p -> issubset([first(p)],scenario_data["Generation"]["nodes"][!,:node_id]), scenario_data["Generation"]["Scenarios"]["DE2040"])
    
    filter!(p -> issubset([first(p)],scenario_data["Generation"]["nodes"][!,:node_id]), scenario_data["Generation"]["Scenarios"]["GA2030"])
    
    filter!(p -> issubset([first(p)],scenario_data["Generation"]["nodes"][!,:node_id]), scenario_data["Generation"]["Scenarios"]["GA2040"])
    
    filter(x -> issubset([x],scenario_data["Generation"]["nodes"][!,:node_id]), names(scenario_data["Demand"]["GA2040"]))
    
    scenario_data["Demand"]["GA2040"]=scenario_data["Demand"]["GA2040"][!,vcat("time_stamp",scenario_data["Generation"]["nodes"][!,:node_id])]
    
    scenario_data["Demand"]["GA2030"]=scenario_data["Demand"]["GA2030"][!,vcat("time_stamp",scenario_data["Generation"]["nodes"][!,:node_id])]
    
    scenario_data["Demand"]["DE2040"]=scenario_data["Demand"]["DE2040"][!,vcat("time_stamp",scenario_data["Generation"]["nodes"][!,:node_id])]
    
    scenario_data["Demand"]["DE2030"]=scenario_data["Demand"]["DE2030"][!,vcat("time_stamp",scenario_data["Generation"]["nodes"][!,:node_id])]
    
    scenario_data["Demand"]["NT2030"]=scenario_data["Demand"]["NT2030"][!,vcat("time_stamp",scenario_data["Generation"]["nodes"][!,:node_id])]
    
    scenario_data["Demand"]["NT2040"]=scenario_data["Demand"]["NT2040"][!,vcat("time_stamp",scenario_data["Generation"]["nodes"][!,:node_id])]
    
    scenario_data["Demand"]["NT2025"]=scenario_data["Demand"]["NT2025"][!,vcat("time_stamp",scenario_data["Generation"]["nodes"][!,:node_id])]
    
    return scenario_data

end


function reduce_grid_size_4YUSO(scenario_data)

    scenario_data["Generation"]["RES"]["Offshore Wind"]["BE00"]["2016"][!,:time_stamp][1416]=scenario_data["Generation"]["RES"]["Offshore Wind"]["BE00"]["2016"][!,:time_stamp][1417]-Hour(1)
    
    scenario_data["Generation"]["RES"]["Onshore Wind"]["BE00"]["2016"][!,:time_stamp][1416]=scenario_data["Generation"]["RES"]["Offshore Wind"]["BE00"]["2016"][!,:time_stamp][1417]-Hour(1)
    
    scenario_data["Generation"]["RES"]["Solar PV"]["BE00"]["2016"][!,:time_stamp][1416]=scenario_data["Generation"]["RES"]["Offshore Wind"]["BE00"]["2016"][!,:time_stamp][1417]-Hour(1)
    
    scenario_data["Generation"]["RES"]["Offshore Wind"]["UK00"]["2016"][!,:time_stamp][1416]=scenario_data["Generation"]["RES"]["Offshore Wind"]["BE00"]["2016"][!,:time_stamp][1417]-Hour(1)
    
    scenario_data["Generation"]["RES"]["Onshore Wind"]["UK00"]["2016"][!,:time_stamp][1416]=scenario_data["Generation"]["RES"]["Offshore Wind"]["BE00"]["2016"][!,:time_stamp][1417]-Hour(1)
    
    scenario_data["Generation"]["RES"]["Solar PV"]["UK00"]["2016"][!,:time_stamp][1416]=scenario_data["Generation"]["RES"]["Offshore Wind"]["BE00"]["2016"][!,:time_stamp][1417]-Hour(1)

    filter!(:EU28=>x->x=="Yes",scenario_data["Generation"]["nodes"])
    
    filter!(:node_id=>x->issubset([x],["BE00","UK00"]),scenario_data["Generation"]["nodes"])

    filter!(Symbol("Border Names Based on PEMMDB 3.0 convention")=>x->x=="poop",scenario_data["Generation"]["ntcs"])

    return scenario_data

end


function data_update_4YUSO(s,result_mip,array_of_zones)

    scenario_data = _CBD.get_scenario_data(s)#scenario time series

    scenario_data = reduce_grid_size_4YUSO(scenario_data)
   
    scenario_data = reduce_toRegions4YUSO(scenario_data)#scenario time series
    
    data, s = _CBD.get_topology_data(s, scenario_data)#topology.m file

    #scenario_data=_CBD.freeze_offshore_expansion(s["nodes"], scenario_data)
   
    _CBD.reduce_nonstoch_gens(scenario_data)

    ###########################################################################

    all_gens,s = _CBD.gen_types(data,scenario_data,s)
 
    if (haskey(s,"collection_circuit") && s["collection_circuit"]==true)
  
        #################### Calculates cable options for collection circuit AC lines
  
        data = _CBD.AC_cable_options_collection(scenario_data,data,s)
 
        #################### Calculates cable options for collection circuit DC lines
 
        data = _CBD.DC_cable_options_collection(scenario_data,data,s)
 
    else
 
        #################### Calculates cable options for AC lines
  
        data = _CBD.AC_cable_options(data,s)
  
        #################### Calculates cable options for DC lines
 
        data = _CBD.DC_cable_options(data,s["candidate_ics_dc"],s["ics_dc"],data["baseMVA"])
  
    end
  
    ############# Sets convex able impedance to the MIP solution ##############
  
    data = _CBD.set_cable_impedance(data, result_mip)
  
    _CBD.additional_params_PMACDC(data)
   
    _CBD.print_topology_data_AC(data,s["map_gen_types"]["markets"])#print to verify
   
    _CBD.print_topology_data_DC(data,s["map_gen_types"]["markets"])#print to verify
   
    ##################### load time series data ##############################
    
    scenario_data = _CBD.load_time_series_gentypes(s, scenario_data)
   
    ##################### multi period setup #################################
	
    s = _CBD.update_settings_wgenz(s, data)
    
    mn_data, s  = _CBD.multi_period_setup_wgen_type(scenario_data, data, all_gens, s);
    
    push!(s,"max_invest_per_year"=>_CBD.max_invest_per_year(s))

    return  mn_data, data, s
end
