function data_setup_septmeeting(s)
    scenario_data = _CBD.get_scenario_data(s)#scenario time series
    data, s = _CBD.get_topology_data(s, scenario_data)#topology.m file
    scenario_data=_CBD.freeze_offshore_expansion(s["nodes"], scenario_data)
    ########## untested
    _CBD.reduce_nonstoch_gens(scenario_data)
    ##########
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
    if (haskey(s, "home_market") && length(s["home_market"])>0);data = _CBD.keep_only_hm_cables(s,data);end#if home market reduce to only those in
    _CBD.additional_params_PMACDC(data)
    _CBD.print_topology_data_AC(data,s["map_gen_types"]["markets"])#print to verify
    _CBD.print_topology_data_DC(data,s["map_gen_types"]["markets"])#print to verify
    ##################### load time series data ##############################
    scenario_data = _CBD.load_time_series_gentypes(s, scenario_data)
    ##################### multi period setup #################################
	s = _CBD.update_settings_wgenz(s, data)
    mn_data, s  = multi_period_setup_wgen_type(scenario_data, data, all_gens, s);
	push!(s,"max_invest_per_year"=>_CBD.max_invest_per_year(s))
    ####################### WTACH OUT if  s["scenarios_length"]=6 is hared coded onlyt works with 6 scenarios!!!
    #s["scenarios_length"]=6
    s["scenarios_length"] = ceil(length(s["scenario_names"])/length(s["scenario_years"]))*length(s["res_years"])
    return  mn_data, data, s
end

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