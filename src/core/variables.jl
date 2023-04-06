################################### Conventional Generators and wind farms ##############################
#creates variables for WFs
function variable_wfs_peak(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    wf_pacmax = _PM.var(pm, nw)[:wf_pacmax] = JuMP.@variable(pm.model,
    [i in intersect(_PM.ids(pm, nw, :gen),first.(pm.setting["wfz"]))], base_name="$(nw)_wf_pacmax",
    start = 0)

    if bounded
        for (s, gen) in _PM.ref(pm, nw, :gen)
            if issubset([s],first.(pm.setting["wfz"]))
                if (haskey(pm.setting,"rebalancing") && pm.setting["rebalancing"]==true)
                    JuMP.set_lower_bound(wf_pacmax[s],  pm.setting["xd"]["gen"][string(s)]["wf_pmax"][nw])
                    JuMP.set_upper_bound(wf_pacmax[s],  pm.setting["xd"]["gen"][string(s)]["wf_pmax"][nw])
                else
                JuMP.set_lower_bound(wf_pacmax[s],  0)
                JuMP.set_upper_bound(wf_pacmax[s],  last(pm.setting["wfz"][Int8(s+1-minimum(first.(pm.setting["wfz"])))]))
                end
            end
        end
    end
    
    report && _IM.sol_component_value(pm, nw, :gen, :wf_pacmax, intersect(_PM.ids(pm, nw, :gen),first.(pm.setting["wfz"])), wf_pacmax)
    return (nw,wf_pacmax)
end

#sets real and imaginary power for a generator
function variable_gen_power(pm::_PM.AbstractPowerModel; kwargs...)
    variable_gen_power_real(pm; kwargs...)
    variable_gen_power_imaginary(pm; kwargs...)
end

#real power variable for generators (both conventional and wind)
function variable_gen_power_real(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    pg = _PM.var(pm, nw)[:pg] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_pg",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :gen, i), "pg_start")
    )

    if bounded
        for (i, gen) in _PM.ref(pm, nw, :gen)
            if issubset([i],first.(pm.setting["genz"]))
                JuMP.set_lower_bound(pg[i], pm.setting["xd"]["gen"][string(i)]["pmin"][nw])
                JuMP.set_upper_bound(pg[i], pm.setting["xd"]["gen"][string(i)]["pmax"][nw])
            elseif issubset([i],first.(pm.setting["wfz"]))
                wf_pacmax = _PM.var(pm, nw, :wf_pacmax, i)
                JuMP.@constraint(pm.model, pg[i]-pm.setting["xd"]["gen"][string(i)]["pmax"][nw]*wf_pacmax  <= 0)
                JuMP.@constraint(pm.model, pg[i]+pm.setting["xd"]["gen"][string(i)]["pmin"][nw]  >= 0)
            end
        end
    end
    report && _IM.sol_component_value(pm, nw, :gen, :pg, _PM.ids(pm, nw, :gen), pg)
end

#generator imaginary power + constraints
function variable_gen_power_imaginary(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    qg = _PM.var(pm, nw)[:qg] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_qg",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :gen, i), "qg_start")
    )

    if bounded
        for (i, gen) in _PM.ref(pm, nw, :gen)
            JuMP.set_lower_bound(qg[i], gen["qmin"])
            JuMP.set_upper_bound(qg[i], gen["qmax"])
        end
    end

    report && _IM.sol_component_value(pm, nw, :gen, :qg, _PM.ids(pm, nw, :gen), qg)
end

############################# Converters #####################
#Creates converter max capacity variable and sets  upper/lower limit
function variable_convdc_peak(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    p_pacmax = _PM.var(pm, nw)[:p_pacmax] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_p_pacmax",
    start = 0)

    if bounded
        for (s, convdc) in _PM.ref(pm, nw, :convdc)
            if (haskey(pm.setting,"rebalancing") && pm.setting["rebalancing"]==true)
                JuMP.set_lower_bound(p_pacmax[s],  pm.setting["xd"]["convdc"][string(s)]["Pacmax"][nw])
            else
                JuMP.set_lower_bound(p_pacmax[s],  pm.setting["xd"]["convdc"][string(s)]["Pacmin"][nw])
            end
            JuMP.set_upper_bound(p_pacmax[s],  pm.setting["xd"]["convdc"][string(s)]["Pacmax"][nw])
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc, :p_pacmax, _PM.ids(pm, nw, :convdc), p_pacmax)
    return (nw,p_pacmax)
end

#Creates required variables for HVDC converter. All are same as PMACDC except active power as it must be less than a variable max  capacity
function variable_dc_converter(pm::_PM.AbstractDCPModel; kwargs...)

    variable_converter_active_power(pm; kwargs...)
    _PMACDC.variable_dcside_power(pm; kwargs...)
    _PMACDC.variable_converter_filter_voltage(pm; kwargs...)
    _PMACDC.variable_converter_internal_voltage(pm; kwargs...)
   _PMACDC.variable_converter_to_grid_active_power(pm; kwargs...)

     _PMACDC.variable_conv_transformer_active_power_to(pm; kwargs...)
    _PMACDC.variable_conv_reactor_active_power_from(pm; kwargs...)
end


#constraint on convexified converter AC side power
function variable_converter_active_power(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    pc = _PM.var(pm, nw)[:pconv_ac] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_pconv_ac",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            p_pacmax = _PM.var(pm, nw, :p_pacmax, c)
            JuMP.@constraint(pm.model, pc[c]-p_pacmax  <= 0)
            JuMP.@constraint(pm.model, pc[c]+p_pacmax  >= 0)
        end
    report && _IM.sol_component_value(pm, nw, :convdc, :pconv, _PM.ids(pm, nw, :convdc), pc)
end

############################# Storage ########################
function variable_storage_peak(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    e_absmax = _PM.var(pm, nw)[:e_absmax] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :storage)], base_name="$(nw)_e_absmax",
    start = 0)

    if bounded
        for (s, strg) in _PM.ref(pm, nw, :storage)
            if (haskey(pm.setting,"rebalancing") && pm.setting["rebalancing"]==true)
                JuMP.set_lower_bound(e_absmax[s],  pm.setting["xd"]["storage"][string(s)]["pmax"][nw])
            else
                JuMP.set_lower_bound(e_absmax[s],  pm.setting["xd"]["storage"][string(s)]["pmin"][nw])
            end
            JuMP.set_upper_bound(e_absmax[s],  pm.setting["xd"]["storage"][string(s)]["pmax"][nw])
        end
    end

    report && _IM.sol_component_value(pm, nw, :storage, :e_absmax, _PM.ids(pm, nw, :storage), e_absmax)
    return (nw,e_absmax)
end

function variable_absorbed_energy(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    e_abs = _PM.var(pm, nw)[:e_abs] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :storage)], base_name="$(nw)_e_abs",
    start = 0)

    for (s, strg) in _PM.ref(pm, nw, :storage)
        e_absmax = _PM.var(pm, nw, :e_absmax, s)
        JuMP.@constraint(pm.model, e_abs[s]  >= 0)
    end

    report && _IM.sol_component_value(pm, nw, :storage, :e_abs, _PM.ids(pm, nw, :storage), e_abs)
end


function variable_storage_power(pm::_PM.AbstractPowerModel; kwargs...)
    variable_storage_power_real(pm; kwargs...)
    variable_storage_power_imaginary(pm; kwargs...)
    variable_storage_power_control_imaginary(pm; kwargs...)
    _PM.variable_storage_current(pm; kwargs...)
    variable_storage_energy(pm; kwargs...)
    variable_storage_charge(pm; kwargs...)
    variable_storage_discharge(pm; kwargs...)
end


function variable_storage_power_real(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    ps = _PM.var(pm, nw)[:ps] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :storage)], base_name="$(nw)_ps",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :storage, i), "ps_start")
    )

    for (s, strg) in _PM.ref(pm, nw, :storage)
        e_absmax = _PM.var(pm, nw, :e_absmax, s)
        JuMP.@constraint(pm.model, ps[s]-e_absmax/4  <= 0)
        JuMP.@constraint(pm.model, ps[s]+e_absmax/4  >= 0)
    end
    report && _IM.sol_component_value(pm, nw, :storage, :ps, _PM.ids(pm, nw, :storage), ps)
end

function variable_storage_power_imaginary(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    qs = _PM.var(pm, nw)[:qs] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :storage)], base_name="$(nw)_qs",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :storage, i), "qs_start")
    )

    for (s, strg) in _PM.ref(pm, nw, :storage)
        e_absmax = _PM.var(pm, nw, :e_absmax, s)
        JuMP.@constraint(pm.model, qs[s]-e_absmax/4  <= 0)
        JuMP.@constraint(pm.model, qs[s]+e_absmax/4  >= 0)
    end

    report && _IM.sol_component_value(pm, nw, :storage, :qs, _PM.ids(pm, nw, :storage), qs)
end

function variable_storage_power_control_imaginary(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    qsc = _PM.var(pm, nw)[:qsc] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :storage)], base_name="$(nw)_qsc",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :storage, i), "qsc_start")
    )

        for (s, strg) in _PM.ref(pm, nw, :storage)
            e_absmax = _PM.var(pm, nw, :e_absmax, s)
            JuMP.@constraint(pm.model, qsc[s]-e_absmax/4  <= 0)
            JuMP.@constraint(pm.model, qsc[s]+e_absmax/4  >= 0)
        end
    report && _IM.sol_component_value(pm, nw, :storage, :qsc, _PM.ids(pm, nw, :storage), qsc)
end

function variable_storage_energy(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    se = _PM.var(pm, nw)[:se] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :storage)], base_name="$(nw)_se",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :storage, i), "se_start", 1)
    )

    for (s, strg) in _PM.ref(pm, nw, :storage)
        e_absmax = _PM.var(pm, nw, :e_absmax, s)
        JuMP.@constraint(pm.model, se[s]-e_absmax  <= 0)
        JuMP.@constraint(pm.model, se[s]  >= 0)
    end

    report && _IM.sol_component_value(pm, nw, :storage, :se, _PM.ids(pm, nw, :storage), se)
end


function variable_storage_discharge(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    sd = _PM.var(pm, nw)[:sd] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :storage)], base_name="$(nw)_sd",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :storage, i), "sd_start", 1)
    )
    for (s, strg) in _PM.ref(pm, nw, :storage)
        e_absmax = _PM.var(pm, nw, :e_absmax, s)
        JuMP.@constraint(pm.model, sd[s]-e_absmax/2  <= 0)
        JuMP.@constraint(pm.model, sd[s]  >= 0)
    end

    report && _IM.sol_component_value(pm, nw, :storage, :sd, _PM.ids(pm, nw, :storage), sd)
end

function variable_storage_charge(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    sc = _PM.var(pm, nw)[:sc] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :storage)], base_name="$(nw)_sc",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :storage, i), "sc_start", 1)
    )
    for (s, strg) in _PM.ref(pm, nw, :storage)
        e_absmax = _PM.var(pm, nw, :e_absmax, s)
        JuMP.@constraint(pm.model, sc[s]-e_absmax/4  <= 0)
        JuMP.@constraint(pm.model, sc[s]  >= 0)
    end

    report && _IM.sol_component_value(pm, nw, :storage, :sc, _PM.ids(pm, nw, :storage), sc)
end

############################# Branches ########################
# same as that in FlexPlan but variable with nw number is returned for time based constraints
function variable_branch_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, relax::Bool=false, report::Bool=true)
    if !relax
        Z_dc_branch_ne = _PM.var(pm, nw)[:branchdc_ne] = JuMP.@variable(pm.model, #branch_ne is also name in PowerModels, branchdc_ne is candidate branches
        [l in _PM.ids(pm, nw, :branchdc_ne)], base_name="$(nw)_branch_ne",
        binary = true,
        start = _PM.comp_start_value(_PM.ref(pm, nw, :branchdc_ne, l), "convdc_tnep_start",  0.0)
        )
    else
        Z_dc_branch_ne = _PM.var(pm, nw)[:branchdc_ne] = JuMP.@variable(pm.model, #branch_ne is also name in PowerModels, branchdc_ne is candidate branches
        [l in _PM.ids(pm, nw, :branchdc_ne)], base_name="$(nw)_branch_ne",
        lower_bound = 0,
        upper_bound = 1,
        start = _PM.comp_start_value(_PM.ref(pm, nw, :branchdc_ne, l), "convdc_tnep_start",  0.0)
        )
    end
    report && _IM.sol_component_value(pm, nw, :branchdc_ne, :isbuilt, _PM.ids(pm, nw, :branchdc_ne), Z_dc_branch_ne)
    return (nw,Z_dc_branch_ne)
end

############################ Binary DC branch constraints #####################################
"variable: `0 <= branch_ne[l] <= 1` for `l` in `branch`es"
function variable_ne_branch_indicator(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, relax::Bool=false, report::Bool=true)
    if !relax
        z_branch_ne = _PM.var(pm, nw)[:branch_ne] = JuMP.@variable(pm.model,
            [l in _PM.ids(pm, nw, :ne_branch)], base_name="$(nw)_branch_ne",
            binary = true,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :ne_branch, l), "branch_tnep_start", 1.0)
        )
    else
        z_branch_ne = _PM.var(pm, nw)[:branch_ne] = JuMP.@variable(pm.model,
            [l in _PM.ids(pm, nw, :ne_branch)], base_name="$(nw)_branch_ne",
            lower_bound = 0.0,
            upper_bound = 1.0,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :ne_branch, l), "branch_tnep_start", 1.0)
        )
    end

    report && _IM.sol_component_value(pm, nw, :ne_branch, :built, _PM.ids(pm, nw, :ne_branch), z_branch_ne)
    return (nw,z_branch_ne)
end


############################### constraints for dc branch convexafy ###############################
#Upper limit for convexafied dc branch
function variable_dcbranch_peak(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    p_rateA = _PM.var(pm, nw)[:p_rateA] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :branchdc)], base_name="$(nw)_p_rateA",
    start = 0)
    if bounded
        for (s, branchdc) in _PM.ref(pm, nw, :branchdc)
            if (haskey(pm.setting,"rebalancing") && pm.setting["rebalancing"]==true)
                JuMP.set_lower_bound(p_rateA[s],  pm.setting["xd"]["branchdc"][string(s)]["rateA"][nw])
            else
                JuMP.set_lower_bound(p_rateA[s],  0)
            end
            JuMP.set_upper_bound(p_rateA[s],  pm.setting["xd"]["branchdc"][string(s)]["rateA"][nw])
        end
    end

    report && _IM.sol_component_value(pm, nw, :branchdc, :p_rateA, _PM.ids(pm, nw, :branchdc), p_rateA)
    return (nw,p_rateA)
end

#DC branch flow for continuous transmission line - convex approximation
function variable_active_dcbranch_flow(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    p = _PM.var(pm, nw)[:p_dcgrid] = JuMP.@variable(pm.model,
    [(l,i,j) in _PM.ref(pm, nw, :arcs_dcgrid)], base_name="$(nw)_pdcgrid",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :branchdc, l), "p_start", 1.0)
    )
    if bounded
        for arc in _PM.ref(pm, nw, :arcs_dcgrid)
            l,i,j = arc
            p_rateA = _PM.var(pm, nw, :p_rateA, l)
            JuMP.@constraint(pm.model, p[arc]-p_rateA  <= 0)
            JuMP.@constraint(pm.model, p[arc]+p_rateA  >= 0)
        end
    end
    report && _IM.sol_component_value_edge(pm, nw, :branchdc, :pf, :pt, _PM.ref(pm, nw, :arcs_dcgrid_from), _PM.ref(pm, nw, :arcs_dcgrid_to), p)
end

############################### constraints for ac branch convexafy ###############################
#Upper limit for convexafied dc branch
function variable_acbranch_peak(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    p_rateAC = _PM.var(pm, nw)[:p_rateAC] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_p_rateAC",
    start = 0)
    if bounded
        for (s, branch) in _PM.ref(pm, nw, :branch)
            if (haskey(pm.setting,"rebalancing") && pm.setting["rebalancing"]==true)
                JuMP.set_lower_bound(p_rateAC[s],  pm.setting["xd"]["branch"][string(s)]["rateA"][nw])
            else
                JuMP.set_lower_bound(p_rateAC[s],  0)
            end
            JuMP.set_upper_bound(p_rateAC[s],  pm.setting["xd"]["branch"][string(s)]["rateA"][nw])
        end
    end

    report && _IM.sol_component_value(pm, nw, :branch, :p_rateAC, _PM.ids(pm, nw, :branch), p_rateAC)
    return (nw,p_rateAC)
end

#Upper limit for convexafied ac branch
function variable_branch_power(pm::_PM.AbstractPowerModel; kwargs...)
    variable_branch_power_real(pm; kwargs...)
    _PM.variable_branch_power_imaginary(pm; kwargs...)
end


"variable: `p[l,i,j]` for `(l,i,j)` in `arcs`"
function variable_branch_power_real(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    p = _PM.var(pm, nw)[:p] = JuMP.@variable(pm.model,
        [(l,i,j) in _PM.ref(pm, nw, :arcs)], base_name="$(nw)_p",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, l), "p_start")
    )

    if bounded
        for arc in _PM.ref(pm, nw, :arcs)
            l,i,j = arc
            p_rateAC = _PM.var(pm, nw, :p_rateAC, l)
            JuMP.@constraint(pm.model, p[arc]-p_rateAC  <= 0)
            JuMP.@constraint(pm.model, p[arc]+p_rateAC  >= 0)
        end
    end

    for (l,branch) in _PM.ref(pm, nw, :branch)
        if haskey(branch, "pf_start")
            f_idx = (l, branch["f_bus"], branch["t_bus"])
            JuMP.set_start_value(p[f_idx], branch["pf_start"])
        end
        if haskey(branch, "pt_start")
            t_idx = (l, branch["t_bus"], branch["f_bus"])
            JuMP.set_start_value(p[t_idx], branch["pt_start"])
        end
    end

    report && _IM.sol_component_value_edge(pm, nw, :branch, :pf, :pt, _PM.ref(pm, nw, :arcs_from), _PM.ref(pm, nw, :arcs_to), p)
end
