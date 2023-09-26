###################################################################
############## Structures Common to All equipment #################
###################################################################
#an object that contains all cost factors used in the calculations
mutable struct cost_ks
    FC_ac::Float32
    FC_dc::Float32
    dc::Float32
    f_ct::Float32
    p_ct::Float32
    c_ct::Float32
    Qc_oss::Float32
    Qc_pcc::Float32
    life::Float32
    T_op::Float32#lifetime considered default sse at 25 years
    E_op::Float32#Euro/MWh default set 100 Euro/MWh
    cf::Float32
    FC_bld::Float32
    p2e::Float32
    ldc::Float32
    lac::Float32
    lmac::Float32
    npv::Float32
    opx_c::Float32
    opx_pl::Float32
    opx_x::Float32
    opx_co::Float32
    opx_cp::Float32
    conv_c::Float32#incremental value of converter cost
    conv_d::Float32#fixed value of converter cost
    pac_e::Float32#incremental value of ac platform cost
    pac_f::Float32#fixed value of ac platform cost
    pdc_g::Float32#incremental value of dc platform cost
    pdc_h::Float32#fixed value of dc platform cost
 end
 cost_ks()=cost_ks(0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0)
 
 #xy co-ordinate struct
#May move but an element of both transformer and cables
mutable struct xy
    x::Float64
    y::Float64
end
xy()=xy(69.69,69.69)

#gps struct
#May move but an element of both transformer and cables
mutable struct gps
    lat::Float64
    lng::Float64
end
gps()=gps(69.69,69.69)

 #May move but an element of both transformer and cables
mutable struct node
    gps::gps
    xy::xy
    num::Int32
end
node()=node(gps(),xy(),69)

 #reliability structure - same for all equipment
 mutable struct reliability
    fr::Float32#failure rate
    mttr::Float32#mean time to repair
    mc::Float32#mean cost of repair
 end
 reliability()=reliability(69.69,69.69,69.69)

 #electrical properties of a cable
 mutable struct elec_cbl
    mva::Float32#per core capacity
    amp::Float32
    volt::Float32
    ohm::Float32
    farrad::Float32
    henry::Float32
    yc::Float32
    xl::Float32
    freq::Float32
 end
 elec_cbl()=elec_cbl(69.69,69.69,69.69,69.69,69.69,69.69,69.69,69.69,50)

 
#the structure of costs for a cable
mutable struct costs_cbl
    perkm_cpx::Float32#MEuros per km-procurement capex only
    pf3d::Float32#MEuros per km-procurement capex only
    perkm_ttl::Float32#MEuros per km-ttl cost
    qc::Float32#MEuros compensation on OSS
    sg::Float32#MEuros switch gear on OSS
    cpx_p::Float32#MEuros procurement capex total
    cpx_i::Float32#MEuros installation capex total
    rlc::Float32#MEuros losses in cable total
    cm::Float32#MEuros cost of corrective maintenance over lifetime
    eens::Float32#MEuros cost of eens over lifetime
    ttl::Float32#MEuros total lifetime cost
    grand_ttl::Float32#includes platform and double cable if mid point compensation
 end
 costs_cbl()=costs_cbl(0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0)
  #the structure of costs for an OSS platform
  mutable struct costs_plat
    cpx::Float32#MEuros procurement and installation
    cm::Float32
    ttl::Float32
 end
 costs_plat()=costs_plat(0.0,0.0,0.0)

 #the structure for a platform
mutable struct platform
    acdc::String#system mva
    kv::Float32#system mva
    mva::Float32#system mva
    depth::Float32#water depth
    costs::costs_plat
    wnd::String
 end
 platform()=platform("acdc",0.0,0.0,0.0,costs_plat(),"")

#the structure used for a cable
mutable struct cable
    mva::Float32#system requirement
    length::Float32
    path::Array{node}#nodes along path in direction of upstream(nth owpp) to downstream(pcc)
    size::Float32#cross setion of core
    num::Float32#number of parallel conductors
    relia::reliability
    elec::elec_cbl
    costs::costs_cbl
    wnd::String
    reactors::Array{Int32}
    plat::platform
    mpc_ac::Bool
    mx_rng::Float32
 end
 cable()=cable(0.0,0.0,node[],0.0,0.0,reliability(),elec_cbl(),costs_cbl(),"",Int32[],platform(),false,0.0)


 #Contains all cable data sourced from www.abb.com/cables
mutable struct cbls_data
    cbls33kV::Array{Array{Float32, 1}, 1}
    cbls66kV::Array{Array{Float32, 1}, 1}
    cbls132kV::Array{Array{Float32, 1}, 1}
    cbls220kV::Array{Array{Float32, 1}, 1}
    cbls400kV::Array{Array{Float32, 1}, 1}
    cbls150kV::Array{Array{Float32, 1}, 1}
    cbls300kV::Array{Array{Float32, 1}, 1}
 end
 cbls_data()=cbls_data(Array{Array{Float32, 1}, 1}(),Array{Array{Float32, 1}, 1}(),Array{Array{Float32, 1}, 1}(),Array{Array{Float32, 1}, 1}(),Array{Array{Float32, 1}, 1}(),Array{Array{Float32, 1}, 1}(),Array{Array{Float32, 1}, 1}())
 