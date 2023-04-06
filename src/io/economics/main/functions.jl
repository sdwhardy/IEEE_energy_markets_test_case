
function AC_cbl(mva,km,kV::Int64=220)
    cbl=cable();cbl.mva=mva;cbl.wnd="Norther"
    cable_options=get_220kV_cables()
    if (kV==66)
        cable_options=get_66kV_cables()
    elseif (kV==132)
        cable_options=get_132kV_cables()
    end
    ac_cbl=optimal_ac_cable(cbl,cable_options,km,get_Cost_Data())
    if (ac_cbl.num<1); ac_cbl.costs.cpx_p=1e12; end
    return ac_cbl
end


function DC_cbl(mva,km)
    cbl=cable();cbl.mva=mva;cbl.wnd="Norther"
    dc_cbl=optimal_hvdc_cable(cbl,get_500kV_cables(),km,get_Cost_Data())
    #
    return dc_cbl
end

function AC_cbl_collection(mva_cable,mav_wfs,km,wind_profile,kV::Int64=220)
    cbl=cable();cbl.mva=mva_cable;cbl.wnd="Norther"
    cable_options=get_220kV_cables()
    if (kV==66)
        cable_options=get_66kV_cables()
    elseif (kV==132)
        cable_options=get_132kV_cables()
    end
    ac_cbl=optimal_ac_cable(cbl,cable_options,km,get_Cost_Data())
    if (ac_cbl.num<1); ac_cbl.costs.cpx_p=1e12; end
    ac_cbl.costs.rlc=cost_rlc((ac_cbl.elec.ohm*km)/ac_cbl.num,mav_wfs,wind_profile,kV)

    #ac_cbl.costs.eens=
    ac_cbl.costs.ttl=ac_cbl.costs.ttl+ac_cbl.costs.rlc#1.9674329
    ac_cbl.costs.grand_ttl=ac_cbl.costs.ttl
    return ac_cbl
end


function DC_cbl_collection(mva,km)
    cbl=cable();cbl.mva=mva;cbl.wnd="Norther"
    dc_cbl=optimal_hvdc_cable(cbl,get_500kV_cables(),km,get_Cost_Data())
    #
    return dc_cbl
end


