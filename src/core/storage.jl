
###################################### Storage #########################################
function constraint_storage_losses(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    storage = _PM.ref(pm, nw, :storage, i)

    _PM.constraint_storage_losses(pm, nw, i, storage["storage_bus"], storage["r"], storage["x"], storage["p_loss"], storage["q_loss"])
end


function constraint_storage_thermal_limit(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    ps = _PM.var(pm, nw, :ps, i)
    e_absmax = _PM.var(pm, nw, :e_absmax, i)
    JuMP.@constraint(pm.model, ps-e_absmax/2  <= 0)
    JuMP.@constraint(pm.model, ps+e_absmax/4  >= 0)
end

function constraint_storage_excl_slack(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    sc = _PM.var(pm, nw, :sc, i)
    sd = _PM.var(pm, nw, :sd, i)
    e_absmax = _PM.var(pm, nw, :e_absmax, i)

    JuMP.@constraint(pm.model, sc + sd <= e_absmax/2)
end


################################################################################
####################### functions from flexplan ################################
################# copied as updates keep breaking code #########################
################################################################################
## New storage to reference model
################################################################################
function add_candidate_storage!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    for (n, nw_ref) in ref[:nw]
        if haskey(nw_ref, :ne_storage)
            bus_storage_ne = Dict([(i, []) for (i,bus) in nw_ref[:bus]])
            for (i,storage) in nw_ref[:ne_storage]
                push!(bus_storage_ne[storage["storage_bus"]], i)
            end
            nw_ref[:bus_storage_ne] = bus_storage_ne
        end
    end
end


function constraint_storage_state(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    storage = _PM.ref(pm, nw, :storage, i)

    if haskey(_PM.ref(pm, nw), :time_elapsed)
        time_elapsed = _PM.ref(pm, nw, :time_elapsed)
    else
        Memento.warn(_LOGGER, "network data should specify time_elapsed, using 1.0 as a default")
        time_elapsed = 1.0
    end
    constraint_storage_state_initial(pm, nw, i, storage["energy"], storage["charge_efficiency"], storage["discharge_efficiency"], storage["stationary_energy_inflow"], storage["stationary_energy_outflow"], storage["self_discharge_rate"], time_elapsed)
end


function constraint_storage_state(pm::_PM.AbstractPowerModel, i::Int, nw_1::Int, nw_2::Int)
    storage = _PM.ref(pm, nw_2, :storage, i)

    if haskey(_PM.ref(pm, nw_2), :time_elapsed)
        time_elapsed = _PM.ref(pm, nw_2, :time_elapsed)
    else
        Memento.warn(_LOGGER, "network $(nw_2) should specify time_elapsed, using 1.0 as a default")
        time_elapsed = 1.0
    end

    if haskey(_PM.ref(pm, nw_1, :storage), i)
        constraint_storage_state(pm, nw_1, nw_2, i, storage["charge_efficiency"], storage["discharge_efficiency"], storage["stationary_energy_inflow"], storage["stationary_energy_outflow"], storage["self_discharge_rate"], time_elapsed)
    else
        # if the storage device has status=0 in nw_1, then the stored energy variable will not exist. Initialize storage from data model instead.
        Memento.warn(_LOGGER, "storage component $(i) was not found in network $(nw_1) while building constraint_storage_state between networks $(nw_1) and $(nw_2). Using the energy value from the storage component in network $(nw_2) instead")
        constraint_storage_state_initial(pm, nw_2, i, storage["energy"], storage["charge_efficiency"], storage["discharge_efficiency"], storage["stationary_energy_inflow"], storage["stationary_energy_outflow"], storage["self_discharge_rate"], time_elapsed)
    end
end

function constraint_storage_state(pm::_PM.AbstractPowerModel, n_1::Int, n_2::Int, i::Int, charge_eff, discharge_eff, inflow, outflow, self_discharge_rate, time_elapsed)
    sc_2 = _PM.var(pm, n_2, :sc, i)
    sd_2 = _PM.var(pm, n_2, :sd, i)
    se_2 = _PM.var(pm, n_2, :se, i)
    se_1 = _PM.var(pm, n_1, :se, i)

    JuMP.@constraint(pm.model, se_2 == ((1-self_discharge_rate)^time_elapsed)*se_1 + time_elapsed*(charge_eff*sc_2 - sd_2/discharge_eff + inflow - outflow))
end

function constraint_storage_state_initial(pm::_PM.AbstractPowerModel, n::Int, i::Int, energy, charge_eff, discharge_eff, inflow, outflow, self_discharge_rate, time_elapsed)
    sc = _PM.var(pm, n, :sc, i)
    sd = _PM.var(pm, n, :sd, i)
    se = _PM.var(pm, n, :se, i)

    JuMP.@constraint(pm.model, se == ((1-self_discharge_rate)^time_elapsed)*energy + time_elapsed*(charge_eff*sc - sd/discharge_eff + inflow - outflow))
end

function constraint_storage_state_final(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    storage = _PM.ref(pm, nw, :storage, i)
    constraint_storage_state_final(pm, nw, i, storage["energy"])
end

function constraint_storage_state_final(pm::_PM.AbstractPowerModel, n::Int, i::Int, energy)
    se = _PM.var(pm, n, :se, i)

    JuMP.@constraint(pm.model, se >= energy)
end

function constraint_maximum_absorption(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    storage = _PM.ref(pm, nw, :storage, i)

    if haskey(_PM.ref(pm, nw), :time_elapsed)
        time_elapsed = _PM.ref(pm, nw, :time_elapsed)
    else
        Memento.warn(_LOGGER, "network data should specify time_elapsed, using 1.0 as a default")
        time_elapsed = 1.0
    end
    constraint_maximum_absorption_initial(pm, nw, i, time_elapsed)
end

function  constraint_maximum_absorption(pm::_PM.AbstractPowerModel, i::Int, nw_1::Int, nw_2::Int)
    storage = _PM.ref(pm, nw_2, :storage, i)

    if haskey(_PM.ref(pm, nw_2), :time_elapsed)
        time_elapsed = _PM.ref(pm, nw_2, :time_elapsed)
    else
        Memento.warn(_LOGGER, "network $(nw_2) should specify time_elapsed, using 1.0 as a default")
        time_elapsed = 1.0
    end

    if haskey(_PM.ref(pm, nw_1, :storage), i)
        constraint_maximum_absorption(pm, nw_1, nw_2, i, time_elapsed)
    else
        # if the storage device has status=0 in nw_1, then the stored energy variable will not exist. Initialize storage from data model instead.
        Memento.warn(_LOGGER, "storage component $(i) was not found in network $(nw_1) while building constraint_storage_state between networks $(nw_1) and $(nw_2). Using the energy value from the storage component in network $(nw_2) instead")
        constraint_maximum_absorption_initial(pm, nw_2, i, time_elapsed)
    end
end

function constraint_maximum_absorption(pm::_PM.AbstractPowerModel, n_1::Int, n_2::Int, i::Int, time_elapsed)
    sc_2 = _PM.var(pm, n_2, :sc, i)
    e_abs_2 = _PM.var(pm, n_2, :e_abs, i)
    e_abs_1 = _PM.var(pm, n_1, :e_abs, i)

    JuMP.@constraint(pm.model, e_abs_2 - e_abs_1 == time_elapsed * sc_2)
end

function constraint_maximum_absorption_initial(pm::_PM.AbstractPowerModel, n::Int, i::Int, time_elapsed)
    sc = _PM.var(pm, n, :sc, i)
    e_abs = _PM.var(pm, n, :e_abs, i)

    JuMP.@constraint(pm.model, e_abs == time_elapsed * sc)
end