export cordoba_acdc_wf_split
#**#
function cordoba_acdc_wf_split(data::Dict{String,Any}, model_type::Type, solver; ref_extensions = [_PMACDC.add_ref_dcgrid!, _PMACDC.add_candidate_dcgrid!,  add_candidate_storage!, _PM.ref_add_on_off_va_bounds!, _PM.ref_add_ne_branch!], setting = s, kwargs...)
    s = setting
    return run_model_p1(data, model_type, post_cordoba_acdc_wf_split; ref_extensions = [_PMACDC.add_ref_dcgrid!,_PMACDC.add_candidate_dcgrid!,  add_candidate_storage!, _PM.ref_add_on_off_va_bounds!, _PM.ref_add_ne_branch!], setting = s, kwargs...)
end


#**#
function post_cordoba_acdc_wf_split(pm::_PM.AbstractPowerModel)
    # VARIABLES: defined within PowerModels(ACDC) can directly be used, other variables need to be defined in the according sections of the code: flexible_demand.jl
    vsp=[];vcp=[];vap=[];vbp=[];vgp=[];vdp=[];vacp=[]
        for n in _PM.nw_ids(pm)

          
            _PM.variable_bus_voltage(pm; nw = n)#CREATES voltage angle variables and sets voltage magnitudes to 1.0 at all AC nodes
            push!(vgp,variable_wfs_peak(pm; nw = n))
            variable_gen_power(pm; nw = n)#CREATES pg variables of all generators and sets upper and lower limits
            
            
            ####################### cordoba converters ########################
            push!(vcp,variable_convdc_peak(pm; nw = n))
            variable_dc_converter(pm; nw = n)


            ####################### cordoba storage ########################
            push!(vsp,variable_storage_peak(pm; nw = n))
            variable_storage_power(pm; nw = n)#CREATES variables ps, qsc, se, sc, sd and sets upper/lower bounds
            variable_absorbed_energy(pm; nw = n)#e_abs upper/lower limits
            ########################################################

            ######################### May use in future ###########################################
            if (haskey(pm.setting,"relax_problem") && pm.setting["relax_problem"]==true)
                push!(vacp,variable_acbranch_peak(pm; nw = n))
                variable_branch_power(pm; nw = n)#CREATES real and imaginary branch power variables, sets upper and lower limits and initial values
                push!(vdp,variable_dcbranch_peak(pm; nw = n))
                variable_active_dcbranch_flow(pm; nw = n)
            elseif (haskey(pm.setting,"onshore_grid") && pm.setting["onshore_grid"]==true)
                push!(vacp,variable_acbranch_peak(pm; nw = n))
                variable_branch_power(pm; nw = n)#CREATES real and imaginary branch power variables, sets upper and lower limits and initial values
                #_PMACDC.variable_active_dcbranch_flow(pm; nw = n)#CREATES pdcgrid for each branchdc and bounds between +/- rateA
                push!(vdp,variable_dcbranch_peak(pm; nw = n))
                variable_active_dcbranch_flow(pm; nw = n)
            else
                _PM.variable_branch_power(pm; nw = n)#CREATES real and imaginary branch power variables, sets upper and lower limits and initial values
                _PMACDC.variable_active_dcbranch_flow(pm; nw = n)#CREATES pdcgrid for each branchdc and bounds between +/- rateA
            end
            _PMACDC.variable_voltage_slack(pm; nw = n)#CREATES va_du(angle @ transformer?), vaf_du(angle @ filter), vac_du(angle @ converter?) for each convdc_ne and bounds between -2pi and 2pi, intiallizes to 0
            _PMACDC.variable_dcbranch_current(pm; nw = n)#ONLY ACTIVE IN BF MODEL(not doing anything even with branch flow = true?), CREATES: ccm_dcgrid and bounds.
            _PMACDC.variable_dcgrid_voltage_magnitude(pm; nw = n)# IN DC flow MODEL not USED

            #######################################################################################

            # variables for TNEP problem

            push!(vap,variable_ne_branch_indicator(pm; nw = n))#CREATES: branch_ne {0,1} for each branch_ne
            _PM.variable_ne_branch_power(pm; nw = n)#CREATES p_ne branch power variable and sets bounds
            push!(vbp,variable_branch_ne(pm; nw = n))#CREATES: branch_ne {0,1} for each branchdc_ne
            _PMACDC.variable_active_dcbranch_flow_ne(pm; nw = n)#CREATES: pdcgrid_ne for each branchdc_ne and sets upper and lower bounds

            ######################### May use in future ###########################################

            _PM.variable_ne_branch_voltage(pm; nw = n)#DOES nothing in DC model - there are no voltages on branches
            _PMACDC.variable_dc_converter_ne(pm; nw = n)#CREATES: pconv_ac_ne, pconv_dc_ne, vaf_ne, vac_ne, pconv_tf_fr_ne, pconv_tf_to_ne, pconv_pr_from_ne and sets bounds (equivalent to existing conv vars)
            _PMACDC.variable_dcbranch_current_ne(pm; nw = n)##ONLY ACTIVE IN BF MODEL(not doing anything even with branch flow = true?),CREATES: ccm_dcgrid_ne
            _PMACDC.variable_dcgrid_voltage_magnitude_ne(pm; nw = n)# IN DC flow MODEL not USED

            #######################################################################################
        end
        if ((haskey(pm.setting,"relax_problem") && pm.setting["relax_problem"]==true))
            sort!(vdp, by = x -> x[1])
            constraint_t0t1(vdp,pm)
            sort!(vacp, by = x -> x[1])
            constraint_t0t1(vacp,pm)
        end
        sort!(vsp, by = x -> x[1])
        constraint_t0t1(vsp,pm)
        sort!(vbp, by = x -> x[1])
        constraint_t0t1(vbp,pm)
        sort!(vap, by = x -> x[1])
        constraint_t0t1(vap,pm)
        sort!(vcp, by = x -> x[1])
        constraint_t0t1(vcp,pm)
        sort!(vgp, by = x -> x[1])
        constraint_t0t1_wfz(vgp,pm)
    #CONSTRAINTS: defined within PowerModels(ACDC) can directly be used, other constraints need to be defined in the according sections of the code: flexible_demand.jl
        for n in _PM.nw_ids(pm)
            _PM.constraint_model_voltage(pm; nw = n)
            _PM.constraint_ne_model_voltage(pm; nw = n)
            _PMACDC.constraint_voltage_dc(pm; nw = n)
            _PMACDC.constraint_voltage_dc_ne(pm; nw = n)
            for i in _PM.ids(pm, n, :ref_buses)
                _PM.constraint_theta_ref(pm, i, nw = n)
            end
            
            if (!(haskey(pm.setting, "agent")) || (pm.setting["agent"] == ""))
                for i in _PM.ids(pm, n, :bus)
                    if haskey(pm.setting, "home_market") && length(pm.setting["home_market"]) > 0                        
                        if !(is_intra_zonal(i,i,pm.setting["home_market"]))
                            #println("full power balnce "*string(i))
                            constraint_power_balance_acne_dcne_strg(pm, i; nw = n)
                        end
                    else
                       constraint_power_balance_acne_dcne_strg(pm, i; nw = n)
                    end
                end
            end
            if haskey(pm.setting, "home_market") && length(pm.setting["home_market"]) > 0
                for zm in pm.setting["home_market"]
                    is=intersect(_PM.ids(pm, n, :bus),zm)
                   # println("acne_dcne zonal power balnce "*string(is))
                    constraint_power_balance_acne_dcne_strg_hm(pm, is; nw = n)
                end
            end

            for i in _PM.ids(pm, n, :branch)
                _PM.constraint_ohms_yt_from(pm, i; nw = n)
                _PM.constraint_ohms_yt_to(pm, i; nw = n)
                constraint_ohms_ac_branch(pm, i; nw = n)#NOTE change for Zonal market
                _PM.constraint_voltage_angle_difference(pm, i; nw = n)
                _PM.constraint_thermal_limit_from(pm, i; nw = n)
                _PM.constraint_thermal_limit_to(pm, i; nw = n)
            end

            ac_candidates_in_corridor=[]
            for i in _PM.ids(pm, n, :ne_branch)
                _PM.constraint_ne_ohms_yt_from(pm, i; nw = n)
                _PM.constraint_ne_ohms_yt_to(pm, i; nw = n)
                constraint_ohms_ac_branch_ne(pm, i; nw = n)#NOTE change for Zonal market
                _PM.constraint_ne_voltage_angle_difference(pm, i; nw = n)
                _PM.constraint_ne_thermal_limit_from(pm, i; nw = n)
                _PM.constraint_ne_thermal_limit_to(pm, i; nw = n)
                push!(ac_candidates_in_corridor,collect_4_constraint_candidate_corridor_limit_ac(pm, i; nw = n))
            end

            for i in _PM.ids(pm, n, :busdc)
               if haskey(pm.setting, "home_market") && length(pm.setting["home_market"]) > 0
                    if !(is_intra_zonal(i,i,pm.setting["home_market"]))
                        #println("full power balnce "*string(i))
                        _PMACDC.constraint_power_balance_dc_dcne(pm, i; nw = n)
                    end
                else
                    #println("entering!!!!!!!!!!!!!!!!!!!")
                    constraint_power_balance_dc_dcne(pm, i; nw = n)
                end
            end

            if haskey(pm.setting, "home_market") && length(pm.setting["home_market"]) > 0
                for zm in pm.setting["home_market"]
                  
                    is=intersect(_PM.ids(pm, n, :busdc),zm)
                   # println("dc_dcne zonal power balnce "*string(is))
                    constraint_power_balance_dc_dcne_hm(pm, is; nw = n)
                end
            end

            for i in _PM.ids(pm, n, :busdc_ne)
               if haskey(pm.setting, "home_market") && length(pm.setting["home_market"]) > 0
                    if !(is_intra_zonal(i,i,pm.setting["home_market"]))
                        #println("full power balnce "*string(i))
                        _PMACDC.constraint_power_balance_dcne_dcne(pm, i; nw = n)
                    end
                else
                    #println("entering222!!!!!!!!!!!!!!!!!!!")
                    constraint_power_balance_dcne_dcne(pm, i; nw = n)
               end
            end

            if haskey(pm.setting, "home_market") && length(pm.setting["home_market"]) > 0
                for zm in pm.setting["home_market"]
                    
                    is=intersect(_PM.ids(pm, n, :busdc_ne),zm)
                   # println("dcne_dcne zonal power balnce "*string(is))
                    constraint_power_balance_dcne_dcne_hm(pm, is; nw = n)
                end
            end

            for i in _PM.ids(pm, n, :branchdc)
                constraint_ohms_dc_branch(pm, i; nw = n)#NOTE change for Zonal market
            end

            dc_candidates_in_corridor=[]
            for i in _PM.ids(pm, n, :branchdc_ne)
                #println("!!!!!!!!!!!! entrering333 !!!!!!!!!!!!!!!!!!")
                constraint_ohms_dc_branch_ne(pm, i; nw = n)#NOTE change for Zonal market
                _PMACDC.constraint_branch_limit_on_off(pm, i; nw = n)
                push!(dc_candidates_in_corridor,collect_4_constraint_candidate_corridor_limit_dc(pm, i; nw = n))
            end

            if (pm.setting["corridor_limit"])
                if (length(ac_candidates_in_corridor)>0)
                    constraint_candidate_corridor_limit(pm, ac_candidates_in_corridor; nw = n);end
                if (length(dc_candidates_in_corridor)>0)
                constraint_candidate_corridor_limit(pm, dc_candidates_in_corridor; nw = n);end
            end

            for i in _PM.ids(pm, n, :convdc)
                _PMACDC.constraint_converter_losses(pm, i; nw = n)
                _PMACDC.constraint_converter_current(pm, i; nw = n)
                _PMACDC.constraint_conv_transformer(pm, i; nw = n)
                _PMACDC.constraint_conv_reactor(pm, i; nw = n)
                _PMACDC.constraint_conv_filter(pm, i; nw = n)
                if pm.ref[:nw][n][:convdc][i]["islcc"] == 1
                    _PMACDC.constraint_conv_firing_angle(pm, i; nw = n)
                end
            end

            for i in _PM.ids(pm, :storage, nw=n)
                constraint_storage_excl_slack(pm, i, nw = n)
                constraint_storage_thermal_limit(pm, i, nw = n)
                constraint_storage_losses(pm, i, nw = n)
            end
        end

        for (s, scenario) in pm.ref[:scenario]

            network_ids = sort(collect(n for (sc, n) in scenario))
            n_1 = network_ids[1]
            n_last = network_ids[end]

            # NW = 1
            for i in _PM.ids(pm, :storage, nw = n_1)
                constraint_storage_state(pm, i, nw = n_1)
                constraint_maximum_absorption(pm, i, nw = n_1)
            end

            # NW = last
            for i in _PM.ids(pm, :storage, nw = n_last)
                constraint_storage_state_final(pm, i, nw = n_last)
            end

            for n_2 in network_ids[2:end]
                for i in _PM.ids(pm, :storage, nw = n_2)
                    constraint_storage_state(pm, i, n_1, n_2)
                    constraint_maximum_absorption(pm, i, n_1, n_2)
                end
                n_1 = n_2
            end
        end
        max_investment_per_year(pm)
        if (haskey(pm.setting,"relax_problem") && pm.setting["relax_problem"]==true)
            objective_min_cost_acdc_convex_convcble_strg_npv(pm)
            fix_dc_ne_lines2zero(pm)
            fix_ac_ne_lines2zero(pm)
            undo_relax=JuMP.relax_integrality(pm.model)
        else
            objective_min_cost_acdc_convex_conv_strg_npv(pm)
        end
        #println(pm.model)
end

