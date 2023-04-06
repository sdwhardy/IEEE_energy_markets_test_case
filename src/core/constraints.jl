####################################### power balance ############################################
############## Nodal Market clearing
function constraint_power_balance_acne_dcne_strg(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    bus_arcs = PowerModels.ref(pm, nw, :bus_arcs, i)
    bus_arcs_ne = PowerModels.ref(pm, nw, :ne_bus_arcs, i)
    bus_arcs_dc = PowerModels.ref(pm, nw, :bus_arcs_dc, i)
    bus_gens = PowerModels.ref(pm, nw, :bus_gens, i)
    bus_convs_ac = PowerModels.ref(pm, nw, :bus_convs_ac, i)
    bus_convs_ac_ne = PowerModels.ref(pm, nw, :bus_convs_ac_ne, i)
    bus_loads = PowerModels.ref(pm, nw, :bus_loads, i)
    bus_shunts = PowerModels.ref(pm, nw, :bus_shunts, i)
    bus_storage = PowerModels.ref(pm, nw, :bus_storage, i)
    bus_storage_ne = 1

    pd = Dict(k => PowerModels.ref(pm, nw, :load, k, "pd") for k in bus_loads)
    qd = Dict(k => PowerModels.ref(pm, nw, :load, k, "qd") for k in bus_loads)

    gs = Dict(k => PowerModels.ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bs = Dict(k => PowerModels.ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)
    if (haskey(pm.setting,"agent") && pm.setting["agent"]!="")
        cost=constraint_power_balance_acne_dcne_strg_admm(pm, nw, i, bus_arcs, bus_arcs_ne, bus_arcs_dc, bus_gens, bus_convs_ac, bus_convs_ac_ne, bus_loads, bus_shunts, bus_storage, bus_storage_ne, pd, qd, gs, bs)
        return cost
    else
        constraint_power_balance_acne_dcne_strg(pm, nw, i, bus_arcs, bus_arcs_ne, bus_arcs_dc, bus_gens, bus_convs_ac, bus_convs_ac_ne, bus_loads, bus_shunts, bus_storage, bus_storage_ne, pd, qd, gs, bs)
    end
end


#Power balance constraint including candidate storage
function constraint_power_balance_acne_dcne_strg(pm::_PM.AbstractDCPModel, n::Int, i::Int, bus_arcs, bus_arcs_ne, bus_arcs_dc, bus_gens, bus_convs_ac, bus_convs_ac_ne, bus_loads, bus_shunts, bus_storage, bus_storage_ne, pd, qd, gs, bs)
    p = _PM.var(pm, n, :p)
    pg = _PM.var(pm, n, :pg)
    pconv_grid_ac_ne = _PM.var(pm, n, :pconv_tf_fr_ne)
    pconv_grid_ac = _PM.var(pm, n, :pconv_tf_fr)
    pconv_ac = _PM.var(pm, n, :pconv_ac)
    pconv_ac_ne = _PM.var(pm, n, :pconv_ac_ne)
    p_ne = _PM.var(pm, n, :p_ne)
    ps   = _PM.var(pm, n, :ps)
    v = 1

    cstr=JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(p_ne[a] for a in bus_arcs_ne) + sum(pconv_grid_ac[c] for c in bus_convs_ac) + sum(pconv_grid_ac_ne[c] for c in bus_convs_ac_ne)  == sum(pg[g] for g in bus_gens) - sum(ps[s] for s in bus_storage) - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts)*v^2)
    
    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = NaN
    end
end


########### Zonal Market clearing

##################### node in zone
function constraint_power_balance_dc_dcne_hm_node(pm::_PM.AbstractPowerModel, i, is::Set{Int64}; nw::Int=pm.cnw)

    bus_arcs_dcgrid = PowerModels.ref(pm, nw, :bus_arcs_dcgrid, i)
    bus_arcs_dcgrid_ne = PowerModels.ref(pm, nw, :bus_arcs_dcgrid_ne, i)

    bus_arcs_dcgrid_ne_inner=sum([(1-pm.setting["balancing_reserve"])*PowerModels.ref(pm, nw, :branchdc_ne, a[1])["rateA"]*PowerModels.var(pm, nw, :branchdc_ne, a[1]) for a in bus_arcs_dcgrid_ne if (issubset([a[2]],is) && issubset([a[3]],is))]) #println(string(a[1])*" "*string(a[2])*" "*string(a[3]))

    bus_arcs_dcgrid_ne=[a for a in bus_arcs_dcgrid_ne if !(issubset([a[2]],is) && issubset([a[3]],is))]
    
    bus_convs_dc = PowerModels.ref(pm, nw, :bus_convs_dc, i)
    bus_convs_dc_ne = PowerModels.ref(pm, nw, :bus_convs_dc_ne, i)
    bus_convs_dc_ne = PowerModels.ref(pm, nw, :bus_convs_dc_ne, i)
    pd=PowerModels.ref(pm, nw, :busdc, i)["Pdc"]

    if (haskey(pm.setting,"agent") && pm.setting["agent"]!="")
        return cost
    else
        constraint_power_balance_dc_dcne_hm_node(pm, nw, is, bus_arcs_dcgrid, bus_arcs_dcgrid_ne, bus_convs_dc, bus_convs_dc_ne, pd, bus_arcs_dcgrid_ne_inner)
    end
end

#Power balance constraint including candidate storage
function constraint_power_balance_dc_dcne_hm_node(pm::_PM.AbstractPowerModel, n::Int, is::Set{Int64}, bus_arcs_dcgrid, bus_arcs_dcgrid_ne, bus_convs_dc, bus_convs_dc_ne, pd, bus_arcs_dcgrid_ne_inner)
    p_dcgrid = _PM.var(pm, n, :p_dcgrid)
    p_dcgrid_ne = _PM.var(pm, n, :p_dcgrid_ne)
    pconv_dc = _PM.var(pm, n, :pconv_dc)
    pconv_dc_ne = _PM.var(pm, n, :pconv_dc_ne)

    cstr1=JuMP.@constraint(pm.model, sum(p_dcgrid[a] for a in bus_arcs_dcgrid) + sum(p_dcgrid_ne[a] for a in bus_arcs_dcgrid_ne) + sum(pconv_dc[c] for c in bus_convs_dc) + sum(pconv_dc_ne[c] for c in bus_convs_dc_ne) - bus_arcs_dcgrid_ne_inner  <= 0)

    cstr2=JuMP.@constraint(pm.model, sum(p_dcgrid[a] for a in bus_arcs_dcgrid) + sum(p_dcgrid_ne[a] for a in bus_arcs_dcgrid_ne) + sum(pconv_dc[c] for c in bus_convs_dc) + sum(pconv_dc_ne[c] for c in bus_convs_dc_ne) + bus_arcs_dcgrid_ne_inner  >= 0)
end


function constraint_power_balance_acne_dcne_strg_hm_node(pm::_PM.AbstractPowerModel, i, is::Set{Int64}; nw::Int=pm.cnw)

    bus_arcs = PowerModels.ref(pm, nw, :bus_arcs, i)
    ne_bus_arcs = PowerModels.ref(pm, nw, :ne_bus_arcs, i)
    ne_bus_arcs_inner=[(1-pm.setting["balancing_reserve"])*PowerModels.ref(pm, nw, :ne_branch, a[1])["rate_a"]*PowerModels.var(pm, nw, :branch_ne, a[1]) for a in ne_bus_arcs if (issubset([a[2]],is) && issubset([a[3]],is))] #println(string(a[1])*" "*string(a[2])*" "*string(a[3]))
    if (length(ne_bus_arcs_inner)>0)
        ne_bus_arcs_inner=sum(ne_bus_arcs_inner)
    else
        ne_bus_arcs_inner=0
    end

    ne_bus_arcs=[a for a in ne_bus_arcs if !(issubset([a[2]],is) && issubset([a[3]],is))]
    bus_arcs_dc = PowerModels.ref(pm, nw, :bus_arcs_dc, i)
    bus_gens = PowerModels.ref(pm, nw, :bus_gens, i)
    bus_convs_ac = PowerModels.ref(pm, nw, :bus_convs_ac, i)
    bus_convs_ac_ne = PowerModels.ref(pm, nw, :bus_convs_ac_ne, i)
    bus_loads = PowerModels.ref(pm, nw, :bus_loads, i)
    bus_shunts = PowerModels.ref(pm, nw, :bus_shunts, i)
    bus_storage = PowerModels.ref(pm, nw, :bus_storage, i)
    bus_storage_ne=[];
    pd = Dict(k => PowerModels.ref(pm, nw, :load, k, "pd") for k in bus_loads)
    qd = Dict(k => PowerModels.ref(pm, nw, :load, k, "qd") for k in bus_loads)

    gs = Dict(k => PowerModels.ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bs = Dict(k => PowerModels.ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)
    if (haskey(pm.setting,"agent") && pm.setting["agent"]!="")
        cost=constraint_power_balance_acne_dcne_strg_hm_admm(pm, nw, is, bus_arcs, bus_arcs_ne, bus_arcs_dc, bus_gens, bus_convs_ac, bus_convs_ac_ne, bus_loads, bus_shunts, bus_storage, bus_storage_ne, pd, qd, gs, bs)
        return cost
    else
        constraint_power_balance_acne_dcne_strg_hm_node(pm, nw, is, bus_arcs, ne_bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_convs_ac_ne, bus_loads, bus_shunts, bus_storage, bus_storage_ne, pd, qd, gs, bs, ne_bus_arcs_inner)
    end
end

#Power balance constraint including candidate storage
function constraint_power_balance_acne_dcne_strg_hm_node(pm::_PM.AbstractDCPModel, n::Int, is::Set{Int64}, bus_arcs, bus_arcs_ne, bus_arcs_dc, bus_gens, bus_convs_ac, bus_convs_ac_ne, bus_loads, bus_shunts, bus_storage, bus_storage_ne, pd, qd, gs, bs, ne_bus_arcs_inner)
    p = _PM.var(pm, n, :p)
    pg = _PM.var(pm, n, :pg)
    pconv_grid_ac_ne = _PM.var(pm, n, :pconv_tf_fr_ne)
    pconv_grid_ac = _PM.var(pm, n, :pconv_tf_fr)
    pconv_ac = _PM.var(pm, n, :pconv_ac)
    pconv_ac_ne = _PM.var(pm, n, :pconv_ac_ne)
    p_ne = _PM.var(pm, n, :p_ne)
    ps   = _PM.var(pm, n, :ps)
    v = 1

    cstr1=JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(p_ne[a] for a in bus_arcs_ne) + sum(pconv_grid_ac[c] for c in bus_convs_ac) + sum(pconv_grid_ac_ne[c] for c in bus_convs_ac_ne)  - sum(pg[g] for g in bus_gens) - sum(ps[s] for s in bus_storage) + sum(pd[d] for d in bus_loads) + sum(gs[s] for s in bus_shunts)*v^2 - ne_bus_arcs_inner <= 0)
    cstr2=JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(p_ne[a] for a in bus_arcs_ne) + sum(pconv_grid_ac[c] for c in bus_convs_ac) + sum(pconv_grid_ac_ne[c] for c in bus_convs_ac_ne)  - sum(pg[g] for g in bus_gens) - sum(ps[s] for s in bus_storage) + sum(pd[d] for d in bus_loads) + sum(gs[s] for s in bus_shunts)*v^2 + ne_bus_arcs_inner >= 0)
end

function constraint_power_balance_dc_dcne_hm(pm::_PM.AbstractPowerModel, is::Set{Int64}; nw::Int=pm.cnw)
    bus_arcs_dcgrid=[];for (i,v) in enumerate(is);
        if (i==1);bus_arcs_dcgrid=PowerModels.ref(pm, nw, :bus_arcs_dcgrid, v)
        else;bus_arcs_dcgrid=vcat(bus_arcs_dcgrid,PowerModels.ref(pm, nw, :bus_arcs_dcgrid, v))
        end;end
        bus_arcs_dcgrid=[a for a in bus_arcs_dcgrid if !(issubset([a[2]],is) && issubset([a[3]],is))] #println(string(a[1])*" "*string(a[2])*" "*string(a[3]))
        bus_arcs_dcgrid_ne=[];for (i,v) in enumerate(is);

        if (i==1);bus_arcs_dcgrid_ne=PowerModels.ref(pm, nw, :bus_arcs_dcgrid_ne, v)
        else;bus_arcs_dcgrid_ne=vcat(bus_arcs_dcgrid_ne,PowerModels.ref(pm, nw, :bus_arcs_dcgrid_ne, v))
        end;end
    bus_arcs_dcgrid_ne=[a for a in bus_arcs_dcgrid_ne if !(issubset([a[2]],is) && issubset([a[3]],is))] #println(string(a[1])*" "*string(a[2])*" "*string(a[3]))
  
    bus_convs_dc=[];for (i,v) in enumerate(is);
        if (i==1);bus_convs_dc=PowerModels.ref(pm, nw, :bus_convs_dc, v)
        else;bus_convs_dc=vcat(bus_convs_dc,PowerModels.ref(pm, nw, :bus_convs_dc, v))
        end;end
  
    bus_convs_dc_ne=[];for (i,v) in enumerate(is);
        if (i==1);bus_convs_dc_ne=PowerModels.ref(pm, nw, :bus_convs_dc_ne, v)
        else;bus_convs_dc_ne=vcat(bus_convs_dc_ne,PowerModels.ref(pm, nw, :bus_convs_dc_ne, v))
        end;end
  
    pd=[];for (i,v) in enumerate(is);
        if (i==1);pd=PowerModels.ref(pm, nw, :busdc, v)["Pdc"]
        else;pd=vcat(pd,PowerModels.ref(pm, nw, :busdc, v)["Pdc"])
        end;end
  
    if (haskey(pm.setting,"agent") && pm.setting["agent"]!="")
        return cost
    else
        constraint_power_balance_dc_dcne_hm(pm, nw, is, bus_arcs_dcgrid, bus_arcs_dcgrid_ne, bus_convs_dc, bus_convs_dc_ne, pd)
    end
end

#Power balance constraint including candidate storage
function constraint_power_balance_dc_dcne_hm(pm::_PM.AbstractPowerModel, n::Int, is::Set{Int64}, bus_arcs_dcgrid, bus_arcs_dcgrid_ne, bus_convs_dc, bus_convs_dc_ne, pd)
    p_dcgrid = _PM.var(pm, n, :p_dcgrid)
    p_dcgrid_ne = _PM.var(pm, n, :p_dcgrid_ne)
    pconv_dc = _PM.var(pm, n, :pconv_dc)
    pconv_dc_ne = _PM.var(pm, n, :pconv_dc_ne)
    cstr=JuMP.@constraint(pm.model, sum(p_dcgrid[a] for a in bus_arcs_dcgrid) + sum(p_dcgrid_ne[a] for a in bus_arcs_dcgrid_ne) + sum(pconv_dc[c] for c in bus_convs_dc) + sum(pconv_dc_ne[c] for c in bus_convs_dc_ne)  == -1*sum(pd))
end

function constraint_power_balance_dcne_dcne_hm(pm::_PM.AbstractPowerModel, is::Set{Int64}; nw::Int=pm.cnw)

    bus_i=[];for (i,v) in enumerate(is);
        if (i==1);bus_i=PowerModels.ref(pm, nw, :busdc_ne, v)["busdc_i"]
        else;bus_i=vcat(bus_i,PowerModels.ref(pm, nw, :busdc_ne, v)["busdc_i"])
        end;end

    bus_arcs_dcgrid_ne=[];for (i,v) in enumerate(bus_i);
        if (i==1);bus_arcs_dcgrid_ne=PowerModels.ref(pm, nw, :bus_arcs_dcgrid_ne, v)
        else;bus_arcs_dcgrid_ne=vcat(bus_arcs_dcgrid_ne,PowerModels.ref(pm, nw, :bus_arcs_dcgrid_ne, v))
        end;end
        bus_arcs_dcgrid_ne=[a for a in bus_arcs_dcgrid_ne if !(issubset([a[2]],is) && issubset([a[3]],is))] #println(string(a[1])*" "*string(a[2])*" "*string(a[3]))
    
    bus_ne_convs_dc_ne=[];for (i,v) in enumerate(bus_i);
        if (i==1);bus_ne_convs_dc_ne=PowerModels.ref(pm, nw, :bus_ne_convs_dc_ne, v)
        else;bus_ne_convs_dc_ne=vcat(bus_ne_convs_dc_ne,PowerModels.ref(pm, nw, :bus_ne_convs_dc_ne, v))
        end;end

    pd_ne=[];for (i,v) in enumerate(is);
        if (i==1);pd_ne=PowerModels.ref(pm, nw, :busdc_ne, v)["Pdc"]
        else;pd_ne=vcat(pd_ne,PowerModels.ref(pm, nw, :busdc_ne, v)["Pdc"])
        end;end

    if (length(pd_ne)>0)
            constraint_power_balance_dcne_dcne_hm(pm, nw, is, bus_arcs_dcgrid_ne, bus_ne_convs_dc_ne, pd_ne);end
end


function constraint_power_balance_dcne_dcne_hm(pm::_PM.AbstractPowerModel, n::Int, is::Set{Int64}, bus_arcs_dcgrid_ne, bus_ne_convs_dc_ne, pd_ne)
p_dcgrid_ne = _PM.var(pm, n, :p_dcgrid_ne)
pconv_dc_ne = _PM.var(pm, n, :pconv_dc_ne)
xb = _PM.var(pm, n, :branchdc_ne)
xc = _PM.var(pm, n, :conv_ne)
cstr = JuMP.@constraint(pm.model, sum(p_dcgrid_ne[a] for a in bus_arcs_dcgrid_ne) + sum(pconv_dc_ne[c] for c in bus_ne_convs_dc_ne)  == -1*sum(pd_ne))
    if _IM.report_duals(pm)
        for i in is
            _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr
            _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = NaN
        end
    end
end

function constraint_power_balance_acne_dcne_strg_hm(pm::_PM.AbstractPowerModel, is::Set{Int64}; nw::Int=pm.cnw)

    bus_arcs=[];for (i,v) in enumerate(is);
        if (i==1);bus_arcs=PowerModels.ref(pm, nw, :bus_arcs, v)
        else;bus_arcs=vcat(bus_arcs,PowerModels.ref(pm, nw, :bus_arcs, v))
        end;end
    bus_arcs=[a for a in bus_arcs if !(issubset([a[2]],is) && issubset([a[3]],is))] #println(string(a[1])*" "*string(a[2])*" "*string(a[3]))
    
    bus_arcs_ne=[];for (i,v) in enumerate(is);
        if (i==1);bus_arcs_ne=PowerModels.ref(pm, nw, :ne_bus_arcs, v)
        else;bus_arcs_ne=vcat(bus_arcs_ne,PowerModels.ref(pm, nw, :ne_bus_arcs, v))
        end;end
    bus_arcs_ne=[a for a in bus_arcs_ne if !(issubset([a[2]],is) && issubset([a[3]],is))] #println(string(a[1])*" "*string(a[2])*" "*string(a[3]))
    
    bus_arcs_dc=[];for (i,v) in enumerate(is);
        if (i==1);bus_arcs_dc=PowerModels.ref(pm, nw, :bus_arcs_dc, v)
        else;bus_arcs_dc=vcat(bus_arcs_dc,PowerModels.ref(pm, nw, :bus_arcs_dc, v))
        end;end
    bus_arcs_dc=[a for a in bus_arcs_dc if !(issubset([a[2]],is) && issubset([a[3]],is))] #println(string(a[1])*" "*string(a[2])*" "*string(a[3]))
    
    bus_gens=[];for (i,v) in enumerate(is);
        if (i==1);bus_gens=PowerModels.ref(pm, nw, :bus_gens, v)
        else;bus_gens=vcat(bus_gens,PowerModels.ref(pm, nw, :bus_gens, v))
        end;end
    bus_convs_ac=[];for (i,v) in enumerate(is);
        if (i==1);bus_convs_ac=PowerModels.ref(pm, nw, :bus_convs_ac, v)
        else;bus_convs_ac=vcat(bus_convs_ac,PowerModels.ref(pm, nw, :bus_convs_ac, v))
        end;end
    bus_convs_ac_ne=[];for (i,v) in enumerate(is);
        if (i==1);bus_convs_ac_ne=PowerModels.ref(pm, nw, :bus_convs_ac_ne, v)
        else;bus_convs_ac_ne=vcat(bus_convs_ac_ne,PowerModels.ref(pm, nw, :bus_convs_ac_ne, v))
        end;end
    bus_loads=[];for (i,v) in enumerate(is);
        if (i==1);bus_loads=PowerModels.ref(pm, nw, :bus_loads, v)
        else;bus_loads=vcat(bus_loads,PowerModels.ref(pm, nw, :bus_loads, v))
        end;end
    bus_shunts=[];for (i,v) in enumerate(is);
        if (i==1);bus_shunts=PowerModels.ref(pm, nw, :bus_shunts, v)
        else;bus_shunts=vcat(bus_shunts,PowerModels.ref(pm, nw, :bus_shunts, v))
        end;end
    bus_storage=[];for (i,v) in enumerate(is);
        if (i==1);bus_storage=PowerModels.ref(pm, nw, :bus_storage, v)
        else;bus_storage=vcat(bus_storage,PowerModels.ref(pm, nw, :bus_storage, v))
        end;end
    bus_storage_ne=[];
    pd = Dict(k => PowerModels.ref(pm, nw, :load, k, "pd") for k in bus_loads)
    qd = Dict(k => PowerModels.ref(pm, nw, :load, k, "qd") for k in bus_loads)

    gs = Dict(k => PowerModels.ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bs = Dict(k => PowerModels.ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)
    if (haskey(pm.setting,"agent") && pm.setting["agent"]!="")
        cost=constraint_power_balance_acne_dcne_strg_hm_admm(pm, nw, is, bus_arcs, bus_arcs_ne, bus_arcs_dc, bus_gens, bus_convs_ac, bus_convs_ac_ne, bus_loads, bus_shunts, bus_storage, bus_storage_ne, pd, qd, gs, bs)
        return cost
    else
        constraint_power_balance_acne_dcne_strg_hm(pm, nw, is, bus_arcs, bus_arcs_ne, bus_arcs_dc, bus_gens, bus_convs_ac, bus_convs_ac_ne, bus_loads, bus_shunts, bus_storage, bus_storage_ne, pd, qd, gs, bs)
    end
end

#Power balance constraint including candidate storage
function constraint_power_balance_acne_dcne_strg_hm(pm::_PM.AbstractDCPModel, n::Int, is::Set{Int64}, bus_arcs, bus_arcs_ne, bus_arcs_dc, bus_gens, bus_convs_ac, bus_convs_ac_ne, bus_loads, bus_shunts, bus_storage, bus_storage_ne, pd, qd, gs, bs)
    p = _PM.var(pm, n, :p)
    pg = _PM.var(pm, n, :pg)
    pconv_grid_ac_ne = _PM.var(pm, n, :pconv_tf_fr_ne)
    pconv_grid_ac = _PM.var(pm, n, :pconv_tf_fr)
    pconv_ac = _PM.var(pm, n, :pconv_ac)
    pconv_ac_ne = _PM.var(pm, n, :pconv_ac_ne)
    p_ne = _PM.var(pm, n, :p_ne)
    ps   = _PM.var(pm, n, :ps)
    v = 1

    cstr=JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(p_ne[a] for a in bus_arcs_ne) + sum(pconv_grid_ac[c] for c in bus_convs_ac) + sum(pconv_grid_ac_ne[c] for c in bus_convs_ac_ne)  == sum(pg[g] for g in bus_gens) - sum(ps[s] for s in bus_storage) - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts)*v^2)
    if _IM.report_duals(pm)
        for i in is
            _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr
            _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = NaN
        end
    end
end

function constraint_power_balance_dc_dcne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    bus_arcs_dcgrid = PowerModels.ref(pm, nw, :bus_arcs_dcgrid, i)
    if haskey(PowerModels.ref(pm, nw, :bus_arcs_dcgrid_ne), i)
        bus_arcs_dcgrid_ne = PowerModels.ref(pm, nw, :bus_arcs_dcgrid_ne, i)
    else
        bus_arcs_dcgrid_ne = []
    end
    bus_convs_dc = PowerModels.ref(pm, nw, :bus_convs_dc, i)
    bus_convs_dc_ne = PowerModels.ref(pm, nw, :bus_convs_dc_ne, i)
    pd = PowerModels.ref(pm, nw, :busdc, i)["Pdc"]
    constraint_power_balance_dc_dcne(pm, nw, i, bus_arcs_dcgrid, bus_arcs_dcgrid_ne, bus_convs_dc, bus_convs_dc_ne, pd)
end

function constraint_power_balance_dc_dcne(pm::_PM.AbstractPowerModel, n::Int, i::Int, bus_arcs_dcgrid, bus_arcs_dcgrid_ne, bus_convs_dc, bus_convs_dc_ne, pd)
    p_dcgrid = _PM.var(pm, n, :p_dcgrid)
    p_dcgrid_ne = _PM.var(pm, n, :p_dcgrid_ne)
    pconv_dc = _PM.var(pm, n, :pconv_dc)
    pconv_dc_ne = _PM.var(pm, n, :pconv_dc_ne)

    cstr=JuMP.@constraint(pm.model, sum(p_dcgrid[a] for a in bus_arcs_dcgrid) + sum(p_dcgrid_ne[a] for a in bus_arcs_dcgrid_ne) + sum(pconv_dc[c] for c in bus_convs_dc) + sum(pconv_dc_ne[c] for c in bus_convs_dc_ne)  == (-pd))
end

function constraint_power_balance_dcne_dcne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    bus_i = PowerModels.ref(pm, nw, :busdc_ne, i)["busdc_i"]
    if haskey(PowerModels.ref(pm, nw, :bus_arcs_dcgrid_ne), bus_i)
        bus_arcs_dcgrid_ne = PowerModels.ref(pm, nw, :bus_arcs_dcgrid_ne, bus_i)
    else
        bus_arcs_dcgrid_ne = []
    end
    bus_ne_convs_dc_ne = PowerModels.ref(pm, nw, :bus_ne_convs_dc_ne, bus_i)
    pd_ne = PowerModels.ref(pm, nw, :busdc_ne, i)["Pdc"]
    constraint_power_balance_dcne_dcne(pm, nw, i, bus_arcs_dcgrid_ne, bus_ne_convs_dc_ne, pd_ne)
end

function constraint_power_balance_dcne_dcne(pm::_PM.AbstractPowerModel, n::Int, i::Int, bus_arcs_dcgrid_ne, bus_ne_convs_dc_ne, pd_ne)
    p_dcgrid_ne = _PM.var(pm, n, :p_dcgrid_ne)
    pconv_dc_ne = _PM.var(pm, n, :pconv_dc_ne)
    xb = _PM.var(pm, n, :branchdc_ne)
    xc = _PM.var(pm, n, :conv_ne)
    cstr=JuMP.@constraint(pm.model, sum(p_dcgrid_ne[a] for a in bus_arcs_dcgrid_ne) + sum(pconv_dc_ne[c] for c in bus_ne_convs_dc_ne)  == (-pd_ne))
end

############################ Fixing branch variables for MIP vs Convex approx ###########################
############################# HVDC
function fix_dc_lines2zero(pm)
    for n in _PM.nw_ids(pm)
        if haskey(_PM.ref(pm, n), :branchdc)
            branchdc = _PM.ref(pm, n, :branchdc)
            if !isempty(branchdc)
                for (i,br) in branchdc
                    brnch=_PM.var(pm, n, :branchdc, i)
                    JuMP.fix(brnch,0,force=true)
                end
            end
        end
    end
end


function fix_dc_ne_lines2zero(pm)
    for n in _PM.nw_ids(pm)
        if haskey(_PM.ref(pm, n), :branchdc_ne)
            branchdc_ne = _PM.ref(pm, n, :branchdc_ne)
            if !isempty(branchdc_ne)
                for (i,br) in branchdc_ne
                    brnch=_PM.var(pm, n, :branchdc_ne, i)
                    JuMP.fix(brnch,0,force=true)
                    #JuMP.unset_binary(brnch)
                    #println(JuMP.is_binary(brnch))
                end
            end
        end
    end
end

############################## HVAC
function fix_ac_lines2zero(pm)
    for n in _PM.nw_ids(pm)
        if haskey(_PM.ref(pm, n), :branch)
            branch = _PM.ref(pm, n, :branch)
            if !isempty(branch)
                for (i,br) in branch
                    brnch=_PM.var(pm, n, :branch, i)
                    JuMP.fix(brnch,0,force=true)
                end
            end
        end
    end
end

function fix_ac_ne_lines2zero(pm)
    for n in _PM.nw_ids(pm)
        if haskey(_PM.ref(pm, n), :branch_ne)
            branch_ne = _PM.ref(pm, n, :branch_ne)
            if !isempty(branch_ne)
                for (i,br) in branch_ne
                    brnch=_PM.var(pm, n, :branch_ne, i)
                    JuMP.fix(brnch,0,force=true)
                end
            end
        end
    end
end

########################### Ohms law for Market model, in Nodal same as PMACDC #######################
######################## HVDC #######################
function constraint_ohms_dc_branch_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    branch = PowerModels.ref(pm, nw, :branchdc_ne, i)
    f_bus = branch["fbusdc"]
    t_bus = branch["tbusdc"]
    rate_a = branch["rateA"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)
    p = PowerModels.ref(pm, nw, :dcpol)
    constraint_ohms_dc_branch_ne(pm, nw, f_bus, t_bus, f_idx, t_idx, branch["r"], p, rate_a)
end

function constraint_ohms_dc_branch_ne(pm::_PM.AbstractDCPModel, n::Int, f_bus, t_bus, f_idx, t_idx, r, p, rate_a)
    p_dc_fr_ne = _PM.var(pm, n, :p_dcgrid_ne, f_idx)
    p_dc_to_ne = _PM.var(pm, n, :p_dcgrid_ne, t_idx)
    cstr=JuMP.@constraint(pm.model, p_dc_fr_ne + p_dc_to_ne == 0)
end

function constraint_ohms_dc_branch(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    branch = _PM.ref(pm, nw, :branchdc, i)
    f_bus = branch["fbusdc"]
    t_bus = branch["tbusdc"]
    p_rateA=_PM.var(pm, nw, :p_rateA, i)
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    p = _PM.ref(pm, nw, :dcpol)
    constraint_ohms_dc_branch(pm, nw, f_bus, t_bus, f_idx, t_idx, branch["r"], p, p_rateA)
end

function constraint_ohms_dc_branch(pm::_PM.AbstractDCPModel, n::Int,  f_bus, t_bus, f_idx, t_idx, r, p, p_rateA)
    p_dc_fr = _PM.var(pm, n, :p_dcgrid, f_idx)
    p_dc_to = _PM.var(pm, n, :p_dcgrid, t_idx)
    JuMP.@constraint(pm.model, p_dc_fr + p_dc_to == 0)
end

######################## HVAC #######################
function constraint_ohms_ac_branch(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    branch = _PM.ref(pm, nw, :branch, i)
    rate_a =_PM.var(pm, nw, :p_rateAC, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)
    constraint_ohms_ac_branch(pm, nw, f_idx, t_idx, f_bus, t_bus, rate_a)
end

function constraint_ohms_ac_branch(pm::_PM.AbstractDCPModel, n::Int, f_idx, t_idx, f_bus, t_bus, rate_a)
    p_fr  = _PM.var(pm, n,  :p, f_idx)
    p_to  = _PM.var(pm, n,  :p, t_idx)
    JuMP.@constraint(pm.model, p_fr + p_to == 0)
end

function constraint_ohms_ac_branch_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    branch = _PM.ref(pm, nw, :ne_branch, i)
    rate_a = branch["rate_a"]
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)
    constraint_ohms_ac_branch_ne(pm, nw, f_idx, t_idx, f_bus, t_bus, rate_a)
end

function constraint_ohms_ac_branch_ne(pm::_PM.AbstractDCPModel, n::Int, f_idx, t_idx, f_bus, t_bus, rate_a)
    p_fr  = _PM.var(pm, n,  :p_ne, f_idx)
    p_to  = _PM.var(pm, n,  :p_ne, t_idx)
    JuMP.@constraint(pm.model, p_fr + p_to == 0)
end


##################################### Max investment constraints
#Constraint on size of yearly investment possible
#main logic
function max_investment_per_year(pm::_PM.AbstractPowerModel)
    s1=pm.setting["scenarios_length"]
    y1=pm.setting["years_length"]
    h1=pm.setting["hours_length"]
    for (s, scenario) in pm.ref[:scenario]
        s_num=parse(Int64,s)
        cost=0.0
        ordered_scenes=sort(OrderedCollections.OrderedDict(scenario), by=x->parse(Int64,x))
        ks=collect(keys(ordered_scenes))
        strt=ordered_scenes[ks[1]]
        _sc=floor(Int64,(strt-1)/(y1*h1))
        _yr=ceil(Int64,(strt-_sc*(y1*h1))/(h1))
        for (sc, n) in ordered_scenes
            if (pm.setting["relax_problem"])
                cost=cost+calc_branchdc_cost_max_invest(pm, n)
                if (pm.setting["AC"]=="1")
                    cost=cost+calc_branch_cost_max_invest(pm, n);end
            else
                cost=cost+calc_branchdc_ne_cost_max_invest(pm, n)
                if (pm.setting["AC"]=="1")
                    cost=cost+calc_branch_ne_cost_max_invest(pm, n);
                end
            end
            cost=cost+calc_convdc_convexafy_cost_max_invest(pm, n)
            cost=cost+calc_storage_cost_cordoba_max_invest(pm, n)
            cost=cost+calc_wf_cost_max_invest(pm, n)
            if (n==strt+h1-1)
                JuMP.@constraint(pm.model,cost<=pm.setting["max_invest_per_year"][_yr])
                strt=strt+h1
                _yr=ceil(Int64,(strt-_sc*(y1*h1))/(h1))
                cost=0.0
            end
        end
    end
end

################## Convex variables
#max investment per year for wind farms
function calc_wf_cost_max_invest(pm::_PM.AbstractPowerModel, n::Int)

    function calc_single_wf_cost_npv(i, b_cost, nw)
        cost = b_cost * _PM.var(pm,nw,:wf_pacmax,i)
        return cost
    end

    sl=pm.setting["scenarios_length"]
    yl=pm.setting["years_length"]
    hl=pm.setting["hours_length"]
    _sc=floor(Int64,(n-1)/(yl*hl))
    _yr=ceil(Int64,(n-_sc*(yl*hl))/(hl))
    wfs=[]
    wfs_ns=[]
    cost = 0
    if (_yr==1)
        for nt=n:hl:n+(yl-_yr)*hl
            push!(wfs,_PM.ref(pm, nt, :gen));push!(wfs_ns,nt);end
        for (k,gs) in enumerate(wfs)
                cost = cost + sum(calc_single_wf_cost_npv(i,pm.setting["xd"]["gen"][string(i)]["invest"][wfs_ns[k]],n) for (i,g) in gs if issubset([i],first.(pm.setting["wfz"])))
            if (wfs_ns[k]+hl<=n+(yl-_yr)*hl)
                cost = cost - sum(calc_single_wf_cost_npv(i,pm.setting["xd"]["gen"][string(i)]["invest"][wfs_ns[k]+hl],n) for (i,g) in gs if issubset([i],first.(pm.setting["wfz"])))
        end;end
    else
        for nt=n:hl:n+(yl-_yr)*hl
            push!(wfs,_PM.ref(pm, nt, :gen));push!(wfs_ns,nt);end
        for (k,gs) in enumerate(wfs)
           cost = cost + sum(calc_single_wf_cost_npv(i,pm.setting["xd"]["gen"][string(i)]["invest"][wfs_ns[k]],n) for (i,g) in gs if issubset([i],first.(pm.setting["wfz"])))
            cost = cost - sum(calc_single_wf_cost_npv(i,pm.setting["xd"]["gen"][string(i)]["invest"][wfs_ns[k]],n-hl) for (i,g) in gs if issubset([i],first.(pm.setting["wfz"])))
            if (wfs_ns[k]+hl<=n+(yl-_yr)*hl)
                cost = cost - sum(calc_single_wf_cost_npv(i,pm.setting["xd"]["gen"][string(i)]["invest"][wfs_ns[k]+hl],n) for (i,g) in gs if issubset([i],first.(pm.setting["wfz"])))
                cost = cost + sum(calc_single_wf_cost_npv(i,pm.setting["xd"]["gen"][string(i)]["invest"][wfs_ns[k]+hl],n-hl) for (i,g) in gs if issubset([i],first.(pm.setting["wfz"])))
        end;end
    end
    return cost
end
#max investment per year for storage
function calc_storage_cost_cordoba_max_invest(pm::_PM.AbstractPowerModel, n::Int)

    function calc_single_storage_cost_npv(i, b_cost, nw)
        cost = b_cost * _PM.var(pm,nw,:e_absmax,i)
        return cost
    end

    sl=pm.setting["scenarios_length"]
    yl=pm.setting["years_length"]
    hl=pm.setting["hours_length"]
    _sc=floor(Int64,(n-1)/(yl*hl))
    _yr=ceil(Int64,(n-_sc*(yl*hl))/(hl))
    stores=[]
    stores_nt=[]
    cost = 0
    if (_yr==1)
        for nt=n:hl:n+(yl-_yr)*hl
            push!(stores,_PM.ref(pm, nt, :storage));push!(stores_nt,nt);end
        for (k,s) in enumerate(stores)
            cost = cost + sum(calc_single_storage_cost_npv(i,pm.setting["xd"]["storage"][string(i)]["cost"][stores_nt[k]],n) for (i,b) in s)
            if (stores_nt[k]+hl<=n+(yl-_yr)*hl)
                cost = cost - sum(calc_single_storage_cost_npv(i,pm.setting["xd"]["storage"][string(i)]["cost"][stores_nt[k]+hl],n) for (i,b) in s)
        end;end
    else
        for nt=n:hl:n+(yl-_yr)*hl
            push!(stores,_PM.ref(pm, nt, :storage));;push!(stores_nt,nt);end
        for (k,s) in enumerate(stores)
            cost = cost + sum(calc_single_storage_cost_npv(i,pm.setting["xd"]["storage"][string(i)]["cost"][stores_nt[k]],n) for (i,b) in s)
            cost = cost - sum(calc_single_storage_cost_npv(i,pm.setting["xd"]["storage"][string(i)]["cost"][stores_nt[k]],n-hl) for (i,b) in s)
            if (stores_nt[k]+hl<=n+(yl-_yr)*hl)
                cost = cost - sum(calc_single_storage_cost_npv(i,pm.setting["xd"]["storage"][string(i)]["cost"][stores_nt[k]+hl],n) for (i,b) in s)
            cost = cost + sum(calc_single_storage_cost_npv(i,pm.setting["xd"]["storage"][string(i)]["cost"][stores_nt[k]+hl],n-hl) for (i,b) in s)
        end;end
    end
    return cost
end

#max investment per year for converters
function calc_convdc_convexafy_cost_max_invest(pm::_PM.AbstractPowerModel, n::Int)

    function calc_single_convdc_cost_npv(i, b_cost, nw)
        cost = b_cost * _PM.var(pm,nw,:p_pacmax,i)
        return cost
    end

    sl=pm.setting["scenarios_length"]
    yl=pm.setting["years_length"]
    hl=pm.setting["hours_length"]
    _sc=floor(Int64,(n-1)/(yl*hl))
    _yr=ceil(Int64,(n-_sc*(yl*hl))/(hl))
    convdc=[]
    convdc_ns=[]
    cost = 0
    if (_yr==1)
        for nt=n:hl:n+(yl-_yr)*hl
            push!(convdc,_PM.ref(pm, nt, :convdc));push!(convdc_ns,nt)end
        for (k,c) in enumerate(convdc)
            cost = cost + sum(calc_single_convdc_cost_npv(i,pm.setting["xd"]["convdc"][string(i)]["cost"][convdc_ns[k]],n) for (i,b) in c)
            if (convdc_ns[k]+hl<=n+(yl-_yr)*hl)
                cost = cost - sum(calc_single_convdc_cost_npv(i,pm.setting["xd"]["convdc"][string(i)]["cost"][convdc_ns[k]+hl],n) for (i,b) in c)
        end;end
    else
        for nt=n:hl:n+(yl-_yr)*hl
            push!(convdc,_PM.ref(pm, nt, :convdc));push!(convdc_ns,nt);end
        for (k,c) in enumerate(convdc)
            cost = cost + sum(calc_single_convdc_cost_npv(i,pm.setting["xd"]["convdc"][string(i)]["cost"][convdc_ns[k]],n) for (i,b) in c)
            cost = cost - sum(calc_single_convdc_cost_npv(i,pm.setting["xd"]["convdc"][string(i)]["cost"][convdc_ns[k]],n-hl) for (i,b) in c)
            if (convdc_ns[k]+hl<=n+(yl-_yr)*hl)
                cost = cost - sum(calc_single_convdc_cost_npv(i,pm.setting["xd"]["convdc"][string(i)]["cost"][convdc_ns[k]+hl],n) for (i,b) in c)
                cost = cost + sum(calc_single_convdc_cost_npv(i,pm.setting["xd"]["convdc"][string(i)]["cost"][convdc_ns[k]+hl],n-hl) for (i,b) in c)            
        end;end
    end
    return cost
end

#HVDC branches
function calc_branchdc_cost_max_invest(pm::_PM.AbstractPowerModel, n::Int)

    function calc_single_branchdc_cost_npv(i, b_cost, nw)
        cost = b_cost * _PM.var(pm,nw,:p_rateA,i)
        return cost
    end

    sl=pm.setting["scenarios_length"]
    yl=pm.setting["years_length"]
    hl=pm.setting["hours_length"]
    _sc=floor(Int64,(n-1)/(yl*hl))
    _yr=ceil(Int64,(n-_sc*(yl*hl))/(hl))
    brs=[]
    brs_ns=[]
    cost = 0
    if (_yr==1)
        for nt=n:hl:n+(yl-_yr)*hl
            push!(brs,_PM.ref(pm, nt, :branchdc));push!(brs_ns,nt);end
        for (k,bs) in enumerate(brs)
            cost = cost + sum(calc_single_branchdc_cost_npv(i,pm.setting["xd"]["branchdc"][string(i)]["cost"][brs_ns[k]],n) for (i,b) in bs)
            if (brs_ns[k]+hl<=n+(yl-_yr)*hl)
            cost = cost - sum(calc_single_branchdc_cost_npv(i,pm.setting["xd"]["branchdc"][string(i)]["cost"][brs_ns[k]+hl],n) for (i,b) in bs)
        end;end
    else
        for nt=n:hl:n+(yl-_yr)*hl
            push!(brs,_PM.ref(pm, nt, :branchdc));push!(brs_ns,nt);end
        for (k,bs) in enumerate(brs)
            cost = cost + sum(calc_single_branchdc_cost_npv(i,pm.setting["xd"]["branchdc"][string(i)]["cost"][brs_ns[k]],n) for (i,b) in bs)
            cost = cost - sum(calc_single_branchdc_cost_npv(i,pm.setting["xd"]["branchdc"][string(i)]["cost"][brs_ns[k]],n-hl) for (i,b) in bs)
            if (brs_ns[k]+hl<=n+(yl-_yr)*hl)
            cost = cost - sum(calc_single_branchdc_cost_npv(i,pm.setting["xd"]["branchdc"][string(i)]["cost"][brs_ns[k]+hl],n) for (i,b) in bs)
            cost = cost + sum(calc_single_branchdc_cost_npv(i,pm.setting["xd"]["branchdc"][string(i)]["cost"][brs_ns[k]+hl],n-hl) for (i,b) in bs)
        end;end
    end
    return cost
end

# HVAC branches
function calc_branch_cost_max_invest(pm::_PM.AbstractPowerModel, n::Int)

    function calc_single_branch_cost_npv(i, b_cost, nw)
        cost = b_cost * _PM.var(pm,nw,:p_rateAC,i)
        return cost
    end

    sl=pm.setting["scenarios_length"]
    yl=pm.setting["years_length"]
    hl=pm.setting["hours_length"]
    _sc=floor(Int64,(n-1)/(yl*hl))
    _yr=ceil(Int64,(n-_sc*(yl*hl))/(hl))
    brs=[]
    brs_ns=[]
    cost = 0
    if (_yr==1)
        for nt=n:hl:n+(yl-_yr)*hl
            push!(brs,_PM.ref(pm, nt, :branch));push!(brs_ns,nt);end
        for (k,bs) in enumerate(brs)
            cost = cost + sum(calc_single_branch_cost_npv(i,pm.setting["xd"]["branch"][string(i)]["cost"][brs_ns[k]],n) for (i,b) in bs)
            if (brs_ns[k]+hl<=n+(yl-_yr)*hl)
                cost = cost - sum(calc_single_branch_cost_npv(i,pm.setting["xd"]["branch"][string(i)]["cost"][brs_ns[k]+hl],n) for (i,b) in bs)
        end;end
    else
        for nt=n:hl:n+(yl-_yr)*hl
            push!(brs,_PM.ref(pm, nt, :branch));push!(brs_ns,nt);end
        for (k,bs) in enumerate(brs)
            cost = cost + sum(calc_single_branch_cost_npv(i,pm.setting["xd"]["branch"][string(i)]["cost"][brs_ns[k]],n) for (i,b) in bs)
            cost = cost - sum(calc_single_branch_cost_npv(i,pm.setting["xd"]["branch"][string(i)]["cost"][brs_ns[k]],n-hl) for (i,b) in bs)
            if (brs_ns[k]+hl<=n+(yl-_yr)*hl)
                cost = cost - sum(calc_single_branch_cost_npv(i,pm.setting["xd"]["branch"][string(i)]["cost"][brs_ns[k]+hl],n) for (i,b) in bs)
            cost = cost + sum(calc_single_branch_cost_npv(i,pm.setting["xd"]["branch"][string(i)]["cost"][brs_ns[k]+hl],n-hl) for (i,b) in bs)
            end    
        end
    end
    return cost
end

##################### Binary variables
#HVDC cables
function calc_branch_ne_cost_max_invest(pm::_PM.AbstractPowerModel, n::Int)

    function calc_single_branch_ne_cost_npv(i, b_cost, nw)
        cost = b_cost * _PM.var(pm,nw,:branch_ne,i)
        return cost
    end

    sl=pm.setting["scenarios_length"]
    yl=pm.setting["years_length"]
    hl=pm.setting["hours_length"]
    _sc=floor(Int64,(n-1)/(yl*hl))
    _yr=ceil(Int64,(n-_sc*(yl*hl))/(hl))
    brs=[]
    brs_ns=[]
    cost = 0
    if (_yr==1)
        for nt=n:hl:n+yl*hl-1
            push!(brs,_PM.ref(pm, nt, :ne_branch));push!(brs_ns,nt)end
        for (k,bs) in enumerate(brs)
            if (length(bs)>0)
                #println(bs)
                cost = cost + sum(calc_single_branch_ne_cost_npv(i,pm.setting["xd"]["ne_branch"][string(i)]["construction_cost"][brs_ns[k]],n) for (i,b) in bs)
            end
        end
    else
        for nt=n:hl:n-hl+(yl-_yr+1)*hl
            push!(brs,_PM.ref(pm, nt, :ne_branch));push!(brs_ns,nt);end
        for (k,bs) in enumerate(brs)
            if (length(bs)>0)
                #println(bs)
                cost = cost + sum(calc_single_branch_ne_cost_npv(i,pm.setting["xd"]["ne_branch"][string(i)]["construction_cost"][brs_ns[k]],n) for (i,b) in bs)
                cost = cost - sum(calc_single_branch_ne_cost_npv(i,pm.setting["xd"]["ne_branch"][string(i)]["construction_cost"][brs_ns[k]],n-hl) for (i,b) in bs)
            end
        end
    end
    return cost
end

#HVAC Cables
function calc_branchdc_ne_cost_max_invest(pm::_PM.AbstractPowerModel, n::Int)

    function calc_single_branchdc_ne_cost_npv(i, b_cost, nw)
        cost = b_cost * _PM.var(pm,nw,:branchdc_ne,i)
        return cost
    end

    sl=pm.setting["scenarios_length"]
    yl=pm.setting["years_length"]
    hl=pm.setting["hours_length"]
    _sc=floor(Int64,(n-1)/(yl*hl))
    _yr=ceil(Int64,(n-_sc*(yl*hl))/(hl))
    brs=[]
    brs_ns=[]
    cost = 0
    if (_yr==1)
        for nt=n:hl:n+yl*hl-1
            push!(brs,_PM.ref(pm, nt, :branchdc_ne));push!(brs_ns,nt);end
        for (k,bs) in enumerate(brs)
            cost = cost + sum(calc_single_branchdc_ne_cost_npv(i,pm.setting["xd"]["branchdc_ne"][string(i)]["cost"][brs_ns[k]],n) for (i,b) in bs)
        end
    else
        for nt=n:hl:n-hl+(yl-_yr+1)*hl
            push!(brs,_PM.ref(pm, nt, :branchdc_ne));push!(brs_ns,nt);end
        for (k,bs) in enumerate(brs)
            cost = cost + sum(calc_single_branchdc_ne_cost_npv(i,pm.setting["xd"]["branchdc_ne"][string(i)]["cost"][brs_ns[k]],n) for (i,b) in bs)
            cost = cost - sum(calc_single_branchdc_ne_cost_npv(i,pm.setting["xd"]["branchdc_ne"][string(i)]["cost"][brs_ns[k]],n-hl) for (i,b) in bs)
        end
    end
    return cost
end


############################ Constraint on number of TLs per corridor ##############################
#HVDC lines
function collect_4_constraint_candidate_corridor_limit_dc(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    branch = _PM.ref(pm, nw, :branchdc_ne, i)
    ft_bus = [branch["fbusdc"],branch["tbusdc"]]
    z = _PM.var(pm, nw, :branchdc_ne)[i]
    return (sort!(ft_bus), z)
end

#HVAC lines
function collect_4_constraint_candidate_corridor_limit_ac(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    branch = _PM.ref(pm, nw, :ne_branch, i)
    ft_bus = [branch["f_bus"],branch["t_bus"]]
    z = _PM.var(pm, nw, :branch_ne)[i]
    return (sort!(ft_bus), z)
end

#corridor Constraint
function constraint_candidate_corridor_limit(pm::_PM.AbstractPowerModel, cs_in_cs; nw::Int=pm.cnw)
    corridors=Dict{String,Any}()
    ks=first.(cs_in_cs)
    unique!(ks)
    for k in ks
        push!(corridors, string(k[1])*string(k[2])=>[])
    end

    for c_in_c in cs_in_cs
        k=first(c_in_c)
        push!(corridors[string(k[1])*string(k[2])],last(c_in_c))
    end
    for (k,c) in corridors
        JuMP.@constraint(pm.model, sum(c) <= 1)
    end
end

################################### Step wise constraints ###############################
#generalized time based constraint on variables (can only expand capacity each year and only once) - for wfs see below
function constraint_t0t1(vss, pm)
    sl=pm.setting["scenarios_length"]
    yl=pm.setting["years_length"]
    hl=pm.setting["hours_length"]
    s=1
    y=1
    for (i,vs) in enumerate(vss)
        for (j,v) in enumerate(last(vs))
            if (mod(i,hl)!=1)
                JuMP.@constraint(pm.model, last(vss[i])[j] == last(vss[i-1])[j])
            end
            if (i+hl*yl<=length(vss))
                JuMP.@constraint(pm.model, last(vss[i])[j]  == last(vss[i+hl*yl])[j])
            end
            if (i==y*hl+(s-1)*yl*hl+1)
                y+=1
            end
            if (i==s*yl*hl+1)
                s+=1
                y=1
            end
            if (i+hl<=s*yl*hl && i+hl<=sl*yl*hl && y<yl)
                    JuMP.@constraint(pm.model, last(vss[i])[j]  <= last(vss[i+hl])[j])
            end
        end
    end
end

#time based constraint on wf variables (can only expand capacity each year and only once)
function constraint_t0t1_wfz(vss, pm)
    sl=pm.setting["scenarios_length"]
    yl=pm.setting["years_length"]
    hl=pm.setting["hours_length"]
    s=1
    y=1
    for (i,vs) in enumerate(vss)
        for (j,v) in enumerate(last(vs))
            if (mod(i,hl)!=1)
                JuMP.@constraint(pm.model, last(vss[i])[Int64(j+(-1+minimum(first.(pm.setting["wfz"]))))] == last(vss[i-1])[Int64(j+(-1+minimum(first.(pm.setting["wfz"]))))])
            end
            if (i+hl*yl<=length(vss))
                JuMP.@constraint(pm.model, last(vss[i])[Int64(j+(-1+minimum(first.(pm.setting["wfz"]))))] == last(vss[i+hl*yl])[Int64(j+(-1+minimum(first.(pm.setting["wfz"]))))])
            end
            if (i==y*hl+(s-1)*yl*hl+1)
                y+=1
            end
            if (i==s*yl*hl+1)
                s+=1
                y=1
            end
            if (i+hl<=s*yl*hl && i+hl<=sl*yl*hl && y<yl)
                    JuMP.@constraint(pm.model, last(vss[i])[Int64(j+(-1+minimum(first.(pm.setting["wfz"]))))]  <= last(vss[i+hl])[Int64(j+(-1+minimum(first.(pm.setting["wfz"]))))])
            end
        end
    end
end
