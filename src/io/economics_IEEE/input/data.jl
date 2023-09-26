
############################ Reads Data from Excel ########################
################################################################################
#**
function get_Cost_Data()
    ks=cost_ks()
    ks.ldc=0.5175# changed from 1.775 on 8/12/21 to reflect cost in ENTSO-e
    ks.lac=0.5175# changed from 0.32 on 3/12/21 to reflect cost in ENTSO-e
    ks.opx_c=0.025#OPEX percent
    ks.E_op=100.0#Euro/MWh (used in losses)
    return ks
end

#ABB XLPE Submarine Cable Systems Attachment to XLPE Land Cable Systems not subsea - User´s Guide Table:49
#500: 0.14microF/km 0.43mH/km
#630: 0.16microF/km 0.41mH/km
#800: 0.17microF/km 0.40mH/km
#1000: 0.19microF/km 0.38mH/km
#Capacity: table 34
#400: 590
#500: 655
#630: 715
#800: 775
#1000: 825
#resistances:
#500: 0.0490ohms/km
#630: 0.0391ohms/km
#800: 0.0323ohms/km
#1000: 0.0273ohms/km
#costs: Centre for Sustainable Electricity and Distributed Generation
#500: 515*1.16(gbp/euro)
#630: 550
#800: 675
#1000: 700
#***Data for 1600 is taken from FEM simulation while cost is linear interpolation
function get_220kV_cables()#[kv, mm, mOhms/km, picoF/km, Amps, kE/km, mH/km]
    cbls220=[[220.0, 400.0, 40.1, 122.0, 590.0, 496.48, 0.457], [220.0, 500.0, 49.0, 140.0, 655.0, 597.4, 0.43], [220.0, 630.0, 39.1, 160.0, 715.0, 638.0, 0.41], [220.0, 800.0, 32.3, 170.0, 775.0, 783.0, 0.4], [220.0, 1000.0, 27.3, 190.0, 825.0, 812.0, 0.38], [220.0, 1600.0, 17.9, 190.0, 950.0, 1162.0, 0.35]]
    return cbls220
end

#**#[kv, mm, mOhms/km, picoF/km, Amps, kE/km, mH/km]
function get_500kV_cables()
    cbls500=[[500, 500, 46.7, 0.7, 1072, 510, 0.7], [500, 630, 36.1, 0.7, 1246, 516.5, 0.7], [500, 800, 28.2, 0.7, 1438, 525, 0.7], [500, 1000, 22.4, 0.7, 1644, 535, 0.7], [500, 1200, 19.3, 0.7, 1791, 545, 0.7], [500, 1400, 16.4, 0.7, 1962, 555, 0.7], [500, 1500, 15.4, 0.7, 2042.5, 560, 0.7], [500, 1600, 14.4, 0.7, 2123, 565, 0.7], [500, 1800, 12.9, 0.7, 2265, 575, 0.7], [500, 2000, 11.5, 0.7, 2407, 604, 0.7], [500, 2200, 10.3, 0.7, 2540, 633, 0.7], [500, 2400, 9.6, 0.7, 2678, 662, 0.7], [500, 2500, 9.2, 0.7, 2746, 719, 0.7], [500, 2600, 8.7, 0.7, 2814, 776, 0.7], [500, 2800, 7.8, 0.7, 2937, 890, 0.7], [500, 3000, 6.9, 0.7, 3066, 1004, 0.7]]
    return cbls500
end

#NOTE 66 and 132 kV cables are guess afrom interpolations or sizes in:
#https://www.sab-cable.com/cables-wires-harnessing-temperature-measurement/technical-data/cables-and-wires/american-cable-stranding.html
function get_66kV_cables()
    #keys=["mOhms/km", "nanoF/km", "Amps", "kE/km", "mH/km"]
    cbls66=[[66,240,70,220,480,251.72,0.38],[66,300,50,240,530,274.92,0.37],[66,400,40,260,590,306.24,0.35],[66,500,30,290,655,345.68,0.34],[66,630,27.1,320,715,387.44,0.33],[66,800,22.5,350,775,436.16,0.32],[66,1000,19.8,380,825,482.56,0.31], [66.0, 1200.0, 15.1, 304.0, 1081, 615, 0.55], [66.0, 1600.0, 11.3, 338.0, 1227, 670, 0.52]]

    return cbls66
end

#Entso-E
#MVA Voltage Cost 
#200 132 kV 518 – 805 
function get_132kV_cables()
    #keys=["mOhms/km", "nanoF/km", "Amps", "kE/km", "mH/km"]
    cbls132=[[132,185,90,200,420,258.777018181818,0.4],[132,240,70,220,480,286.503127272727,0.38],[132,300,50,240,530,312.908945454545,0.37],[132,400,40,260,590,348.5568,0.35],[132,500,30,290,655,393.446690909091,0.34],[132,630,27.1,320,715,440.977163636364,0.33],[132,800,22.5,350,775,496.429381818182,0.32],[132,1000,19.8,380,825,549.241018181818,0.31], [132.0, 1200.0, 15.1, 304.0, 1081, 680, 0.55], [132.0, 1600.0, 11.3, 338.0, 1227, 740, 0.52]]

    return cbls132
end

#checks
#Entso-E
#MVA Voltage Cost 
#300 220 kV 575 – 863  for 100km (3core): 80.5-184.05 (mean 132.275) result: capex 157.255 (includes 12.465 in reactive compensation)
#Catapult
#1GW 60km 227 (assuming 1/3 of listed cable installation costs) Result: capex 235.882 (including compensation)


#**
#NOTE 1.5 in price accounts for 3 seperate laying of cables.
function get_400kV_cables()
    #keys=["mOhms/km", "nanoF/km", "Amps", "kE/km", "mH/km"]
     cbls400=[[400.0, 630.0, 28.3, 119.0, 594.0, 1.5*916.4, 0.46], [400.0, 800.0, 22.1, 134.0, 636.0, 1.5*997.6, 0.44], [400.0, 1000.0, 17.6, 150.0, 671.0, 1.5*1154.2, 0.41], [400.0, 1600.0, 15.6, 188.0, 779.0, 1.5*1624.0, 0.52], [400.0, 2000.0, 12.9, 209.0, 840.0, 1.5*1780.6, 0.50], [400.0, 2500.0, 10.9, 226.0, 893.0, 1.5*2000, 0.47]]
    return cbls400
end


###########################################################
######################### cables ##########################
###########################################################

#entso-e
#materials
#150/320kV not checked yet
#Cross-sectional Euro/m
#Area (mm2) 150 kV 320 kV 
#1200 230 – 460 345 – 518 
#1500 288 – 460 345 – 518 
#1800 345 – 518 345 – 575 
#2000 345 – 575 403 – 660 
#installation: 230 – 977.5Euros/route-metre
#**
function get_150kV_cables()
    keys=["mOhms/km", "nanoF/km", "Amps", "kE/km", "mH/km"]
    cbls150=Dict()
    for c in [[150.0, 1000.0, 22.4, 0.7, 1644.0, 179.8, 0.7], [150.0, 1200.0, 19.2, 0.7, 1791.0, 208.8, 0.7], [150.0, 1400.0, 16.5, 0.7, 1962.0, 234.9, 0.7], [150.0, 1600.0, 14.4, 0.7, 2123.0, 261.0, 0.7], [150.0, 2000.0, 11.5, 0.7, 2407.0, 290.0, 0.7]]
        push!(cbls150,string(c[2])=>Dict(zip(keys,c[3:end])))
    end
    return cbls150
end

#**
function get_300kV_cables()
    keys=["mOhms/km", "nanoF/km", "Amps", "kE/km", "mH/km"]
    cbls300=Dict()
    for c in [[300.0, 1000.0, 22.4, 0.7, 1644.0, 263.9, 0.7], [300.0, 1200.0, 19.2, 0.7, 1791.0, 295.8, 0.7], [300.0, 1400.0, 16.5, 0.7, 1962.0, 333.5, 0.7], [300.0, 1600.0, 14.4, 0.7, 2123.0, 371.2, 0.7], [300.0, 2000.0, 11.5, 0.7, 2407.0, 411.8, 0.7]]
        push!(cbls300,string(c[2])=>Dict(zip(keys,c[3:end])))
    end
    return cbls300
end
