function optimal_hvdc_cable(cbl0,cbl_data,km,ks)
    cbl=cable()
    cbl.costs.ttl=Inf
    cbl.elec.volt=cbl_data[1][1]
    cbl.length=km
    cbl.mva=cbl0.mva
    cbl0.costs.ttl=Inf

    for _cd in cbl_data
        num=2
        capacity=(_cd[1]*_cd[5])*10^-3
        while (cbl0.mva>num*capacity)
            num=num+2
        end
        fillOut_cable_struct_dc(cbl0,_cd,km,num)
        cbl0=cost_hvdc_cable(cbl0,ks)
        if (cbl0.costs.ttl<cbl.costs.ttl)
            cbl=deepcopy(cbl0)
        end
    end
    return cbl
end


function cost_hvdc_cable(cbl,ks)
    #cost of losses in the hvdc cable
    cbl.costs.rlc=0#cost_rlc_hvdc(cbl,ks)
    #capex of cable
    cbl.costs.cpx_p,cbl.costs.cpx_i=capex_cable(cbl,ks.ldc)
    #cost of corrective maintenance
    cbl.costs.cm=cost_cm(cbl.costs.cpx_p,ks.opx_c)
    #cost of expected energy not served
    cbl.costs.eens=0#cost_eens(cbl,ks)
    #totals the cable cost
    cbl.costs.ttl=cost_cbl_sum(cbl)
    cbl.costs.grand_ttl=cbl.costs.ttl
    return cbl
end