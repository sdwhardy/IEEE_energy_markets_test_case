function run_model_p1(file::String, model_type::Type, optimizer, build_method; kwargs...)
    data = PowerModels.parse_file(file)
    return run_model_p1(data, model_type, build_method; kwargs...)
end

""
function run_model_p1(data::Dict{String,<:Any}, model_type::Type, build_method; ref_extensions=[], multinetwork=false, multiconductor=false, kwargs...)
    if multinetwork != _IM.ismultinetwork(data)
        model_requirement = multinetwork ? "multi-network" : "single-network"
        data_type = _IM.ismultinetwork(data) ? "multi-network" : "single-network"
        Memento.error(_LOGGER, "attempted to build a $(model_requirement) model with $(data_type) data")
    end

    if multiconductor != _PM.ismulticonductor(data)
        model_requirement = multiconductor ? "multi-conductor" : "single-conductor"
        data_type = _PM.ismulticonductor(data) ? "multi-conductor" : "single-conductor"
        Memento.error(_LOGGER, "attempted to build a $(model_requirement) model with $(data_type) data")
    end

    start_time = time()
    pm = _PM.instantiate_model(data, model_type, build_method; ref_extensions=ref_extensions, kwargs...)
    Memento.debug(_PM._LOGGER, "pm model build time: $(time() - start_time)")

    return pm
end
#pm=jump_result_mip; optimizer=gurobi
function run_model_p2(pm, optimizer, solution_processors=[], kwargs...)

    start_time = time()
    result = optimize_model!(pm, optimizer=optimizer, solution_processors=solution_processors)
    Memento.debug(_PM._LOGGER, "pm model solve and solution time: $(time() - start_time)")

    return result
end


""
function instantiate_model(file::String, model_type::Type, build_method; kwargs...)
    data = PowerModels.parse_file(file)
    return instantiate_model(data, model_type, build_method; kwargs...)
end

""
function instantiate_model(data::Dict{String,<:Any}, model_type::Type, build_method; kwargs...)
    return _IM.instantiate_model(data, model_type, build_method, ref_add_core!, _pm_global_keys; kwargs...)
end


##########################
