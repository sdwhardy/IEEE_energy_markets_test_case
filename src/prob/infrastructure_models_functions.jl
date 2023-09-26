
#aim=jump_result_mip;optimizer=gurobi
function optimize_model!(aim::_IM.AbstractInfrastructureModel; relax_integrality=false, optimizer=nothing, solution_processors=[])
    start_time = time()

    if relax_integrality
        JuMP.relax_integrality(aim.model)
    end

    if JuMP.mode(aim.model) != JuMP.DIRECT && optimizer !== nothing
        if JuMP.backend(aim.model).optimizer === nothing
            JuMP.set_optimizer(aim.model, optimizer)
        else
            Memento.warn(_PM._LOGGER, "Model already contains optimizer, cannot use optimizer specified in `optimize_model!`")
        end
    end

    if JuMP.mode(aim.model) != JuMP.DIRECT && JuMP.backend(aim.model).optimizer === nothing
        Memento.error(_PM._LOGGER, "No optimizer specified in `optimize_model!` or the given JuMP model.")
    end

    _, solve_time, solve_bytes_alloc, sec_in_gc = @timed JuMP.optimize!(aim.model)
    #_, solve_time, solve_bytes_alloc, sec_in_gc = @timed JuMP.optimize!(aim.model)
  
    try
        solve_time = JuMP.solve_time(aim.model)
    catch
        Memento.warn(_PM._LOGGER, "The given optimizer does not provide the SolveTime() attribute, falling back on @timed.  This is not a rigorous timing value.");
    end
    
    Memento.debug(_PM._LOGGER, "JuMP model optimize time: $(time() - start_time)")

    start_time = time()
    result = build_result(aim, solve_time; solution_processors=solution_processors)
    Memento.debug(_PM._LOGGER, "solution build time: $(time() - start_time)")

    #aim.solution = result["solution"]
    return result
end

################# Important trouble shooting code do not erase !!!!!!!!!!!!!!!!!!!!!!
#=
aim=jump_result_mip
optimizer=gurobi
gurobi
if JuMP.termination_status(aim.model) == _MOI.INFEASIBLE_OR_UNBOUNDED
        JuMP.@assert JuMP.termination_status(aim.model) == _MOI.INFEASIBLE
        JuMP.compute_conflict!(aim.model)
        contypes=JuMP.list_of_constraint_types(aim.model)
        #for contype in contypes
        as=_MOI.get.(aim.model, _MOI.ConstraintConflictStatus(),JuMP.all_constraints(aim.model, JuMP.VariableRef, _MOI.EqualTo{Float64}))
        as=_MOI.get.(aim.model, _MOI.ConstraintConflictStatus(),JuMP.all_constraints(aim.model, JuMP.VariableRef, _MOI.GreaterThan{Float64}))
        as=_MOI.get.(aim.model, _MOI.ConstraintConflictStatus(),JuMP.all_constraints(aim.model, JuMP.VariableRef, _MOI.LessThan{Float64}))
        for (i,a) in enumerate(as)
        if (a!=_MOI.NOT_IN_CONFLICT)   
            println(i, " ", a);end
        end 
        JuMP.all_constraints(aim.model, JuMP.VariableRef, _MOI.LessThan{Float64})[119527]
        JuMP.all_constraints(aim.model, JuMP.VariableRef, _MOI.GreaterThan{Float64})[181267]
    end
=#
########################################################################################

function build_result(aim::_IM.AbstractInfrastructureModel, solve_time; solution_processors=[])
    # try-catch is needed until solvers reliably support ResultCount()
    result_count = 1
    try
        result_count = JuMP.result_count(aim.model)
    catch
        Memento.warn(_LOGGER, "the given optimizer does not provide the ResultCount() attribute, assuming the solver returned a solution which may be incorrect.");
    end

    solution = Dict{String,Any}()

    if result_count > 0
        solution = build_solution(aim, post_processors=solution_processors)
    else
        Memento.warn(_LOGGER, "model has no results, solution cannot be built")
    end

    result = Dict{String,Any}(
        "optimizer" => JuMP.solver_name(aim.model),
        "termination_status" => JuMP.termination_status(aim.model),
        "primal_status" => JuMP.primal_status(aim.model),
        "dual_status" => JuMP.dual_status(aim.model),
        "objective" => _IM._guard_objective_value(aim.model),
        "objective_lb" => _IM._guard_objective_bound(aim.model),
        "solve_time" => solve_time,
        "solution" => solution,
    )

    for sol_count=1:1:JuMP.result_count(aim.model)
        push!(result,"objective"*string(sol_count)=>JuMP.objective_value(aim.model,result=sol_count))
    end

    return result
end

function build_solution(aim::_IM.AbstractInfrastructureModel; post_processors=[])
    
    sol = Dict{String, Any}()
    #sol["multiinfrastructure"] = true

    for sol_count=1:1:JuMP.result_count(aim.model)
        push!(sol,string(sol_count)=>Dict{String, Any}())
        for nw in keys(aim.sol[:nw])
            sol[string(sol_count)][string(nw)] = build_solution_values(aim.sol[:nw][nw], sol_count)
        end
    end

   #= _IM.solution_preprocessor(aim, sol)

    for post_processor in post_processors
        post_processor(aim, sol)
    end

    #for it in it_ids(aim)
    #    it_str = string(it)
        data_it = aim.data

        if _IM.ismultinetwork(data_it)
            sol["it"][it_str]["multinetwork"] = true
        else
            for (k, v) in sol["it"][it_str]["nw"]["$(nw_id_default)"]
                sol["it"][it_str][k] = v
            end

            sol["it"][it_str]["multinetwork"] = false
            delete!(sol["it"][it_str], "nw")
        end

        if !ismultiinfrastructure(aim)
            for (k, v) in sol["it"][it_str]
                sol[k] = v
            end

            delete!(sol["it"], it_str)
        end
    end

    if !ismultiinfrastructure(aim)
        sol["multiinfrastructure"] = false
        delete!(sol, "it")
    end=#

    return sol
end

function build_solution_values(var::Dict, sol_count)
    sol = Dict{String, Any}()

    for (key, val) in var
        sol[string(key)] = build_solution_values(val, sol_count)
    end

    return sol
end

""
function build_solution_values(var::Array{<:Any,1}, sol_count)
    return [build_solution_values(val, sol_count) for val in var]
end

""
function build_solution_values(var::Array{<:Any,2}, sol_count)
    return [build_solution_values(var[i, j], sol_count) for i in 1:size(var, 1), j in 1:size(var, 2)]
end

""
function build_solution_values(var::Number, sol_count)
    return var
end

""
function build_solution_values(var::JuMP.VariableRef, sol_count)
    return JuMP.value(var;result=sol_count)
end

""
function build_solution_values(var::JuMP.GenericAffExpr, sol_count)
    return JuMP.value(var;result=sol_count)
end

""
function build_solution_values(var::JuMP.GenericQuadExpr, sol_count)
    return JuMP.value(var;result=sol_count)
end

""
function build_solution_values(var::JuMP.NonlinearExpression, sol_count)
    return JuMP.value(var;result=sol_count)
end

""
function build_solution_values(var::JuMP.ConstraintRef, sol_count)
    return JuMP.dual(var;result=sol_count)
end

""
function build_solution_values(var::Any, sol_count)
    Memento.warn(_IM._LOGGER, "build_solution_values found unknown type $(typeof(var))")
    return var
end
