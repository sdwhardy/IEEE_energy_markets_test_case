#CAPEX of cables
#**
function capex_cable(cbl,lay)
    cpx_p=cbl.length*cbl.num*cbl.costs.perkm_cpx#1.775 is installation cost per core per km ref: North Sea Grid Final Report Annex
    k=0.985^(cbl.num)
    cpx_i=cbl.length*cbl.num*lay*k#1.775=DC, 1.905=HVAC, 1.69=MVAC
    return cpx_p,cpx_i
end

#corrective maintenance of all equipment
#North Sea Grid OPEX values used
#**
function cost_cm(cpx,k)
    cm=cpx*k*npv_years()
    return cm
end

#**
function cost_rlc(r,mav_wfs,wind_profile,kV)
    yearly_losses=0
    for time_step in mav_wfs.*wind_profile
        amps=time_step/(sqrt(3)*kV)*1000
        time_step_losses=((amps)^2*r*get_Cost_Data().E_op)/1000000
        yearly_losses=yearly_losses+time_step_losses
    end
    yearly_losses=yearly_losses*npv_years()
    return yearly_losses/1000000
end

#sums all cable costs and returns the total**
#**
function cost_cbl_sum(cbl)
    ttl=cbl.costs.rlc+cbl.costs.cpx_i+cbl.costs.cpx_p+cbl.costs.cm+cbl.costs.qc+cbl.costs.eens+cbl.costs.sg
    if (ttl==NaN)
        ttl=Inf
    end
    cbl.costs.grand_ttl=ttl
    return ttl
end

############################### Net Present value ##############################
#Changes to a net present value
#**
function npv_years()
    #1+1/(1.04)^1+1/(1.04)^2+...+1/(1.04)^25
    return 16.62
end

#Changes to a net present value
#**
function npv_hours()
    #16.62*365.25*24=145690.91
    return 145691
end


#**
function get_cbl_failure_data(cbl)
    #cbl.relia.fr=(0.1114/100)*cbl.length#/yr/100km
    #cbl.relia.mttr=1.971#months
    cbl.relia.fr=(0.1/100)*cbl.length#/yr/100km
    cbl.relia.mttr=2#months
    cbl.relia.mc=0.56#No longer used
    return cbl
end


#Fills in the physical data of a cable into the cable structure
#common data between ac and dc cables - note in dc cables capacitive and inductive reactance is not appliccable
#**
function fillOut_cable_struct(cbl,cbl_data,km,num)
    cbl.elec.volt=cbl_data[1]
    cbl.size=cbl_data[2]
    cbl.elec.ohm=cbl_data[3]*10^-3
    cbl.elec.farrad=cbl_data[4]*10^-9
    cbl.elec.amp=cbl_data[5]
    cbl.costs.perkm_cpx=cbl_data[6]*10^-3
    cbl.length=km
    cbl.elec.henry=cbl_data[7]*10^-3
    cbl.elec.xl=2*pi*cbl.elec.freq*cbl.elec.henry#cable inductive reactance
    cbl.elec.yc=2*pi*cbl.elec.freq*cbl.elec.farrad#cable capacitive reactance
    cbl.num=num
    cbl=get_cbl_failure_data(cbl)#Set failure data
    return cbl
end

#Fills in the physical data of an ac cable into the cable structure **
#**
function fillOut_cable_struct_ac(cbl,cbl_data,km,num)
    cbl=fillOut_cable_struct(cbl,cbl_data,km,num)#common data between ac and dc cables
    cbl.elec.mva=get_newQ_Capacity(cbl.elec.freq,km,cbl.elec.volt,cbl.elec.farrad,cbl.elec.amp)
    return cbl
end

#Fills in the physical data of an hvdc cable into the cable structure **
#**
function fillOut_cable_struct_dc(cbl,cbl_data,km,num)
    cbl=fillOut_cable_struct(cbl,cbl_data,km,num)#common data between ac and dc cables
    cbl.elec.mva=cbl.elec.volt*cbl.elec.amp*10^-3#dc does not change with distance
    return cbl
end