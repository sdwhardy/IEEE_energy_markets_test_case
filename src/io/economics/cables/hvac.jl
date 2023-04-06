
function optimal_ac_cable(cbl0,cbl_data,km,ks)
    cbl=cable()
    cbl.costs.ttl=Inf
    cbl.elec.volt=cbl_data[1][1]
    cbl.length=km
    cbl.mva=min_mva=deepcopy(cbl0.mva)
    cbl0.costs.ttl=Inf
    
    for cd in cbl_data
        num=1
        cap_at_km=get_newQ_Capacity(cbl0.elec.freq,km,cd[1],cd[4]*10^-9,cd[5])
        max_in_parallel=12
        if (cap_at_km/cbl0.mva>1/max_in_parallel)
            while ((min_mva>num*cap_at_km) && num<max_in_parallel)
                num=deepcopy(num+1)
            end
            cbl0=fillOut_cable_struct_ac(cbl0,cd,km,num)
            cbl0=cost_hvac_cable(cbl0,ks)
        end
        if (cbl0.costs.ttl<cbl.costs.ttl)
            cbl=deepcopy(cbl0)
        end
    end
    return cbl
end

function get_newQ_Capacity(f,l,v,q,a)
#Calculates the square of new hvac cable capacity after 50-50 compensation at distance km.
    mva=(sqrt(3)*v*10^3*a/10^6)^2-((0.5*((v*10^3)^2*2*pi*f*l*q))/10^6)^2
#takes square root if negative returns zero if negative
    if mva>=0
        mva=sqrt(mva)
    else
        mva=0.0
    end
    return mva
end


#calculates the cost of a given hvac cost
#**
function cost_hvac_cable(cbl,ks)
    #capex of cable
    cbl.costs.cpx_p,cbl.costs.cpx_i=capex_cable(cbl,ks.lac)
    #cost of corrective maintenance
    cbl.costs.cm=cost_cm(cbl.costs.cpx_p,ks.opx_c)
    #totals the cable cost
    cbl.costs.ttl=cost_cbl_sum(cbl)
    cbl.costs.grand_ttl=cbl.costs.ttl
    return cbl
end
