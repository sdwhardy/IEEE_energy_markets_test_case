############################ figures ##################################
############### post simulation 
function post_map_Of_Connections_ACDCNTC(results)
    number_keys=parse.(Int64,keys(results["result_mip"]["solution"]["nw"]))
    t0=results["result_mip"]["solution"]["nw"][string(minimum(number_keys))]
    t1=results["result_mip"]["solution"]["nw"][string(minimum(number_keys)+results["s"]["hours_length"])]
    t2=results["result_mip"]["solution"]["nw"][string(maximum(number_keys))]
    data=results["data"]
    nodes = results["s"]["nodes"]
    cvs=data["convdc"]
    _map_of_connections_ACDCNTC0=DataFrames.DataFrame("from"=>[],"to"=>[],"lat_fr"=>[],"long_fr"=>[],"lat_to"=>[],"long_to"=>[],"mva"=>[],"type"=>[])
    _map_of_connections_ACDCNTC1=DataFrames.DataFrame("from"=>[],"to"=>[],"lat_fr"=>[],"long_fr"=>[],"lat_to"=>[],"long_to"=>[],"mva"=>[],"type"=>[])
    _map_of_connections_ACDCNTC2=DataFrames.DataFrame("from"=>[],"to"=>[],"lat_fr"=>[],"long_fr"=>[],"lat_to"=>[],"long_to"=>[],"mva"=>[],"type"=>[])
    for (t,t_sol) in enumerate([t0,t1,t2])   
        for (key_sol,br_sol) in t_sol["branch"] 
            if (br_sol["p_rateAC"]>0.1)
                br=data["branch"][key_sol]
                df_fr_ac=nodes[only(findall(==(br["f_bus"]), nodes.node)), :]
                df_to_ac=nodes[only(findall(==(br["t_bus"]), nodes.node)), :]
                mva=last(results["s"]["xd"]["branch"][key_sol]["rateA"])
                from=string(df_fr_ac.country)*string(df_fr_ac.type)
                to=string(df_to_ac.country)*string(df_to_ac.type)
                if (t==1)
                    push!(_map_of_connections_ACDCNTC0,[from,to,df_fr_ac.lat,df_fr_ac.long,df_to_ac.lat,df_to_ac.long,mva,"AC"])
                elseif (t==2)
                    push!(_map_of_connections_ACDCNTC1,[from,to,df_fr_ac.lat,df_fr_ac.long,df_to_ac.lat,df_to_ac.long,mva,"AC"])
                else
                    push!(_map_of_connections_ACDCNTC2,[from,to,df_fr_ac.lat,df_fr_ac.long,df_to_ac.lat,df_to_ac.long,mva,"AC"])
                end
            end
        end
        for (key_sol,br_sol) in t_sol["branchdc"]
            if (br_sol["p_rateA"]>0.1)
                br=data["branchdc"][key_sol]
                df_fr_dc=DataFrames.DataFrame()
                df_to_dc=DataFrames.DataFrame()
                for (key_cv,cv) in cvs; 
                    if (br["fbusdc"]==cv["busdc_i"]==cv["busac_i"]);
                        df_fr_dc=nodes[only(findall(==(cv["busac_i"]), nodes.node)), :];
                    elseif (br["tbusdc"]==cv["busdc_i"]==cv["busac_i"]);
                        df_to_dc=nodes[only(findall(==(cv["busac_i"]), nodes.node)), :]; 
                    end
                end
                
                if (!(isempty(df_fr_dc)) && !(isempty(df_to_dc)))
                    mva=last(results["s"]["xd"]["branchdc"][key_sol]["rateA"])
                    from=string(df_fr_dc.country)*string(df_fr_dc.type)
                    to=string(df_to_dc.country)*string(df_to_dc.type)
                    if (t==1)
                        push!(_map_of_connections_ACDCNTC0,[from,to,df_fr_dc.lat,df_fr_dc.long,df_to_dc.lat,df_to_dc.long,mva,"DC"])
                    elseif (t==2)
                        push!(_map_of_connections_ACDCNTC1,[from,to,df_fr_dc.lat,df_fr_dc.long,df_to_dc.lat,df_to_dc.long,mva,"DC"])
                    else
                        push!(_map_of_connections_ACDCNTC2,[from,to,df_fr_dc.lat,df_fr_dc.long,df_to_dc.lat,df_to_dc.long,mva,"DC"])
                    end
                end
            end
        end
    end
    _map_of_connections_ACDCNTC2=DataFrames.antijoin(_map_of_connections_ACDCNTC2, _map_of_connections_ACDCNTC1; on=[:from, :to, :mva, :type], makeunique = false, validate = (false, false))
    _map_of_connections_ACDCNTC1=DataFrames.antijoin(_map_of_connections_ACDCNTC1, _map_of_connections_ACDCNTC0; on=[:from, :to, :mva, :type], makeunique = false, validate = (false, false))
    #_map_of_connections_ACDCNTC2=DataFrames.antijoin(_map_of_connections_ACDCNTC2, _map_of_connections_ACDCNTC1; on=[:from, :to], makeunique = false, validate = (false, false))
    #_map_of_connections_ACDCNTC1=DataFrames.antijoin(_map_of_connections_ACDCNTC1, _map_of_connections_ACDCNTC0; on=[:from, :to], makeunique = false, validate = (false, false))
    _map_of_connections=Dict("0"=>_map_of_connections_ACDCNTC0,"1"=>_map_of_connections_ACDCNTC1,"2"=>_map_of_connections_ACDCNTC2)
    return _map_of_connections
end

#############################################
################# AC grid as NTC in solution - depricated but still needed for old solutions
function post_map_Of_Connections_ACDCNTC_ACgrid(results)
    number_keys=parse.(Int64,keys(results["result_mip"]["solution"]["nw"]))
    t0=results["result_mip"]["solution"]["nw"][string(minimum(number_keys))]
    t1=results["result_mip"]["solution"]["nw"][string(minimum(number_keys)+results["s"]["hours_length"])]
    t2=results["result_mip"]["solution"]["nw"][string(maximum(number_keys))]
    data=results["data"]
    nodes = results["s"]["nodes"]
    cvs=data["convdc"]
    _map_of_connections_ACDCNTC0=DataFrames.DataFrame("from"=>[],"to"=>[],"lat_fr"=>[],"long_fr"=>[],"lat_to"=>[],"long_to"=>[],"mva"=>[],"type"=>[])
    _map_of_connections_ACDCNTC1=DataFrames.DataFrame("from"=>[],"to"=>[],"lat_fr"=>[],"long_fr"=>[],"lat_to"=>[],"long_to"=>[],"mva"=>[],"type"=>[])
    _map_of_connections_ACDCNTC2=DataFrames.DataFrame("from"=>[],"to"=>[],"lat_fr"=>[],"long_fr"=>[],"lat_to"=>[],"long_to"=>[],"mva"=>[],"type"=>[])
    for (t,t_sol) in enumerate([t0,t1,t2])   
        for (key_sol,br_sol) in t_sol["branch"] 
            if (br_sol["p_rateAC"]>0.1)
                br=data["branch"][key_sol]
                df_fr_ac=nodes[only(findall(==(br["f_bus"]), nodes.node)), :]
                df_to_ac=nodes[only(findall(==(br["t_bus"]), nodes.node)), :]
                mva=last(results["s"]["xd"]["branch"][key_sol]["rateA"])
                from=string(df_fr_ac.country)*string(df_fr_ac.type)
                to=string(df_to_ac.country)*string(df_to_ac.type)
                if (t==1)
                    push!(_map_of_connections_ACDCNTC0,[from,to,df_fr_ac.lat,df_fr_ac.long,df_to_ac.lat,df_to_ac.long,mva,"AC"])
                elseif (t==2)
                    push!(_map_of_connections_ACDCNTC1,[from,to,df_fr_ac.lat,df_fr_ac.long,df_to_ac.lat,df_to_ac.long,mva,"AC"])
                else
                    push!(_map_of_connections_ACDCNTC2,[from,to,df_fr_ac.lat,df_fr_ac.long,df_to_ac.lat,df_to_ac.long,mva,"AC"])
                end
            end
        end
        for (key_sol,br_sol) in t_sol["branchdc"]
            if (br_sol["p_rateA"]>0.1)
                br=data["branchdc"][key_sol]
                df_fr_dc=DataFrames.DataFrame()
                df_to_dc=DataFrames.DataFrame()
                for (key_cv,cv) in cvs; 
                    if (br["fbusdc"]==cv["busdc_i"]==cv["busac_i"]);
                        df_fr_dc=nodes[only(findall(==(cv["busac_i"]), nodes.node)), :];
                    elseif (br["tbusdc"]==cv["busdc_i"]==cv["busac_i"]);
                        df_to_dc=nodes[only(findall(==(cv["busac_i"]), nodes.node)), :]; 
                    end
                end
                
                if (!(isempty(df_fr_dc)) && !(isempty(df_to_dc)))
                    mva=last(results["s"]["xd"]["branchdc"][key_sol]["rateA"])
                    from=string(df_fr_dc.country)*string(df_fr_dc.type)
                    to=string(df_to_dc.country)*string(df_to_dc.type)
                    if (t==1)
                        push!(_map_of_connections_ACDCNTC0,[from,to,df_fr_dc.lat,df_fr_dc.long,df_to_dc.lat,df_to_dc.long,mva,"DC"])
                    elseif (t==2)
                        push!(_map_of_connections_ACDCNTC1,[from,to,df_fr_dc.lat,df_fr_dc.long,df_to_dc.lat,df_to_dc.long,mva,"DC"])
                    else
                        push!(_map_of_connections_ACDCNTC2,[from,to,df_fr_dc.lat,df_fr_dc.long,df_to_dc.lat,df_to_dc.long,mva,"DC"])
                    end
                end
            end
        end
    end
    _map_of_connections_ACDCNTC2=DataFrames.antijoin(_map_of_connections_ACDCNTC2, _map_of_connections_ACDCNTC1; on=[:from, :to, :mva, :type], makeunique = false, validate = (false, false))
    _map_of_connections_ACDCNTC1=DataFrames.antijoin(_map_of_connections_ACDCNTC1, _map_of_connections_ACDCNTC0; on=[:from, :to, :mva, :type], makeunique = false, validate = (false, false))
    _map_of_connections_ACDCNTC0=filter(:type=>x->x!="AC",_map_of_connections_ACDCNTC0)
    _map_of_connections=Dict("0"=>_map_of_connections_ACDCNTC0,"1"=>_map_of_connections_ACDCNTC1,"2"=>_map_of_connections_ACDCNTC2)
    return _map_of_connections
end

############### pre simulation 
function map_Of_Connections_ACDCNTC(data, s)
    nodes = s["nodes"]
    nodes_ntc = DataFrames.DataFrame(XLSX.readtable(s["rt_ex"]*"input.xlsx", "nodes_ntc"))
    _map_of_connections_ACDCNTC=DataFrames.DataFrame("from"=>[],"to"=>[],"lat_fr"=>[],"long_fr"=>[],"lat_to"=>[],"long_to"=>[],"mva"=>[],"type"=>[])
    for (key,br) in data["branch"]
        df_fr_ac=nodes[only(findall(==(br["f_bus"]), nodes.node)), :]
        df_to_ac=nodes[only(findall(==(br["t_bus"]), nodes.node)), :]
        mva=first(s["xd"]["branch"][key]["rateA"])
        from=string(df_fr_ac.country)*string(df_fr_ac.type)
        to=string(df_to_ac.country)*string(df_to_ac.type)
        push!(_map_of_connections_ACDCNTC,[from,to,df_fr_ac.lat,df_fr_ac.long,df_to_ac.lat,df_to_ac.long,mva,"AC"])
    end

    cvs=data["convdc"]
    for (key_br,br) in data["branchdc"]
        df_fr_dc=DataFrames.DataFrame()
        df_to_dc=DataFrames.DataFrame()
        for (key_cv,cv) in cvs; 
            if (br["fbusdc"]==cv["busdc_i"]);
                df_fr_dc=nodes[only(findall(==(cv["busac_i"]), nodes.node)), :];
            elseif (br["tbusdc"]==cv["busdc_i"]);
                df_to_dc=nodes[only(findall(==(cv["busac_i"]), nodes.node)), :]; 
            end
        end
            mva=first(s["xd"]["branchdc"][key_br]["rateA"])
        if (br["status"]==0)#candidate HVDC
            from=string(df_fr_dc.country)*string(df_fr_dc.type)
            to=string(df_to_dc.country)*string(df_to_dc.type)
            push!(_map_of_connections_ACDCNTC,[from,to,df_fr_dc.lat,df_fr_dc.long,df_to_dc.lat,df_to_dc.long,mva,"DC"])
        elseif (br["status"]==1)#NTC    
            df_fr_ntc=nodes_ntc[only(findall(==(df_fr_dc["country"]), nodes_ntc.country)), :]
            df_to_ntc=nodes_ntc[only(findall(==(df_to_dc["country"]), nodes_ntc.country)), :]
            from=string(df_fr_ntc.country)
            to=string(df_to_ntc.country)
            push!(_map_of_connections_ACDCNTC,[from,to,df_fr_ntc.lat,df_fr_ntc.long,df_to_ntc.lat,df_to_ntc.long,mva,"NTC"])
        end
    end
    return _map_of_connections_ACDCNTC
end

function problemOUTPUT_map(results, lat_offset, long_offset, lo, la, txt_x=1)
    s=results["s"]
    nodes = s["nodes"]
    
    df_map=post_map_Of_Connections_ACDCNTC(results)
    #df_map=post_map_Of_Connections_ACDCNTC_ACgrid(results)
    df_map["0"]
    for (k,_map) in df_map
    println(k)    
    println(_map)
    end

    #country node display    
    countries=filter(:type => !=(0), s["nodes"])        
    markerCNT = PlotlyJS.attr(size=[15*txt_x],
                color="green")

    #country legend
    traceCNT = [PlotlyJS.scattergeo(;mode="markers+text",textfont=PlotlyJS.attr(size=50*txt_x),
                lat=[row[:lat]],lon=[row[:long]],
                marker=markerCNT)  for row in eachrow(countries)]

    #OWPP node display 
    owpps=filter(:type => ==(0), s["nodes"])           
    markerWF = PlotlyJS.attr(size=[15*txt_x],
                color="navy")

    #windfarm legend
    traceWF = [PlotlyJS.scattergeo(;mode="markers+text",textfont=PlotlyJS.attr(size=50*txt_x),
                lat=[row[:lat]],lon=[row[:long]],
                marker=markerWF)  for row in eachrow(owpps)]

    
     #DC line display
     lineDCtext = PlotlyJS.attr(width=25*txt_x,color="black") 
     lineDC0 = PlotlyJS.attr(width=5*txt_x,color="black")
     lineDC1 = PlotlyJS.attr(width=5*txt_x,color="black",dash="dash")
     lineDC2 = PlotlyJS.attr(width=5*txt_x,color="black",dash="dot")

     
     #AC line display
     lineACtext = PlotlyJS.attr(width=25*txt_x,color="red")
     lineAC0 = PlotlyJS.attr(width=5*txt_x,color="red")
     lineAC1 = PlotlyJS.attr(width=5*txt_x,color="red",dash="dash")
     lineAC2 = PlotlyJS.attr(width=5*txt_x,color="red",dash="dot")

         #AC line legend
    traceAC0=[PlotlyJS.scattergeo(;mode="lines",
    lat=[row.lat_fr,(row.lat_fr+row.lat_to)/2-lat_offset,row.lat_to],
    lon=[row.long_fr,(row.long_fr+row.long_to)/2-long_offset,row.long_to],line=lineAC0) 
    for row in eachrow(df_map["0"]) if (row[:type]=="AC")]

    traceAC1=[PlotlyJS.scattergeo(;mode="lines",
    lat=[row.lat_fr,(row.lat_fr+row.lat_to)/2-lat_offset,row.lat_to],
    lon=[row.long_fr,(row.long_fr+row.long_to)/2-long_offset,row.long_to],line=lineAC1) 
    for row in eachrow(df_map["1"]) if (row[:type]=="AC")]

    traceAC2=[PlotlyJS.scattergeo(;mode="lines",
    lat=[row.lat_fr,(row.lat_fr+row.lat_to)/2-lat_offset,row.lat_to],
    lon=[row.long_fr,(row.long_fr+row.long_to)/2-long_offset,row.long_to],line=lineAC2) 
    for row in eachrow(df_map["2"]) if (row[:type]=="AC")]

     #DC line legend
    traceDC0=[PlotlyJS.scattergeo(;mode="lines",
    lat=[row.lat_fr,(row.lat_fr+row.lat_to)/2+lat_offset,row.lat_to],
    lon=[row.long_fr,(row.long_fr+row.long_to)/2+long_offset,row.long_to],line=lineDC0) 
    for row in eachrow(df_map["0"]) if (row[:type]=="DC")]
    
    traceDC1=[PlotlyJS.scattergeo(;mode="lines",
    lat=[row.lat_fr,(row.lat_fr+row.lat_to)/2+lat_offset,row.lat_to],
    lon=[row.long_fr,(row.long_fr+row.long_to)/2+long_offset,row.long_to],line=lineDC1) 
    for row in eachrow(df_map["1"]) if (row[:type]=="DC")]
    
    traceDC2=[PlotlyJS.scattergeo(;mode="lines",
    lat=[row.lat_fr,(row.lat_fr+row.lat_to)/2+lat_offset,row.lat_to],
    lon=[row.long_fr,(row.long_fr+row.long_to)/2+long_offset,row.long_to],line=lineDC2) 
    for row in eachrow(df_map["2"]) if (row[:type]=="DC")]


    df=vcat(df_map["2"],df_map["1"],df_map["0"])

    traceAClabels=[PlotlyJS.scattergeo(;mode="text",
    lat=[(row.lat_fr+row.lat_to)/2-la*lat_offset],
    lon=[(row.long_fr+row.long_to)/2-lo*long_offset],text=[string(round(row.mva/10,digits = 1))*" GW"], 
    textfont=PlotlyJS.attr(size=25*txt_x,color="red"), marker=lineACtext, textposition="middle bottom") 
    for row in eachrow(df) if (row[:type]=="AC")]

    traceDClabels=[PlotlyJS.scattergeo(;mode="text",
    lat=[(row.lat_fr+row.lat_to)/2+la*lat_offset],
    lon=[(row.long_fr+row.long_to)/2+lo*long_offset],text=[string(round(row.mva/10,digits = 1))*" GW"], 
    textfont=PlotlyJS.attr(size=25*txt_x,color="black"), marker=lineDCtext,textposition="middle top") 
    for row in eachrow(df) if (row[:type]=="DC")]    
           

    #combine plot data                
    #trace=vcat(traceCNT,traceWF,traceDC,traceAC)
    trace=vcat(traceCNT,traceWF,traceAC0,traceAC1,traceAC2,traceDC0,traceDC1,traceDC2,traceAClabels,traceDClabels)
    #trace=vcat(traceCNT,traceWF,traceAC0,traceAC1,traceAC2,traceDC0,traceDC1,traceDC2)
    #trace=vcat(traceCNT,traceWF)

    #set map location
    geo = PlotlyJS.attr(scope="europe",fitbounds="locations")

    
    #plot layput
    layout = PlotlyJS.Layout(geo=geo,showlegend=false, geo_resolution=50, width=1000, height=1100, 
    #legend = PlotlyJS.attr(x=0,y = 0.95,font=PlotlyJS.attr(size=25*txt_x),bgcolor= "#1C00ff00"), 
    margin=PlotlyJS.attr(l=0, r=0, t=0, b=0))

    #display plot
    PlotlyJS.plot(trace, layout)
end

function problemINPUT_map(data, s, txt_x=1)
    nodes = s["nodes"]
    df_map=map_Of_Connections_ACDCNTC(data, s)
    println(df_map)

    #country node display    
    countries=filter(:type => !=(0), s["nodes"])        
    markerCNT = PlotlyJS.attr(size=[15*txt_x],
                color="green")

    #country legend
    traceCNT = [PlotlyJS.scattergeo(;mode="markers+text",textfont=PlotlyJS.attr(size=50*txt_x),
                lat=[row[:lat]],lon=[row[:long]],
                marker=markerCNT)  for row in eachrow(countries)]

    #OWPP node display 
    owpps=filter(:type => ==(0), s["nodes"])           
    markerWF = PlotlyJS.attr(size=[15*txt_x],
                color="navy")

    #windfarm legend
    traceWF = [PlotlyJS.scattergeo(;mode="markers+text",textfont=PlotlyJS.attr(size=50*txt_x),
                lat=[row[:lat]],lon=[row[:long]],
                marker=markerWF)  for row in eachrow(owpps)]

    #windfarm legend
    traceWF = [PlotlyJS.scattergeo(;mode="markers+text",textfont=PlotlyJS.attr(size=50*txt_x),
                lat=[row[:lat]],lon=[row[:long]],
                marker=markerWF)  for row in eachrow(owpps)]
    
     #DC line display
     lineDC = PlotlyJS.attr(width=1*txt_x,color="black",dash="dash")

     #DC line legend
     traceDC=[PlotlyJS.scattergeo(;mode="lines",
                     lat=[row.lat_fr,row.lat_to],
                     lon=[row.long_fr,row.long_to],line=lineDC) 
                     for row in eachrow(df_map) if (row[:type]=="DC")]

    #AC line display
    lineAC = PlotlyJS.attr(width=1*txt_x,color="red",dash="dash")

    #DC line legend
    traceAC=[PlotlyJS.scattergeo(;mode="lines",
    lat=[row.lat_fr,row.lat_to],
    lon=[row.long_fr,row.long_to],line=lineAC) 
    for row in eachrow(df_map) if (row[:type]=="AC")]

    #NTC line display
    lineNTC = PlotlyJS.attr(width=1*txt_x,color="blue")

    #NTC line legend
    traceNTC=[PlotlyJS.scattergeo(;mode="lines",
    lat=[row.lat_fr,row.lat_to],
    lon=[row.long_fr,row.long_to],line=lineNTC) 
    for row in eachrow(df_map) if (row[:type]=="NTC")]    

    #combine plot data                
    #trace=vcat(traceCNT,traceWF,traceDC,traceAC)
    trace=vcat(traceCNT,traceWF,traceNTC,traceDC,traceAC)
    #trace=vcat(traceCNT,traceWF)

    #set map location
    geo = PlotlyJS.attr(scope="europe",fitbounds="locations")

    #plot layput
    layout = PlotlyJS.Layout(geo=geo,geo_resolution=50, width=1000, height=1100, 
    #legend = PlotlyJS.attr(x=0,y = 0.95,font=PlotlyJS.attr(size=25*txt_x),bgcolor= "#1C00ff00"), 
    margin=PlotlyJS.attr(l=0, r=0, t=0, b=0))

    #display plot
    PlotlyJS.plot(trace, layout)
end
#######################################################################
#input results_nodal=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\UK_DE_DK\\nodal_results_VOLL5000b_rc.jld2")
#s_nodal, result_mip_nodal, data_nodal, mn_data_nodal=summarize_in_s(results_nodal);
#topology_map(s_nodal, 1.75)
function topology_map(s, txt_x=1)
    #handle time steps
    t0=deepcopy(s["topology"]["t0"])
    t2=deepcopy(s["topology"]["t2"])
    tinf=deepcopy(s["topology"]["tinf"])
    for row in eachrow(s["nodes"]);
        #storage
        if (t0[string(row[:node][1])]["strg"]==0)
            t0[string(row[:node][1])]["strg"]="-"
        else
            t0[string(row[:node][1])]["strg"]=string(round(t0[string(row[:node][1])]["strg"]/10))
        end
        if (t2[string(row[:node][1])]["strg"]==0)
            t2[string(row[:node][1])]["strg"]="-"
        else
            t2[string(row[:node][1])]["strg"]=string(round(t2[string(row[:node][1])]["strg"]/10))
        end
        if (tinf[string(row[:node][1])]["strg"]==0)
            tinf[string(row[:node][1])]["strg"]="-"
        else
            tinf[string(row[:node][1])]["strg"]=string(round(tinf[string(row[:node][1])]["strg"]/10))
        end
        #converters
        if (t0[string(row[:node][1])]["conv"]==0)
            t0[string(row[:node][1])]["conv"]="-"
        else
            t0[string(row[:node][1])]["conv"]=string(round(t0[string(row[:node][1])]["conv"]/10))
        end
        if (t2[string(row[:node][1])]["conv"]==0)
            t2[string(row[:node][1])]["conv"]="-"
        else
            t2[string(row[:node][1])]["conv"]=string(round(t2[string(row[:node][1])]["conv"]/10))
        end
        if (tinf[string(row[:node][1])]["conv"]==0)
            tinf[string(row[:node][1])]["conv"]="-"
        else
            tinf[string(row[:node][1])]["conv"]=string(round(tinf[string(row[:node][1])]["conv"]/10))
        end
        if (row[:type]==0)
            #wf
            if (t0[string(row[:node][1])]["wf"]==0)
                t0[string(row[:node][1])]["wf"]="-"
            else
                t0[string(row[:node][1])]["wf"]=string(round(t0[string(row[:node][1])]["wf"]/10))
            end
            if (t2[string(row[:node][1])]["wf"]==0)
                t2[string(row[:node][1])]["wf"]="-"
            else
                t2[string(row[:node][1])]["wf"]=string(round(t2[string(row[:node][1])]["wf"]/10))
            end
            if (tinf[string(row[:node][1])]["wf"]==0)
                tinf[string(row[:node][1])]["wf"]="-"
            else
                tinf[string(row[:node][1])]["wf"]=string(round(tinf[string(row[:node][1])]["wf"]/10))
            end
        end
    end
    
    #country node display            
    markerCNT = PlotlyJS.attr(size=[10*txt_x],
                color="green",
                line_color="green")

    #country legend
    traceCNT = [PlotlyJS.scattergeo(;mode="markers+text",textfont=PlotlyJS.attr(size=25*txt_x),
                textposition="top center",text=string(row[:node])*": "*row[:country],
                name=string(row[:node])*": "*t0[string(row[:node][1])]["conv"]*","
                *t2[string(row[:node][1])]["conv"]*","*tinf[string(row[:node][1])]["conv"]*"GW/"
                *t0[string(row[:node][1])]["strg"]*","*t2[string(row[:node][1])]["strg"]*","
                *tinf[string(row[:node][1])]["strg"]*"GWh",
                lat=[row[:lat]],lon=[row[:long]],
                marker=markerCNT)  for row in eachrow(s["nodes"]) if (row[:type]==1)]

    #windfarm node display
    markerWF = PlotlyJS.attr(size=[10*txt_x],
    color="blue",
    line_color="blue")

    #windfarm legend
    traceWF = [PlotlyJS.scattergeo(;mode="markers+text",textfont=PlotlyJS.attr(size=25*txt_x),
                textposition="top center",text=string(row[:node])*": "*row[:country]*"(WF)",
                name=string(row[:node])*": "*t0[string(row[:node][1])]["wf"]*","
                *t2[string(row[:node][1])]["wf"]*","*tinf[string(row[:node][1])]["wf"]*"GW/"
                *t0[string(row[:node][1])]["conv"]*","*t2[string(row[:node][1])]["conv"]*","
                *tinf[string(row[:node][1])]["conv"]*"GW/"*t0[string(row[:node][1])]["strg"]*","
                *t2[string(row[:node][1])]["strg"]*","*tinf[string(row[:node][1])]["strg"]*"GWh",
                lat=[row[:lat]],lon=[row[:long]],
                marker=markerWF)  for row in eachrow(s["nodes"]) if (row[:type]==0)]
    
    #DC line display
    lineDC = PlotlyJS.attr(width=2*txt_x,color="black")

    #DC line legend
    traceDC=[PlotlyJS.scattergeo(;mode="lines",name=string(Int64(row[:from]))*"-"
                    *string(Int64(row[:to]))*": "*string(round(row[:mva])/10)*" GW",
                    lat=[filter(:node=>x->x==Int64(row[:from]), s["nodes"])[!,:lat][1],
                    filter(:node=>x->x==Int64(row[:to]), s["nodes"])[!,:lat][1]],
                    lon=[filter(:node=>x->x==Int64(row[:from]), s["nodes"])[!,:long][1],
                    filter(:node=>x->x==Int64(row[:to]), s["nodes"])[!,:long][1]],line=lineDC) 
                    for row in eachrow(tinf["dc"])]
                    
    #AC line display
    lineAC = PlotlyJS.attr(width=3*txt_x,color="red",dash="dash")
    
    #AC line legend
    traceAC=[PlotlyJS.scattergeo(;mode="lines",name=string(Int64(row[:from]))*"-"
                *string(Int64(row[:to]))*": "*string(round(row[:mva])/10)*" GW",
                lat=[filter(:node=>x->x==Int64(row[:from]), s["nodes"])[!,:lat][1],
                filter(:node=>x->x==Int64(row[:to]), s["nodes"])[!,:lat][1]],
                lon=[filter(:node=>x->x==Int64(row[:from]), s["nodes"])[!,:long][1],
                filter(:node=>x->x==Int64(row[:to]), s["nodes"])[!,:long][1]],line=lineAC) 
                for row in eachrow(tinf["ac"])]
    
    #combine plot data                
    trace=vcat(traceCNT,traceWF,traceDC,traceAC)
    #trace=vcat(traceCNT,traceWF)

    #set map location
    geo = PlotlyJS.attr(scope="europe",fitbounds="locations")

    #plot layput
    layout = PlotlyJS.Layout(geo=geo,geo_resolution=50, width=1000, height=1100, 
    #legend = PlotlyJS.attr(x=0,y = 0.95,font=PlotlyJS.attr(size=25*txt_x),bgcolor= "#1C00ff00"), 
    margin=PlotlyJS.attr(l=0, r=0, t=0, b=0))

    #display plot
    PlotlyJS.plot(trace, layout)
end


function plot_generation_profile(gen, con)

    clrs=generation_color_map()
    #get generator names
    col_names=names(gen[!,2:end])
    for col in col_names;
        if (isapprox(sum(gen[!,col]),0,atol=1))
            DataFrames.select!(gen, DataFrames.Not(Symbol(col)))
    end;end

	#battery energy
	con_sum=DataFrames.DataFrame();con_sum[!,:ts]=con[!,:ts]
	if (hasproperty(gen,:Battery))
		bat=gen[!,"Battery"]
		bat_d=[imp>=0 ? imp : 0 for imp in bat]
		if (sum(bat_d)>0);gen[!,"Battery Discharge"]=bat_d;end
		bat_c=[exp<=0 ? exp : 0 for exp in bat]
		if (sum(bat_c)<0);con[!,"Battery Charge"]=bat_c;end
		if (sum(bat_c)<0);con_sum[!,"Battery Charge"]=bat_c;end
		gen=DataFrames.select!(gen,DataFrames.Not(Symbol("Battery")))
	end

    #consumption/generation values
    col_names_con=names(con[!,1:end])
    all_con=length(col_names_con)>1 ? abs.(sum(eachcol(con[!,2:end]))) : zeros(Int8,length(con[!,:ts]))
    all_gen=abs.(sum(eachcol(gen[!,2:end])))

    #imported energy
    import_export=all_con.-all_gen
    imp=[imp>=0 ? imp : 0 for imp in import_export]
    if (sum(imp)>0);gen[!,"Import"]=imp;end

    #Set range
    gen[!,2:end]=gen[!,2:end]./10
    all_gen=abs.(sum(eachcol(gen[!,2:end])))
    rng_gen=maximum(all_gen)

    #exported energy
    exp=[exp<=0 ? exp : 0 for exp in import_export]
    if (sum(exp)<0);con_sum[!,"Export"]=exp;end
	if (sum(all_con)>0);con_sum[!,"Demand"]=-1*all_con;end

    #scale and sum consumption data
    con_sum[!,2:end]=con_sum[!,2:end]./10
	all_con=abs.(sum(eachcol(con_sum[!,2:end])))
    rng_con=maximum(all_con)

    #names to display of consumption and generation
    col_names_gen=names(gen[!,2:end])
    col_names_con=names(con_sum[!,2:end])

    #generation data
    scatter_vec_gen=[PlotlyJS.scatter(
            x=gen[!,:ts], y=gen[!,Symbol(nm)],
            stackgroup="one", name=String(nm), mode="lines", hoverinfo="x+y",
            line=PlotlyJS.attr(width=0.5, color=clrs[nm])
        ) for nm in col_names_gen]

    #consumption data    
    scatter_vec_con=[PlotlyJS.scatter(
            x=con_sum[!,:ts], y=con_sum[!,Symbol(nm)],
            stackgroup="two", name=String(nm), mode="lines", hoverinfo="x+y",
            line=PlotlyJS.attr(width=0.5, color=clrs[nm])
        ) for nm in col_names_con]

    #combine gen and consumption
    scatter_vec=vcat(scatter_vec_con,scatter_vec_gen)

    #plot layout
    layout=PlotlyJS.Layout(font_size=25,yaxis_range=(-1*rng_con, rng_gen),yaxis_title="GW",xaxis_title="time steps")

    #plot
    PlotlyJS.plot(scatter_vec, layout)
end


function plot_dual_marginal_price(result_mip, tss, cuntree)

    #initialize data structures
    clrs=generation_color_map()
    marg_price=Dict();
    push!(marg_price,"cuntrees"=>Dict());

    #copy marginal price per node
    if !(haskey(marg_price,"ts"));push!(marg_price,"ts"=>[]);end
    for (n,nw) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"]), by=x->parse(Int64,x));
        if (issubset([string(n)],tss))
            push!(marg_price["ts"],n)
            for (b,bs) in nw["bus"];
                if (parse(Int8,b)==first(cuntree))
                if !(haskey(marg_price["cuntrees"],last(cuntree)));push!(marg_price["cuntrees"],last(cuntree)=>[]);end
                push!(marg_price["cuntrees"][last(cuntree)],bs["lam_kcl_r"]);end;end;
        end;end

    #place marginal price in plot structure    
    scatter_vec_gen=[PlotlyJS.scatter(
            x=marg_price["ts"], y=marginal_prices,
            name=cuntree, mode="lines",
            line=PlotlyJS.attr(width=2, color=clrs[cuntree])) 
            for (cuntree,marginal_prices) in marg_price["cuntrees"]]
    
    #calculate plot limits
    lims=[(maximum(marginal_prices),minimum(marginal_prices)) 
        for (cuntree,marginal_prices) in marg_price["cuntrees"]]
        
    #plot layout
    layout=PlotlyJS.Layout(font_size=35,yaxis_range=(minimum(last.(lims)),
        maximum(first.(lims))),yaxis_title="€/MWh",xaxis_title="time steps")
    
    #display plot    
    PlotlyJS.plot(scatter_vec_gen, layout)
end


function plot_cumulative_wf_income_all_scenarios(s, mn_data, wf_country)
    #get generation buses
    bus=filter(:country=>x->x==wf_country,filter(:type=>x->x==0,s["nodes"]))[!,:node][1]
    gen= string(first(s["wfz"][findfirst(x->x==bus,s["offshore_nodes"])]))
    node=string(bus)

    #convert 3 years of sampled hours to 30 year timeline
    hrs=s["hours_length"]
    hours2lifetime=(8760*10/hrs)

    #cost of building owpp
    wf_price=s["cost_summary"]["owpp"]["totals"][gen]

    #find wf cumulative income 
    scenarios=sort!(OrderedCollections.OrderedDict(mn_data["scenario"]), by=x->parse(Int64,x))
    cum_incomes=[];prices=[];hours=[]
    for (scenario, tss) in scenarios
        hourly_income=s["income_summary"]["owpp"][scenario][node]
        push!(cum_incomes,[sum(hourly_income["income"][1:i]) for (i,ic) in enumerate(hourly_income["income"])])
        push!(prices,hourly_income["price_not_npv"])
        if (scenario=="1")
            hours=hourly_income["hour"];end
    end

    #take first scenario for in come and price
    cum_income=cum_incomes[1]
    price=prices[1]

    #if more than one scenario take the average income
    if (length(cum_incomes)>1)
        for ci in cum_incomes[2:end]
        cum_income=cum_income.+ci;end
        cum_income=cum_income/length(cum_incomes)
        end

    #if more than one scenario take average price
    if (length(prices)>1)
        for p in prices[2:end]
            price=price.+p;end
            price=price/length(prices)
        end

    #plot struct for cumulative income/investment/enery price
    data = [PlotlyJS.bar(;x=parse.(Int64,hours)*hours2lifetime,
                name="Cumulative Revenue (NPV)",
                y=cum_income),
                PlotlyJS.scatter(;x=parse.(Int64,hours)*hours2lifetime,
                y=ones(length(hours))*wf_price,
                name="Investment (CAPEX+OPEX)",
                line=PlotlyJS.attr(width=2, color="red")),
                PlotlyJS.scatter(;x=parse.(Int64,hours)*hours2lifetime,
                y=price,name="Energy Price", line=PlotlyJS.attr(width=2, color="black"), yaxis="y2")]

    #plot layout            
    layout=PlotlyJS.Layout(legend = PlotlyJS.attr(x = 0., y= maximum(cum_income)), 
            width=1000, height=550,font_size=35,yaxis_range=(0,maximum(cum_income)), 
            yaxis_title="M€",xaxis_title="Hours",yaxis2=PlotlyJS.attr(title="€/MWh",
            overlaying="y",side="right"))

    #display plot
    PlotlyJS.plot(data, layout)
end


function plot_cumulative_income_all_scenarios_allWF(s, mn_data)

    kolors=generation_color_map()

    #convert hours to 30 year life
    hrs=s["hours_length"]
    hours2lifetime=(8760*10/hrs)

    #initialize dictionaries
    data_dict=Dict()
    wf_cost=0
    hours=[]


    for bus in s["offshore_nodes"]
        #get wf nodes and their costs
        if !(haskey(data_dict,string(bus)));push!(data_dict,string(bus)=>Dict());end
        gen= string(first(s["wfz"][findfirst(x->x==bus,s["offshore_nodes"])]))
        wf_cost=wf_cost+s["cost_summary"]["owpp"]["totals"][gen]
        node=string(bus)

        #calculate cumulative income for wfs
        scenarios=sort!(OrderedCollections.OrderedDict(mn_data["scenario"]), by=x->parse(Int64,x))
        cum_incomes=[];powers=[];hours=[]
        for (scenario, tss) in scenarios
            hourly_income=s["income_summary"]["owpp"][scenario][node]
            push!(cum_incomes,[sum(hourly_income["income"][1:i]) for (i,ic) in enumerate(hourly_income["income"])])
            if (scenario=="1")
                hours=hourly_income["hour"];end
        end

        #take first scenario data
        cum_income=cum_incomes[1]

        #if more than one scenario take average
        if (length(cum_incomes)>1)
            for ci in cum_incomes[2:end]
                cum_income=cum_income.+ci;end
                cum_income=cum_income/length(cum_incomes)
            end
            data_dict[string(bus)]["cum_income"]=cum_income
            data_dict[string(bus)]["hours"]=hours
        end
        
        #construct plot data structure for income
        data1=[PlotlyJS.scatter(;x=parse.(Int64,hours)*hours2lifetime,
            y=dic["cum_income"],
            name="WF "*string(wf),
            stackgroup="one", mode="lines", hoverinfo="x+y",
            line=PlotlyJS.attr(width=0.5, color=kolors[string(wf)])
        ) for (wf,dic) in data_dict]

        #construct plot data structure for investment
        data2=PlotlyJS.scatter(x=parse.(Int64,hours)*hours2lifetime,
            y=ones(length(hours))* wf_cost,name="OWPPs Investment (NPV)", 
            line=PlotlyJS.attr(width=3, color="black"))

        #combine income and investment struct 
        data=vcat(data1,data2)

        #plot display layout
        layout=PlotlyJS.Layout(; width=1000, height=550,font_size=27,  
        yaxis_title="M€",xaxis_title="Hours",
        legend = PlotlyJS.attr(x = 0., y= 1,bgcolor= "#1C00ff00"))
        
        #display plot
        PlotlyJS.plot(data, layout)
end


#
function plot_cumulative_wf_production_all_scenarios(s, mn_data, wf_country)
    bus=filter(:country=>x->x==wf_country,filter(:type=>x->x==0,s["nodes"]))[!,:node][1]
    gen= string(first(s["wfz"][findfirst(x->x==bus,s["offshore_nodes"])]))
    node=string(bus)
    hrs=s["hours_length"]
    hours2lifetime=(8760*10/hrs)
    scenarios=sort!(OrderedCollections.OrderedDict(mn_data["scenario"]), by=x->parse(Int64,x))
    cum_generations=[];powers=[];hours=[]
    for (scenario, tss) in scenarios
        hourly_income=s["income_summary"]["owpp"][scenario][node]
        push!(cum_generations,[sum(hourly_income["power"][1:i]./10) for (i,ic) in enumerate(hourly_income["power"])])
        push!(powers,hourly_income["power"]/10)
        if (scenario=="1")
            hours=hourly_income["hour"];end
    end
    cum_generation=cum_generations[1]
    power=powers[1]

    if (length(cum_generations)>1)
        for ci in cum_generations[2:end]
        cum_generation=cum_generation.+ci;end
        cum_generation=cum_generation/length(cum_generations)
        end
    if (length(powers)>1)
        for p in powers[2:end]
            power=power.+p;end
            power=power/length(powers)
        end

    data = [PlotlyJS.bar(;x=parse.(Int64,hours)*hours2lifetime,
                name="Cumulative Generation", marker=PlotlyJS.attr(width=2, color="green"),
                y=cum_generation*hours2lifetime),
                PlotlyJS.scatter(;x=parse.(Int64,hours)*hours2lifetime,
                y=power,name="Hourly Generation", line=PlotlyJS.attr(width=2, color="red"), yaxis="y2")]

        PlotlyJS.plot(data, PlotlyJS.Layout(legend = PlotlyJS.attr(x = 0., y= maximum(cum_generation*hours2lifetime)), width=1000, height=550,font_size=35,yaxis_range=(0,maximum(cum_generation*hours2lifetime)), yaxis_title="GWh",xaxis_title="Hours",yaxis2=PlotlyJS.attr(
        title="GWh",
        overlaying="y",
        side="right"
    )))
end

function plot_cumulative_production_all_scenarios_allWF(s, mn_data)
    kolors=generation_color_map()
    hrs=s["hours_length"]
    hours2lifetime=(8760*10/hrs)
    data_dict=Dict()
    for bus in s["offshore_nodes"]
        if !(haskey(data_dict,string(bus)));push!(data_dict,string(bus)=>Dict());end
        gen= string(first(s["wfz"][findfirst(x->x==bus,s["offshore_nodes"])]))
        node=string(bus)
        scenarios=sort!(OrderedCollections.OrderedDict(mn_data["scenario"]), by=x->parse(Int64,x))
        cum_generations=[];powers=[];hours=[]
        for (scenario, tss) in scenarios
            hourly_income=s["income_summary"]["owpp"][scenario][node]
            push!(cum_generations,[sum(hourly_income["power"][1:i]./10) for (i,ic) in enumerate(hourly_income["power"])])
            push!(powers,hourly_income["power"]/10)
            if (scenario=="1")
                hours=hourly_income["hour"];end
        end
        cum_generation=cum_generations[1]
        power=powers[1]

        if (length(cum_generations)>1)
            for ci in cum_generations[2:end]
            cum_generation=cum_generation.+ci;end
            cum_generation=cum_generation/length(cum_generations)
            end
        if (length(powers)>1)
            for p in powers[2:end]
                power=power.+p;end
                power=power/length(powers)
            end
            data_dict[string(bus)]["power"]=power
            data_dict[string(bus)]["cum_generation"]=cum_generation
            data_dict[string(bus)]["hours"]=hours
        end

        data1=[PlotlyJS.bar(;x=parse.(Int64,dic["hours"])*hours2lifetime,
            y=dic["cum_generation"]*hours2lifetime,
            name="WF "*string(wf),
            marker=PlotlyJS.attr(width=2, color=kolors[string(wf)])
        ) for (wf,dic) in data_dict]


    data=vcat(data1)
    PlotlyJS.plot(data, PlotlyJS.Layout(;barmode="stack", width=1000, height=550,font_size=25, yaxis_title="GWh",xaxis_title="Hours",legend = PlotlyJS.attr(x = 0., y= 1)))
end


function plot_cumulative_income_tl_all_scenarios(s,data)
    hrs=s["hours_length"]
    hourly_income_tl_all_scenarios=s["income_summary"]["tso"]
    hours2days=(8760*10/hrs)
    tl_price=s["cost_summary"]["transmission"]#6205.14#only true if 4GW all in year one
    cum_incomes=Dict()
    for (sc,hourly_income_tl) in hourly_income_tl_all_scenarios
        if !(haskey(cum_incomes, sc));push!(cum_incomes,sc=>Dict("dc"=>Dict(),"ac"=>Dict()));end
        if (sc!="totals")
            for (k_br,br) in sort!(OrderedCollections.OrderedDict(hourly_income_tl["dc"]), by=x->parse(Int64,x))
                push!(cum_incomes[sc]["dc"],string(data["branchdc"][k_br]["fbusdc"])*"-"*string(data["branchdc"][k_br]["tbusdc"])=>[sum(br["rent"][1:i]) for (i,ic) in enumerate(br["rent"])]);
            end;
            for (k_br,br) in sort!(OrderedCollections.OrderedDict(hourly_income_tl["ac"]), by=x->parse(Int64,x))
                push!(cum_incomes[sc]["ac"],string(data["branch"][k_br]["f_bus"])*"-"*string(data["branch"][k_br]["t_bus"])=>[sum(br["rent"][1:i]) for (i,ic) in enumerate(br["rent"])]);
            end;end;end
    cum_income=Dict("DC"=>Dict(),"AC"=>Dict())
    for (sc,cum_inc) in cum_incomes
        for (br_k,ci_dc) in cum_inc["dc"]
            if !(haskey(cum_income["DC"], br_k));
                push!(cum_income["DC"],br_k=>ci_dc);
            else
                cum_income["DC"][br_k]=cum_income["DC"][br_k].+ci_dc
            end
        end
        for (br_k,ci_ac) in cum_inc["ac"]
            if !(haskey(cum_income["AC"], br_k));
                push!(cum_income["AC"],br_k=>ci_ac);
            else
                cum_income["AC"][br_k]=cum_income["AC"][br_k].+ci_ac
            end
        end
    end

    data2=PlotlyJS.scatter(x=parse.(Int64,s["income_summary"]["tso"]["1"]["hour"])*hours2days,
    y=ones(length(s["income_summary"]["tso"]["1"]["hour"]))*tl_price,name="TLs Investment (NPV)", line=PlotlyJS.attr(width=3, color="red"))

        data1=[PlotlyJS.scatter(
                x=parse.(Int64,s["income_summary"]["tso"]["1"]["hour"])*hours2days, y=inc/length(cum_incomes),
                name=kv*" branch "*string(nm),stackgroup="one", mode="lines", hoverinfo="x+y",
                line=PlotlyJS.attr(width=0.5)
            ) for (kv,voltage) in cum_income for (nm,inc) in voltage]

        data=vcat(data1,data2)
        PlotlyJS.plot(data,  PlotlyJS.Layout(;width=1000, height=550,font_size=27, yaxis_title="M€",xaxis_title="Hours",legend = PlotlyJS.attr(x = 0., y= 1,bgcolor= "#1C00ff00")))
end


function plot_cumulative_income(s,scenario, node, gen)
    hrs=s["hours_length"]
    hourly_income=s["income_summary"]["owpp"][scenario][node]
    hours2days=(8760*10/hrs)/24
    wf_price=s["cost_summary"]["owpp"]["totals"][gen]#6205.14#only true if 4GW all in year one
    cum_income=[sum(hourly_income["income"][1:i]) for (i,ic) in enumerate(hourly_income["income"])]
    data = [PlotlyJS.bar(;x=parse.(Int64,hourly_income["hour"])*hours2days,
                name="Cumulative Revenue (NPV)", y=cum_income),PlotlyJS.scatter(;x=parse.(Int64,hourly_income["hour"])*hours2days,
                y=ones(length(hourly_income["hour"]))*wf_price,
                name="Investment (CAPEX+OPEX)",
                line=PlotlyJS.attr(width=2, color="red")),
                PlotlyJS.scatter(;x=parse.(Int64,hourly_income["hour"])*hours2days,
               	y=hourly_income["power"]*100,name="Energy Production", line=PlotlyJS.attr(width=2, color="black"), yaxis="y2")]
        PlotlyJS.plot(data, PlotlyJS.Layout(legend = PlotlyJS.attr(x = 0., y= maximum(cum_income)),font_size=35,yaxis_range=(0,maximum(cum_income)), yaxis_title="M€",xaxis_title="Days",yaxis2=PlotlyJS.attr(
        title="MWh",
        overlaying="y",
        side="right"
    )))
end

####################################### Print solution ################################

function tl_totals(s_nodal,data_nodal)
    hrs=s_nodal["hours_length"]
    hourly_income_tl_all_scenarios=s_nodal["income_summary"]["tso"]
    hours2days=(8760*10/hrs)
    tl_price=s_nodal["cost_summary"]["transmission"]#6205.14#only true if 4GW all in year one
    cum_incomes=Dict("all"=>Dict("dc"=>Dict(),"ac"=>Dict(),"total"=>0.0))
    for (sc,hourly_income_tl) in hourly_income_tl_all_scenarios
        if !(haskey(cum_incomes, sc));push!(cum_incomes,sc=>Dict("dc"=>Dict(),"ac"=>Dict()));end
        if (sc!="totals")
            for (k_br,br) in sort!(OrderedCollections.OrderedDict(hourly_income_tl["dc"]), by=x->parse(Int64,x))
                push!(cum_incomes[sc]["dc"],string(data_nodal["branchdc"][k_br]["fbusdc"])*"-"*string(data_nodal["branchdc"][k_br]["tbusdc"])=>[sum(br["rent"][1:i]) for (i,ic) in enumerate(br["rent"])]);
                if !(haskey(cum_incomes["all"]["dc"],string(data_nodal["branchdc"][k_br]["fbusdc"])*"-"*string(data_nodal["branchdc"][k_br]["tbusdc"])));push!(cum_incomes["all"]["dc"],string(data_nodal["branchdc"][k_br]["fbusdc"])*"-"*string(data_nodal["branchdc"][k_br]["tbusdc"])=>0.0);end
                cum_incomes["all"]["dc"][string(data_nodal["branchdc"][k_br]["fbusdc"])*"-"*string(data_nodal["branchdc"][k_br]["tbusdc"])]+=sum(br["rent"])
            end
            for (k_br,br) in sort!(OrderedCollections.OrderedDict(hourly_income_tl["ac"]), by=x->parse(Int64,x))
                push!(cum_incomes[sc]["ac"],string(data_nodal["branch"][k_br]["f_bus"])*"-"*string(data_nodal["branch"][k_br]["t_bus"])=>[sum(br["rent"][1:i]) for (i,ic) in enumerate(br["rent"])]);
                if !(haskey(cum_incomes["all"]["ac"],string(data_nodal["branch"][k_br]["f_bus"])*"-"*string(data_nodal["branch"][k_br]["t_bus"])));push!(cum_incomes["all"]["ac"],string(data_nodal["branch"][k_br]["f_bus"])*"-"*string(data_nodal["branch"][k_br]["t_bus"])=>0.0);end
                cum_incomes["all"]["ac"][string(data_nodal["branch"][k_br]["f_bus"])*"-"*string(data_nodal["branch"][k_br]["t_bus"])]+=sum(br["rent"])
            end;end;end
    
    for (k_br,br) in cum_incomes["all"]["dc"]
        cum_incomes["all"]["dc"][k_br]=br/length(hourly_income_tl_all_scenarios)
        cum_incomes["all"]["total"]=cum_incomes["all"]["total"]+br/length(hourly_income_tl_all_scenarios)
    end
    for (k_br,br) in cum_incomes["all"]["ac"]
        cum_incomes["all"]["ac"][k_br]=br/length(hourly_income_tl_all_scenarios)
        cum_incomes["all"]["total"]=cum_incomes["all"]["total"]+br/length(hourly_income_tl_all_scenarios)
    end
    push!(s_nodal["income_summary"]["tso"],"totals"=>cum_incomes["all"])
    return s_nodal
end 

function generation_color_map()
        color_dict=Dict("Offshore Wind"=>"darkgreen",
        "DSR"=>"aliceblue",
        "UK"=>"darkgreen",
        "WF"=>"navy",
        "DE"=>"red",
        "DK"=>"black",
        "4"=>"darkgreen",
        "5"=>"darkgreen",
        "6"=>"navy",
        "7"=>"red",
        "Onshore Wind"=>"forestgreen",
        "Solar PV"=>"yellow",
        "Solar Thermal"=>"orange",
        "Gas CCGT old 2 Bio"=>"chocolate",
        "Gas CCGT new"=>"chocolate",
		"Gas OCGT new"=>"chocolate",
        "Gas OCGT old"=>"chocolate",
        "Gas CCGT old 1"=>"chocolate",
        "Gas CCGT old 2"=>"chocolate",
        "Gas CCGT present 1"=>"chocolate",
        "Gas CCGT present 2"=>"chocolate",
        "Reservoir"=>"blue",
        "Run-of-River"=>"navy",
        "Nuclear"=>"gray69",
        "Other RES"=>"yellowgreen",
        "Gas conventional old 1"=>"chocolate",
        "Gas conventional old 2"=>"chocolate",
        "Gas CCGT new CCS"=>"chocolate",
        "Gas CCGT present 1 CCS"=>"chocolate",
        "Gas CCGT present 2 CCS"=>"chocolate",
        "Battery Discharge"=>"wheat",
		"Battery Charge"=>"aqua",
        "Gas CCGT CCS"=>"chocolate",
        "Other non-RES"=>"brown",
        "Other non-RES DE00 P"=>"brown",
        "Other non-RES DKW1 P"=>"brown",
        "Lignite new"=>"brown",
        "Lignite old 2"=>"brown",
        "Hard coal new"=>"brown",
        "Hard coal old 1"=>"brown",
        "Hard coal old 2"=>"brown",
        "Hard coal old 2 Bio"=>"brown",
        "Heavy oil old 1 Bio"=>"brown",
        "P2G"=>"brown",
        "PS Closed"=>"blue",
        "PS Open"=>"blue",
        "Demand"=>"grey",
        "Import"=>"red",
        "Export"=>"black")
        return color_dict
end


function owpps_profit_obz(s, result_mip, mn_data)
    for (scenario_num,scenario) in mn_data["scenario"]
        tss=string.(values(scenario))#is this the problem? why keys?
        for (wf_num,wf_node) in enumerate(s["offshore_nodes"])
            s=owpp_profit_obz(s, result_mip, scenario_num, tss, string(wf_node), string(first(s["wfz"][wf_num])))
            if !(haskey(s["income_summary"]["owpp"],"all"));push!(s["income_summary"]["owpp"],"all"=>Dict("power"=>0.0,"income"=>0.0));end
            s["income_summary"]["owpp"]["all"]["power"]= s["income_summary"]["owpp"]["all"]["power"]+s["income_summary"]["owpp"][scenario_num][string(wf_node)]["life_power"]
            s["income_summary"]["owpp"]["all"]["income"]= s["income_summary"]["owpp"]["all"]["income"]+s["income_summary"]["owpp"][scenario_num][string(wf_node)]["life_income"]
        end
    end
    s["income_summary"]["owpp"]["all"]["power"]= s["income_summary"]["owpp"]["all"]["power"]/s["scenarios_length"]
    s["income_summary"]["owpp"]["all"]["income"]= s["income_summary"]["owpp"]["all"]["income"]/s["scenarios_length"]
    return s
end

function owpp_profit_obz(s, result_mip, scenario, tss, bus, gen)
    if !haskey(s,"income_summary");s["income_summary"]=Dict();end
    if !haskey(s["income_summary"],"owpp");s["income_summary"]["owpp"]=Dict();end
    if !haskey(s["income_summary"]["owpp"],scenario);s["income_summary"]["owpp"][scenario]=Dict();end

    hl=1#s["hours_length"]
    yl=1#s["years_length"]
    sl=s["scenarios_length"]
    me2e=1#1000000
    hourly_income=Dict();push!(hourly_income,"price"=>[]);push!(hourly_income,"income"=>[]);push!(hourly_income,"power"=>[]);push!(hourly_income,"hour"=>[]);
    for (n,nw) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"]), by=x->parse(Int64,x));
        if (issubset([string(n)],tss))
            b=nw["bus"][bus];
            g=nw["gen"][gen];

            push!(hourly_income["power"],g["pg"]);
            push!(hourly_income["price"],b["lam_kcl_r"]);
            push!(hourly_income["income"],g["pg"]*b["lam_kcl_r"]*-hl*yl*sl*me2e);
            push!(hourly_income["hour"],n);
    end;end
    hourly_income["life_income"]=sum(hourly_income["income"])
    hourly_income["life_power"]=sum(hourly_income["power"])
    s["income_summary"]["owpp"][scenario][bus]=hourly_income
    return s
end

function strg_profit_obzs(s, result_mip, mn_data)
    for (scenario_num,scenario) in mn_data["scenario"]
        tss=string.(values(scenario))
        for (strg_num,strg_node) in enumerate(vcat(s["offshore_nodes"],s["onshore_nodes"]))
            s=strg_profit_obz(s, result_mip, scenario_num, tss, string(strg_node))
            if !(haskey(s["income_summary"]["strg"],"all"));push!(s["income_summary"]["strg"],"all"=>Dict());end
            if !(haskey(s["income_summary"]["strg"]["all"],"power"));push!(s["income_summary"]["strg"]["all"],"power"=>0.0);end
            if !(haskey(s["income_summary"]["strg"]["all"],"income"));push!(s["income_summary"]["strg"]["all"],"income"=>0.0);end
            if !(haskey(s["income_summary"]["strg"]["all"],string(strg_node)));
                push!(s["income_summary"]["strg"]["all"],string(strg_node)=>s["income_summary"]["strg"][scenario_num][string(strg_node)]["income"]./s["scenarios_length"]);
            else
                s["income_summary"]["strg"]["all"][string(strg_node)]=s["income_summary"]["strg"]["all"][string(strg_node)].+s["income_summary"]["strg"][scenario_num][string(strg_node)]["income"]/s["scenarios_length"]
            end
            if !(haskey(s["income_summary"]["strg"]["all"],"sum"));
                push!(s["income_summary"]["strg"]["all"],"sum"=>s["income_summary"]["strg"][scenario_num][string(strg_node)]["income"]./s["scenarios_length"]);
            else
                s["income_summary"]["strg"]["all"]["sum"]=s["income_summary"]["strg"]["all"]["sum"].+s["income_summary"]["strg"][scenario_num][string(strg_node)]["income"]/s["scenarios_length"]
            end
            s["income_summary"]["strg"]["all"]["power"]= s["income_summary"]["strg"]["all"]["power"]+s["income_summary"]["strg"][scenario_num][string(strg_node)]["life_power"]
            s["income_summary"]["strg"]["all"]["income"]= s["income_summary"]["strg"]["all"]["income"]+s["income_summary"]["strg"][scenario_num][string(strg_node)]["life_income"]
        end
    end
    s["income_summary"]["strg"]["all"]["power"]= s["income_summary"]["strg"]["all"]["power"]/s["scenarios_length"]
    s["income_summary"]["strg"]["all"]["income"]= s["income_summary"]["strg"]["all"]["income"]/s["scenarios_length"]
    return s
end

function strg_profit_obz(s, result_mip, scenario, tss, bus)
    if !haskey(s,"income_summary");s["income_summary"]=Dict();end
    if !haskey(s["income_summary"],"strg");s["income_summary"]["strg"]=Dict();end
    if !haskey(s["income_summary"]["strg"],scenario);s["income_summary"]["strg"][scenario]=Dict();end

    hl=1#s["hours_length"]
    yl=1#s["years_length"]
    sl=s["scenarios_length"]
    me2e=1#1000000
    hourly_income=Dict();push!(hourly_income,"price"=>[]);push!(hourly_income,"income"=>[]);push!(hourly_income,"power"=>[]);push!(hourly_income,"hour"=>[]);
    for (n,nw) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"]), by=x->parse(Int64,x));
        if (issubset([string(n)],tss))
            b=nw["bus"][bus];
            strg=nw["storage"][bus];

            push!(hourly_income["power"],strg["ps"]);
            push!(hourly_income["price"],b["lam_kcl_r"]);
            push!(hourly_income["income"],strg["ps"]*b["lam_kcl_r"]*hl*yl*sl*me2e);
            push!(hourly_income["hour"],n);
    end;end
    hourly_income["life_income"]=sum(hourly_income["income"])
    hourly_income["life_power"]=sum(hourly_income["power"])
    s["income_summary"]["strg"][scenario][bus]=hourly_income
    return s
end
      


function SocialWelfare_zonal(s, result_mip, mn_data, data, result_mip_hm_prices)#NOTE CHANGED
    
    function undo_npv_hourly(x,current_yr)
        cost = x*(1+s["dr"])^(current_yr-base_year)# npv
        return deepcopy(cost)
    end

    function undo_hourly_scaling(cost0)
        cost=cost0*((hl*yl)/(8760*s["scenario_planning_horizon"]))*e2me
        return deepcopy(cost)
    end
    e2me=1000000/result_mip["solution"]["nw"]["1"]["baseMVA"]
    base_year=parse(Int64,s["scenario_years"][1])
    sl=s["scenarios_length"]
    yl=s["years_length"]
    hl=s["hours_length"]

    social_welfare=Dict();
    for k in keys(mn_data["scenario"]);push!(social_welfare,k=>Dict("re_dispatch_cost"=>Dict(),"gross_consumer_surplus"=>Dict(),"available_demand"=>Dict(),"consumed"=>Dict(),"gen_revenue"=>Dict(),"con_expenditure"=>Dict(),"produced"=>Dict(),"price"=>Dict()));end
    for (k_sc,sc) in social_welfare;
        for n in s["onshore_nodes"];
            push!(sc["produced"],string(n)=>0.0);
            push!(sc["gross_consumer_surplus"],string(n)=>0.0);
            push!(sc["available_demand"],string(n)=>0.0);
            push!(sc["gen_revenue"],string(n)=>0.0);
            push!(sc["con_expenditure"],string(n)=>0.0);
            push!(sc["consumed"],string(n)=>0.0);
            push!(sc["price"],string(n)=>0.0);
            push!(sc["re_dispatch_cost"],string(n)=>0.0);end;
            
        for n in s["offshore_nodes"];
            push!(sc["produced"],string(n)=>0.0);
            push!(sc["gross_consumer_surplus"],string(n)=>0.0);
            push!(sc["available_demand"],string(n)=>0.0);
            push!(sc["gen_revenue"],string(n)=>0.0);
            push!(sc["con_expenditure"],string(n)=>0.0);
            push!(sc["consumed"],string(n)=>0.0);
            push!(sc["price"],string(n)=>0.0);
            push!(sc["re_dispatch_cost"],string(n)=>0.0);end;end
    for (k_sc,tss) in sort(OrderedCollections.OrderedDict(mn_data["scenario"]), by=x->parse(Int64,x));
        for (k_ts,ts) in sort(OrderedCollections.OrderedDict(tss), by=x->parse(Int64,x));
            ts_str=string(ts)
            for (g,gen) in result_mip["solution"]["nw"][ts_str]["gen"];
                gen_bus=string(data["gen"][g]["gen_bus"])
                if (gen["pg"]<0)
                    cost_npv=deepcopy(result_mip["solution"]["nw"][ts_str]["bus"][gen_bus]["lam_kcl_r"])*sl
                    social_welfare[k_sc]["con_expenditure"][gen_bus]=social_welfare[k_sc]["con_expenditure"][gen_bus]+gen["pg"]*cost_npv
                    demand_cost_npv=deepcopy(s["xd"]["gen"][g]["cost"][ts][1])*-1
                    social_welfare[k_sc]["available_demand"][gen_bus]=social_welfare[k_sc]["available_demand"][gen_bus]+gen["pg"]*demand_cost_npv
                    social_welfare[k_sc]["consumed"][gen_bus]=social_welfare[k_sc]["consumed"][gen_bus]+gen["pg"]
                    social_welfare[k_sc]["gross_consumer_surplus"][gen_bus]=social_welfare[k_sc]["available_demand"][gen_bus]-social_welfare[k_sc]["con_expenditure"][gen_bus]
                else
                    cost_npv=deepcopy(result_mip["solution"]["nw"][ts_str]["bus"][gen_bus]["lam_kcl_r"])*-1*sl
                    #println("bus "*string(gen_bus)*" costs "*string(cost_npv))
                    gen_cost_npv=deepcopy(s["xd"]["gen"][g]["cost"][ts][1])
                    #println("gen "*string(g)*" ts "*string(ts)*" costs "*string(gen_cost_npv))
                    social_welfare[k_sc]["gen_revenue"][gen_bus]=social_welfare[k_sc]["gen_revenue"][gen_bus]+gen["pg"]*cost_npv
                    social_welfare[k_sc]["produced"][gen_bus]=social_welfare[k_sc]["produced"][gen_bus]+gen["pg"]

                    #cost of rebalancing
                    pre_balance_pg=result_mip_hm_prices["solution"]["nw"][ts_str]["gen"][g]["pg"]
                    if (gen["pg"]>pre_balance_pg+1e-10)
                        social_welfare[k_sc]["re_dispatch_cost"][gen_bus]=social_welfare[k_sc]["re_dispatch_cost"][gen_bus]+(gen["pg"]-pre_balance_pg)*(gen_cost_npv);
                    elseif (gen["pg"]<pre_balance_pg-1e-10) 
                        social_welfare[k_sc]["re_dispatch_cost"][gen_bus]=social_welfare[k_sc]["re_dispatch_cost"][gen_bus]+(pre_balance_pg-gen["pg"])*(cost_npv-gen_cost_npv);
                    end;
                end
            end

            for (gen_bus,bus) in result_mip["solution"]["nw"][ts_str]["bus"];
                _sc=floor(Int64,(ts-1)/(yl*hl))
                _yr=ceil(Int64,(ts-_sc*(yl*hl))/(hl))
                cost_npv=bus["lam_kcl_r"]*sl
                cost_base=undo_npv_hourly(cost_npv,parse(Int64,s["scenario_years"][_yr]))
                cost_base=undo_hourly_scaling(cost_base)*-1
                social_welfare[k_sc]["price"][gen_bus]=social_welfare[k_sc]["price"][gen_bus]+cost_base/(yl*hl)
            end
        end
    end
    totals=Dict();totals["all"]=Dict();
    for (k_sc,sc) in social_welfare;
        if !(haskey(totals,k_sc));push!(totals,k_sc=>Dict());end
        for (k_type, type) in sc
            if !(haskey(totals[k_sc],k_type));push!(totals[k_sc],k_type=>0.0);end
            if !(haskey(totals["all"],k_type));push!(totals["all"],k_type=>0.0);end
            for (b_k,b) in type
                if !(haskey(totals["all"],b_k));push!(totals["all"],b_k=>Dict());end
                if !(haskey(totals["all"][b_k],k_type));push!(totals["all"][b_k],k_type=>0.0);end
                totals["all"][k_type]=totals["all"][k_type]+(b)/sl
                totals["all"][b_k][k_type]=totals["all"][b_k][k_type]+(b)/sl
                totals[k_sc][k_type]=totals[k_sc][k_type]+b
            end
        end
    end
    push!(social_welfare,"totals"=>totals)
    return social_welfare
end


function SocialWelfare(s, result_mip, mn_data, data)#NOTE CHANGED
    
    function undo_npv_hourly(x,current_yr)
        cost = x*(1+s["dr"])^(current_yr-base_year)# npv
        return deepcopy(cost)
    end

    function undo_hourly_scaling(cost0)
        cost=cost0*((hl*yl)/(8760*s["scenario_planning_horizon"]))*e2me
        return deepcopy(cost)
    end
    e2me=1000000/result_mip["solution"]["nw"]["1"]["baseMVA"]
    base_year=parse(Int64,s["scenario_years"][1])
    sl=s["scenarios_length"]
    yl=s["years_length"]
    hl=s["hours_length"]

    social_welfare=Dict();
    for k in keys(mn_data["scenario"]);push!(social_welfare,k=>Dict("re_dispatch_cost"=>Dict(),"gross_consumer_surplus"=>Dict(),"available_demand"=>Dict(),"consumed"=>Dict(),"gen_revenue"=>Dict(),"con_expenditure"=>Dict(),"produced"=>Dict(),"price"=>Dict()));end
    for (k_sc,sc) in social_welfare;
        for n in s["onshore_nodes"];
            push!(sc["produced"],string(n)=>0.0);
            push!(sc["gross_consumer_surplus"],string(n)=>0.0);
            push!(sc["available_demand"],string(n)=>0.0);
            push!(sc["gen_revenue"],string(n)=>0.0);
            push!(sc["con_expenditure"],string(n)=>0.0);
            push!(sc["consumed"],string(n)=>0.0);
            push!(sc["price"],string(n)=>0.0);
            push!(sc["re_dispatch_cost"],string(n)=>0.0);end;
            
        for n in s["offshore_nodes"];
            push!(sc["produced"],string(n)=>0.0);
            push!(sc["gross_consumer_surplus"],string(n)=>0.0);
            push!(sc["available_demand"],string(n)=>0.0);
            push!(sc["gen_revenue"],string(n)=>0.0);
            push!(sc["con_expenditure"],string(n)=>0.0);
            push!(sc["consumed"],string(n)=>0.0);
            push!(sc["price"],string(n)=>0.0);
            push!(sc["re_dispatch_cost"],string(n)=>0.0);end;end
    for (k_sc,tss) in sort(OrderedCollections.OrderedDict(mn_data["scenario"]), by=x->parse(Int64,x));
        for (k_ts,ts) in sort(OrderedCollections.OrderedDict(tss), by=x->parse(Int64,x));
            ts_str=string(ts)
            for (g,gen) in result_mip["solution"]["nw"][ts_str]["gen"];
                gen_bus=string(data["gen"][g]["gen_bus"])
                if (gen["pg"]<0)
                    cost_npv=deepcopy(result_mip["solution"]["nw"][ts_str]["bus"][gen_bus]["lam_kcl_r"])*sl
                    social_welfare[k_sc]["con_expenditure"][gen_bus]=social_welfare[k_sc]["con_expenditure"][gen_bus]+gen["pg"]*cost_npv
                    demand_cost_npv=deepcopy(s["xd"]["gen"][g]["cost"][ts][1])*-1
                    social_welfare[k_sc]["available_demand"][gen_bus]=social_welfare[k_sc]["available_demand"][gen_bus]+gen["pg"]*demand_cost_npv
                    social_welfare[k_sc]["consumed"][gen_bus]=social_welfare[k_sc]["consumed"][gen_bus]+gen["pg"]
                    social_welfare[k_sc]["gross_consumer_surplus"][gen_bus]=social_welfare[k_sc]["available_demand"][gen_bus]-social_welfare[k_sc]["con_expenditure"][gen_bus]
                else
                    cost_npv=deepcopy(result_mip["solution"]["nw"][ts_str]["bus"][gen_bus]["lam_kcl_r"])*-1*sl
                    gen_cost_npv=deepcopy(s["xd"]["gen"][g]["cost"][ts][1])
                    social_welfare[k_sc]["gen_revenue"][gen_bus]=social_welfare[k_sc]["gen_revenue"][gen_bus]+gen["pg"]*cost_npv
                    social_welfare[k_sc]["produced"][gen_bus]=social_welfare[k_sc]["produced"][gen_bus]+gen["pg"]
                end
            end

            for (gen_bus,bus) in result_mip["solution"]["nw"][ts_str]["bus"];
                _sc=floor(Int64,(ts-1)/(yl*hl))
                _yr=ceil(Int64,(ts-_sc*(yl*hl))/(hl))
                cost_npv=bus["lam_kcl_r"]*sl
                cost_base=undo_npv_hourly(cost_npv,parse(Int64,s["scenario_years"][_yr]))
                cost_base=undo_hourly_scaling(cost_base)*-1
                social_welfare[k_sc]["price"][gen_bus]=social_welfare[k_sc]["price"][gen_bus]+cost_base/(yl*hl)
            end
        end
    end
    totals=Dict();totals["all"]=Dict();
    for (k_sc,sc) in social_welfare;
        if !(haskey(totals,k_sc));push!(totals,k_sc=>Dict());end
        for (k_type, type) in sc
            if !(haskey(totals[k_sc],k_type));push!(totals[k_sc],k_type=>0.0);end
            if !(haskey(totals["all"],k_type));push!(totals["all"],k_type=>0.0);end
            for (b_k,b) in type
                if !(haskey(totals["all"],b_k));push!(totals["all"],b_k=>Dict());end
                if !(haskey(totals["all"][b_k],k_type));push!(totals["all"][b_k],k_type=>0.0);end
                totals["all"][k_type]=totals["all"][k_type]+(b)/sl
                totals["all"][b_k][k_type]=totals["all"][b_k][k_type]+(b)/sl
                totals[k_sc][k_type]=totals[k_sc][k_type]+b
            end
        end
    end
    push!(social_welfare,"totals"=>totals)
    return social_welfare
end


function print_table_summary(s)
    println("transmission CAPEX: "*string(s["cost_summary"]["transmission"])*", Revenue: "*string(s["income_summary"]["tso"]["totals"]["total"]))
    println("OWPP CAPEX: "*string(s["cost_summary"]["owpp"]["all"])*", Revenue: "*string(s["income_summary"]["owpp"]["all"]["income"]))
    println("Strg CAPEX: "*string(s["cost_summary"]["storage"]["all"])*", Revenue: "*string(s["income_summary"]["strg"]["all"]["income"]))
    println("Gross consumer surplus: "*string(s["social_welfare"]["totals"]["all"]["gross_consumer_surplus"]))
    println("Average Energy Price: "*string(s["social_welfare"]["totals"]["all"]["price"]))
    println("OWPP Power: "*string(s["income_summary"]["owpp"]["all"]["power"]*(8760/s["hours_length"])))
    for (n,dic) in s["social_welfare"]["totals"]["all"]
        if (typeof(dic)==typeof(Dict()))
            println("Average Energy Price "*n*": "*string(dic["price"]))
        end
    end
    println("Redispatch cost: "*string(s["social_welfare"]["totals"]["all"]["re_dispatch_cost"]))
end
#results=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\UK_DE_DK\\zonal_results_hm14_VOLL5000_rc.jld2")

function summarize_zonal_in_s(results)#NOTE CHANGED
    s=results["s"];result_mip=results["result_mip"];data=results["data"];mn_data=results["mn_data"]
    result_mip_hm_prices=results["result_mip_hm_prices"]
    s= owpps_profit_obz(s, result_mip, mn_data)
    s= transmission_lines_profits(s, result_mip, mn_data, data);
    s= undo_marginal_price_scaling(s,result_mip)
    s["gen_consume_summary"]= summarize_generator_solution_data(result_mip, data,s)#print solution
    s["social_welfare"] = SocialWelfare_zonal(s, result_mip, mn_data, data, result_mip_hm_prices)
    s=tl_totals(s,data)
    s=strg_profit_obzs(s, result_mip, mn_data)
    return s, result_mip, data, mn_data
end

function summarize_in_s(results)
    s=results["s"];result_mip=results["result_mip"];data=results["data"];mn_data=results["mn_data"]
    s= owpps_profit_obz(s, result_mip, mn_data)
    s= transmission_lines_profits(s, result_mip, mn_data, data);
    s= undo_marginal_price_scaling(s,result_mip)
    println("gen_consume_summary")
    s["gen_consume_summary"]= summarize_generator_solution_data(result_mip, data,s)#print solution
    println("social_welfare")
    s["social_welfare"] = SocialWelfare(s, result_mip, mn_data, data)
    s=tl_totals(s,data)
    s=strg_profit_obzs(s, result_mip, mn_data)
    return s, result_mip, data, mn_data
end


function transmission_lines_profits(s, result_mip, mn_data, data)
    for (scenario_num,scenario) in mn_data["scenario"]
        tss=string.(values(scenario))
        s=transmission_line_profits(s, result_mip, scenario_num, tss, data)
    end
    return s
end

function transmission_line_profits(s, result_mip,scenario, tss, data)
    hl=1#s["hours_length"]
    yl=1#s["years_length"]
    sl=s["scenarios_length"]
    me2e=1#1000000
    cvs=data["convdc"]
    hourly_income=Dict();push!(hourly_income,"hour"=>[]);push!(hourly_income,"ac"=>Dict());push!(hourly_income,"dc"=>Dict());
    for (n,nw) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"]), by=x->parse(Int64,x));
        if (issubset([string(n)],tss))
            push!(hourly_income["hour"],n)
            bs=nw["bus"];
            brs_dc=nw["branchdc"];
            brs=nw["branch"];
            for (k_br,br_dc) in brs_dc
                if (result_mip["solution"]["nw"][string(maximum(parse.(Int64,tss)))]["branchdc"][k_br]["p_rateA"]>0)
                if !(haskey(hourly_income["dc"],k_br));
                    push!(hourly_income["dc"],k_br=>Dict());push!(hourly_income["dc"][k_br],"delta_price"=>[]);push!(hourly_income["dc"][k_br],"rent"=>[]);push!(hourly_income["dc"][k_br],"power"=>[]);end
           # println(data["branchdc"][k_br]["fbusdc"])
           # println(data["branchdc"][k_br]["tbusdc"])
            fbusac_i=0
            tbusac_i=0
            for (k_cv,cv) in cvs
                if (cv["busdc_i"]==data["branchdc"][k_br]["fbusdc"]) 
                    #println(string(data["branchdc"][k_br]["fbusdc"])*" => "*string(cv["busac_i"]))
                    fbusac_i=string(cv["busac_i"])
                end
                if (cv["busdc_i"]==data["branchdc"][k_br]["tbusdc"]) 
                    #println(string(data["branchdc"][k_br]["tbusdc"])*" => "*string(cv["busac_i"]))
                    tbusac_i=string(cv["busac_i"])
                end
            end
            push!(hourly_income["dc"][k_br]["power"],br_dc["pt"]);
            push!(hourly_income["dc"][k_br]["delta_price"],(bs[fbusac_i]["lam_kcl_r"]-bs[tbusac_i]["lam_kcl_r"])*-hl*yl*sl*me2e);
            push!(hourly_income["dc"][k_br]["rent"],hourly_income["dc"][k_br]["power"][end]*hourly_income["dc"][k_br]["delta_price"][end]);
                end;end
            for (k_br,br_ac) in brs
                if (result_mip["solution"]["nw"][string(maximum(parse.(Int64,tss)))]["branch"][k_br]["p_rateAC"]>0)
                if !(haskey(hourly_income["ac"],k_br));
                    push!(hourly_income["ac"],k_br=>Dict());push!(hourly_income["ac"][k_br],"delta_price"=>[]);push!(hourly_income["ac"][k_br],"rent"=>[]);push!(hourly_income["ac"][k_br],"power"=>[]);end

            push!(hourly_income["ac"][k_br]["power"],br_ac["pt"]);
            push!(hourly_income["ac"][k_br]["delta_price"],(bs[string(data["branch"][k_br]["f_bus"])]["lam_kcl_r"]-bs[string(data["branch"][k_br]["t_bus"])]["lam_kcl_r"])*-hl*yl*sl*me2e);
            push!(hourly_income["ac"][k_br]["rent"],hourly_income["ac"][k_br]["power"][end]*hourly_income["ac"][k_br]["delta_price"][end]);
                end;end
    end;end
    if !(haskey(s["income_summary"],"tso"));push!(s["income_summary"],"tso"=>Dict());end
    #println(scenario)
    push!(s["income_summary"]["tso"],scenario=>hourly_income)
    return s
end

function undo_marginal_price_scaling(s,result_mip)
    function undo_npv_hourly(x,current_yr)
        cost = (1+s["dr"])^(current_yr-base_year) * x# npv
        return deepcopy(cost)
    end

    function undo_hourly_scaling(cost0)
        cost=cost0*((hl*yl)/(8760*s["scenario_planning_horizon"]))*e2me
        return deepcopy(cost)
    end
    e2me=1000000/result_mip["solution"]["nw"]["1"]["baseMVA"]
    base_year=parse(Int64,s["scenario_years"][1])
    sl=s["scenarios_length"]
    yl=s["years_length"]
    hl=s["hours_length"]
    for (n,nw) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"]), by=x->parse(Int64,x));
        for (b,bs) in nw["bus"];
            _sc=floor(Int64,(parse(Int64,n)-1)/(yl*hl))
            _yr=ceil(Int64,(parse(Int64,n)-_sc*(yl*hl))/(hl))
            #bs["lam_kcl_r"]=undo_npv_hourly(bs["lam_kcl_r"],parse(Int64,s["scenario_years"][_yr]))
            #bs["lam_kcl_r"]=undo_hourly_scaling(bs["lam_kcl_r"])*-1*sl
            if (issubset([parse(Int64,b)],s["offshore_nodes"]))
                if !(haskey(s["income_summary"]["owpp"][string(_sc+1)][b],"price_not_npv"));push!(s["income_summary"]["owpp"][string(_sc+1)][b],"price_not_npv"=>[]);end
                lam_kcl_r=undo_npv_hourly(bs["lam_kcl_r"],parse(Int64,s["scenario_years"][_yr]))
                push!(s["income_summary"]["owpp"][string(_sc+1)][b]["price_not_npv"],undo_hourly_scaling(lam_kcl_r)*-1*sl)
            elseif (issubset([parse(Int64,b)],s["onshore_nodes"]))
                if !(haskey(s["income_summary"],"onshore"));push!(s["income_summary"],"onshore"=>Dict());end
                if !(haskey(s["income_summary"]["onshore"],string(_sc+1)));push!(s["income_summary"]["onshore"],string(_sc+1)=>Dict());end
                if !(haskey(s["income_summary"]["onshore"][string(_sc+1)],b));push!(s["income_summary"]["onshore"][string(_sc+1)],b=>Dict());end
                if !(haskey(s["income_summary"]["onshore"][string(_sc+1)][b],"price_not_npv"));push!(s["income_summary"]["onshore"][string(_sc+1)][b],"price_not_npv"=>[]);end
                lam_kcl_r=undo_npv_hourly(bs["lam_kcl_r"],parse(Int64,s["scenario_years"][_yr]))
                push!(s["income_summary"]["onshore"][string(_sc+1)][b]["price_not_npv"],undo_hourly_scaling(lam_kcl_r)*-1*sl)
            end
        end
    end
    return s
end


function summarize_generator_solution_data(result_mip, data,s)#print solution
	gen_tbls=build_generator_tables(result_mip, data)
	gen_by_market=sort_by_country(gen_tbls,s)
	gen_by_offshore=sort_by_offshore(gen_tbls,s)
	load_by_market=sort_load_by_country(gen_tbls,s["map_gen_types"])
	gen_consume=Dict()
	push!(gen_consume,"onshore_generation"=>gen_by_market)
	push!(gen_consume,"offshore_generation"=>gen_by_offshore)
	push!(gen_consume,"onshore_demand"=>load_by_market)
	return gen_consume
end

function sort_load_by_country(gen_tbls,map_gen_types)
	per_market=Dict()
	for (s,sc) in gen_tbls
		if !(haskey(per_market,s));push!(per_market,s=>Dict());end
		col_names=names(sc)
		for (cuntree,gens) in map_gen_types["loads"]
			for gen in gens
			if !(haskey(per_market[s],cuntree));push!(per_market[s],cuntree=>DataFrames.DataFrame(Symbol(col_names[1])=>sc[!,Symbol(col_names[1])]));end
				col_num=findfirst(x->x==string(gen),col_names)
				if !(isnothing(col_num))
				per_market[s][cuntree]=hcat(per_market[s][cuntree],DataFrames.DataFrame(Symbol(col_names[col_num])=>sc[!,Symbol(col_names[col_num])]))
			end;end
		end
	end

	return per_market
end

function sort_by_offshore(gen_tbls,set)
	per_market=Dict()
	for (s,sc) in gen_tbls
		if !(haskey(per_market,s));push!(per_market,s=>Dict());end
		col_names=names(sc)
		for (cuntree,gens) in set["map_gen_types"]["offshore"]
			for gen in gens
			if !(haskey(per_market[s],cuntree));push!(per_market[s],cuntree=>DataFrames.DataFrame(Symbol(col_names[1])=>sc[!,Symbol(col_names[1])]));end
				col_num=findfirst(x->x==gen,col_names)
				if !(isnothing(col_num))
				per_market[s][cuntree]=hcat(per_market[s][cuntree],DataFrames.DataFrame(Symbol("Offshore Wind")=>sc[!,Symbol(col_names[col_num])]))
			end;end
		end

		for cuntree_num in set["offshore_nodes"]
			cuntree=set["map_gen_types"]["markets"][2][cuntree_num-length(set["onshore_nodes"])]
			if !(haskey(per_market[s],cuntree));push!(per_market[s],cuntree=>DataFrames.DataFrame(Symbol(col_names[1])=>sc[!,Symbol(col_names[1])]));end
			per_market[s][cuntree]=hcat(per_market[s][cuntree],DataFrames.DataFrame(Symbol("Battery")=>sc[!,Symbol("Battery "*string(cuntree_num))]))
		end
	end
	return per_market
end

function sort_by_country(gen_tbls,set)
	per_market=Dict()
	for (s,sc) in gen_tbls
		if !(haskey(per_market,s));push!(per_market,s=>Dict());end
		col_names=names(sc)
		for (cuntree,gens) in set["map_gen_types"]["countries"]
			for gen in gens
			if !(haskey(per_market[s],cuntree));push!(per_market[s],cuntree=>DataFrames.DataFrame(Symbol(col_names[1])=>sc[!,Symbol(col_names[1])]));end
				col_num=findfirst(x->x==gen,col_names)
				if !(isnothing(col_num))
				per_market[s][cuntree]=hcat(per_market[s][cuntree],DataFrames.DataFrame(Symbol(col_names[col_num])=>sc[!,Symbol(col_names[col_num])]))
			end;end
			for (num,type) in set["map_gen_types"]["type"];
				cunt_col_names=names(per_market[s][cuntree])
				location=findfirst(x->x==num,cunt_col_names)
				if !(isnothing(location))
					DataFrames.rename!(per_market[s][cuntree], cunt_col_names[location]=>type)
				end
			end
		end
		for cuntree_num in set["onshore_nodes"]
			cuntree=set["map_gen_types"]["markets"][1][cuntree_num]
			if !(haskey(per_market[s],cuntree));push!(per_market[s],cuntree=>DataFrames.DataFrame(Symbol(col_names[1])=>sc[!,Symbol(col_names[1])]));end
				per_market[s][cuntree]=hcat(per_market[s][cuntree],DataFrames.DataFrame(Symbol("Battery")=>sc[!,Symbol("Battery "*string(cuntree_num))]),makeunique=true)
		end
	end
	return per_market
end

function build_generator_tables(result_mip, data)
	gen_per_scenario=Dict{}()
	for (s,sc) in data["scenario"]
		titles=["ts"]
		for (g,gen) in sort!(OrderedCollections.OrderedDict(result_mip["solution"]["nw"]["1"]["gen"]), by=x->parse(Int64,x));push!(titles,string(g));end
		for (s,bat) in sort!(OrderedCollections.OrderedDict(result_mip["solution"]["nw"]["1"]["storage"]), by=x->parse(Int64,x));push!(titles,"Battery "*string(s));end
		for (cts,ts) in sort!(OrderedCollections.OrderedDict(sc), by=x->parse(Int64,x))
			ts_row=[];push!(ts_row,ts)
			for (g,gen) in sort!(OrderedCollections.OrderedDict(result_mip["solution"]["nw"][string(ts)]["gen"]), by=x->parse(Int64,x))
				push!(ts_row,gen["pg"])
			end
			for (s,bat) in sort!(OrderedCollections.OrderedDict(result_mip["solution"]["nw"][string(ts)]["storage"]), by=x->parse(Int64,x))
				push!(ts_row,-1*bat["ps"])
			end
			titles=hcat(titles,ts_row)
		end

		namelist = Symbol.(titles[1:end,1])
		df  = DataFrames.DataFrame()
		for (i, name) in enumerate(namelist)
    	df[!,name] =  [titles[i,j] for j in 2:length(titles[i,:])];end
		push!(gen_per_scenario,s=>df)
	end
	return gen_per_scenario
end
################################################# tabulating solution ####################################################
function print_solution_wcost_data(result_mip, argz, data)
    #result_mip["solution"]["nw"]=VOLL_clearing_price(result_mip["solution"]["nw"],argz)
    costs=Dict();insert=DataFrames.DataFrame(:from=>[],:to=>[],:mva=>[]);#template=Dict("ac"=>deepcopy(insert),"dc"=>deepcopy(insert))
    argz["topology"]=Dict("t0"=>Dict(),"t2"=>Dict(),"tinf"=>Dict())
    push!(argz["topology"]["t0"],"ac"=>deepcopy(insert));push!(argz["topology"]["t2"],"ac"=>deepcopy(insert));push!(argz["topology"]["tinf"],"ac"=>deepcopy(insert))
    push!(argz["topology"]["t0"],"dc"=>deepcopy(insert));push!(argz["topology"]["t2"],"dc"=>deepcopy(insert));push!(argz["topology"]["tinf"],"dc"=>deepcopy(insert))

    println("Description: test-"*string(argz["test"])*" k-"*string(argz["k"])*" years-"*string(argz["scenario_years"])*" scenarios-"*string(argz["scenario_names"]))
    if (haskey(result_mip["solution"]["nw"]["1"],"branch"))
        println("%%%%%%% CONVEX SOLUTION %%%%%%%")
        push!(costs,"branch"=>print_branch(result_mip,argz,data))
        push!(costs,"branchdc"=>print_branchdc(result_mip,argz,data))
    else
        println("%%%%%%% MIP SOLUTION %%%%%%%")
        print_branch_ne(result_mip,argz,data)
        print_branchdc_ne(result_mip,argz,data)
    end
    push!(costs,"owpp"=>print_owpps(result_mip,argz, data))
    push!(costs,"converters"=>print_converters(result_mip,argz,data))
    push!(costs,"storage"=>print_storage(result_mip,argz,data))
    println("objective: "*string(result_mip["objective"])*" achieved in: "*string(result_mip["solve_time"]))
    costs_temp=deepcopy(costs)
    costs["capex_all"]=sum(c["all"] for (k,c) in costs_temp)
    costs["capex_t0"]=sum(c["t0"]["all"] for (k,c) in costs_temp)
    costs["capex_t2"]=sum(c["t2"]["all"] for (k,c) in costs_temp)
    costs["capex_tinf"]=sum(c["tinf"]["all"] for (k,c) in costs_temp)
    costs["transmission"]=sum(c["all"] for (k,c) in costs_temp if (k != "storage" && k != "owpp"))
    argz["cost_summary"]=costs
end

function VOLL_clearing_price(rez,s, price_cap::Float64=180.0)
    #constants
    e2me=1000000/rez["1"]["baseMVA"]
    base_year=parse(Int64,s["scenario_years"][1])
    sl=s["scenarios_length"]
    yl=s["years_length"]
    hl=s["hours_length"]

    #undo NPV and scaling
    function undo_npv_hourly(x,current_yr)
        cost = (1+s["dr"])^(current_yr-base_year) * x# npv
        return deepcopy(cost)
    end
    
    function undo_hourly_scaling(cost0)
        cost=cost0*((hl*yl)/(8760*s["scenario_planning_horizon"]))*e2me
        return deepcopy(cost)
    end

    #undo NPV and scaling
    function npv_hourly(x,current_yr)
        cost = x/(1+s["dr"])^(current_yr-base_year)# npv
        return deepcopy(cost)
    end
    
    function hourly_scaling(cost0)
        cost=cost0/(((hl*yl)/(8760*s["scenario_planning_horizon"]))*e2me)
        return deepcopy(cost)
    end

    #new vars
    for (r_num,r) in rez
            _sc=floor(Int64,(parse(Int64,r_num)-1)/(yl*hl))
            _yr=ceil(Int64,(parse(Int64,r_num)-_sc*(yl*hl))/(hl))
            #store NPV cost at single time step
            for (b_num,b) in r["bus"]
                lam_kcl_r_NPV=b["lam_kcl_r"]*-1*sl
                lam_kcl_r_scaled=undo_npv_hourly(lam_kcl_r_NPV,parse(Int64,s["scenario_years"][_yr]))
                lam_kcl_r=undo_hourly_scaling(lam_kcl_r_scaled)
                if (lam_kcl_r>4500)
                    max_marginal=hourly_scaling(price_cap)
                    max_marginal_NPV=npv_hourly(max_marginal,parse(Int64,s["scenario_years"][_yr]))
                    max_marginal_NPV/(-1*sl)
                    println(r_num*" "*b_num*" "*string(b["lam_kcl_r"])*" "*string(lam_kcl_r)*" "*string(max_marginal_NPV/(-1*sl)))
                    rez[r_num]["bus"][b_num]["lam_kcl_r"]=deepcopy(max_marginal_NPV/(-1*sl))
                end
            end
        
    end
    return rez
end

function print_branch_ne(result_mip,argz,data_mip)
    if (haskey(result_mip["solution"]["nw"]["1"],"ne_branch"))
        println("%%%% Cables HVAC t0 %%%%")
        for (i,br) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"]["1"]["ne_branch"]), by=x->parse(Int64,x))
            if (br["built"]==1)
                println(string(i)*": "*string(data_mip["ne_branch"][i]["f_bus"])*" - "*string(data_mip["ne_branch"][i]["t_bus"])*" MVA: "*string(data_mip["ne_branch"][i]["rate_a"])*" cost: "*string(data_mip["ne_branch"][i]["construction_cost"]))
        end;end
        println("%%%% Cables HVAC t2 %%%%")
        for (i,br) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"][string(argz["hours_length"]+1)]["ne_branch"]), by=x->parse(Int64,x))
            if (br["built"]==1)
                println(string(i)*": "*string(data_mip["ne_branch"][i]["f_bus"])*" - "*string(data_mip["ne_branch"][i]["t_bus"])*" MVA: "*string(data_mip["ne_branch"][i]["rate_a"])*" cost: "*string(data_mip["ne_branch"][i]["construction_cost"]))
        end;end
        println("%%%% Cables HVAC tinf %%%%")
        for (i,br) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"][string(length(result_mip["solution"]["nw"]))]["ne_branch"]), by=x->parse(Int64,x))
            if (br["built"]==1)
                println(string(i)*": "*string(data_mip["ne_branch"][i]["f_bus"])*" - "*string(data_mip["ne_branch"][i]["t_bus"])*" MVA: "*string(data_mip["ne_branch"][i]["rate_a"])*" cost: "*string(data_mip["ne_branch"][i]["construction_cost"]))
        end;end
    end
end

function print_branchdc_ne(result_mip,argz,data_mip)
    if (haskey(result_mip["solution"]["nw"]["1"],"branchdc_ne"))
        println("%%%% Cables HVDC t0 %%%%")
        for (i,br) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"]["1"]["branchdc_ne"]), by=x->parse(Int64,x))
            if (br["isbuilt"]==1)
                println(string(i)*": "*string(data_mip["branchdc_ne"][i]["fbusdc"])*" - "*string(data_mip["branchdc_ne"][i]["tbusdc"])*" MVA: "*string(data_mip["branchdc_ne"][i]["rateA"])*" cost: "*string(data_mip["branchdc_ne"][i]["cost"]))
        end;end
        println("%%%% Cables HVDC t2 %%%%")
        for (i,br) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"][string(argz["hours_length"]+1)]["branchdc_ne"]), by=x->parse(Int64,x))
            if (br["isbuilt"]==1)
                println(string(i)*": "*string(data_mip["branchdc_ne"][i]["fbusdc"])*" - "*string(data_mip["branchdc_ne"][i]["tbusdc"])*" MVA: "*string(data_mip["branchdc_ne"][i]["rateA"])*" cost: "*string(data_mip["branchdc_ne"][i]["cost"]))
        end;end
        println("%%%% Cables HVDC tinf %%%%")
        for (i,br) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"][string(length(result_mip["solution"]["nw"]))]["branchdc_ne"]), by=x->parse(Int64,x))
            if (br["isbuilt"]==1)
                println(string(i)*": "*string(data_mip["branchdc_ne"][i]["fbusdc"])*" - "*string(data_mip["branchdc_ne"][i]["tbusdc"])*" MVA: "*string(data_mip["branchdc_ne"][i]["rateA"])*" cost: "*string(data_mip["branchdc_ne"][i]["cost"]))
        end;end
    end
end

function print_storage(result_mip,argz,data)
    storage_cost=Dict("all"=>0.0,"t0"=>Dict("all"=>0.0),"t2"=>Dict("all"=>0.0),"tinf"=>Dict("all"=>0.0));
    if (haskey(result_mip["solution"]["nw"]["1"],"storage"))
        println("%%%% Storage t0 %%%%")
        for (i,s) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"]["1"]["storage"]), by=x->parse(Int64,x))
#Equipment tabulation
            s_bus=string(data["storage"][string(i)]["storage_bus"])
            if !(haskey(argz["topology"]["t0"],s_bus));push!(argz["topology"]["t0"],s_bus=>Dict());end
            if !(haskey(argz["topology"]["t0"][s_bus],"strg"));push!(argz["topology"]["t0"][s_bus],"strg"=>s["e_absmax"]);end
#Cost tabulation
            cst=s["e_absmax"]*data["storage"][i]["cost"]
            if !(haskey(storage_cost["t0"],string(i)));push!(storage_cost["t0"],string(i)=>cst);end
            if !(haskey(storage_cost["t0"],"all"));push!(storage_cost["t0"],"all"=>cst);else;storage_cost["t0"]["all"]=storage_cost["t0"]["all"]+cst;end
            storage_cost["all"]=storage_cost["all"]+cst
            println(string(i)*": "*" MWh: "*string(s["e_absmax"])*" Cost: "*string(cst))
        end
        println("%%%% Storage t2 %%%%")
        for (i,s) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"][string(argz["hours_length"]+1)]["storage"]), by=x->parse(Int64,x))
#Equipment tabulation
            s_bus=string(data["storage"][string(i)]["storage_bus"])
            if !(haskey(argz["topology"]["t2"],s_bus));push!(argz["topology"]["t2"],s_bus=>Dict());end
            if !(haskey(argz["topology"]["t2"][s_bus],"strg"));push!(argz["topology"]["t2"][s_bus],"strg"=>s["e_absmax"]);end
#Cost tabulation
            cst=(s["e_absmax"]-result_mip["solution"]["nw"]["1"]["storage"][i]["e_absmax"])*data["storage"][i]["cost"]*2/3*(1/((1+argz["dr"])^(10)))
            if !(haskey(storage_cost["t2"],string(i)));push!(storage_cost["t2"],string(i)=>cst);end
            if !(haskey(storage_cost["t2"],"all"));push!(storage_cost["t2"],"all"=>cst);else;storage_cost["t2"]["all"]=storage_cost["t2"]["all"]+cst;end
            storage_cost["all"]=storage_cost["all"]+cst
                println(string(i)*": "*" MWh: "*string(s["e_absmax"])*" Cost: "*string(cst))
        end
        println("%%%% Storage tinf %%%%")
        for (i,s) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"][string(length(result_mip["solution"]["nw"]))]["storage"]), by=x->parse(Int64,x))
#Equipment tabulation
            s_bus=string(data["storage"][string(i)]["storage_bus"])
            if !(haskey(argz["topology"]["tinf"],s_bus));push!(argz["topology"]["tinf"],s_bus=>Dict());end
            if !(haskey(argz["topology"]["tinf"][s_bus],"strg"));push!(argz["topology"]["tinf"][s_bus],"strg"=>s["e_absmax"]);end
#Cost tabulation
            cst=(s["e_absmax"]-result_mip["solution"]["nw"][string(argz["hours_length"]+1)]["storage"][i]["e_absmax"])*data["storage"][i]["cost"]*1/3*(1/((1+argz["dr"])^(20)))
            if !(haskey(storage_cost["tinf"],string(i)));push!(storage_cost["tinf"],string(i)=>cst);end
            if !(haskey(storage_cost["tinf"],"all"));push!(storage_cost["tinf"],"all"=>cst);else;storage_cost["tinf"]["all"]=storage_cost["tinf"]["all"]+cst;end
            storage_cost["all"]=storage_cost["all"]+cst
            println(string(i)*": "*" MWh: "*string(s["e_absmax"])*" Cost: "*string(cst))
        end
    end
    return storage_cost
end

function print_converters(result_mip,argz,data)
    converter_cost=Dict("all"=>0.0,"t0"=>Dict("all"=>0.0),"t2"=>Dict("all"=>0.0),"tinf"=>Dict("all"=>0.0));
    if (haskey(result_mip["solution"]["nw"]["1"],"convdc"))
        println("%%%% Converters t0 %%%%")
        for (i,cv) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"]["1"]["convdc"]), by=x->parse(Int64,x))
#Equipment tabulation
            cv_bus=string(data["convdc"][string(i)]["busdc_i"])
            if !(haskey(argz["topology"]["t0"],cv_bus));push!(argz["topology"]["t0"],cv_bus=>Dict());end
            if !(haskey(argz["topology"]["t0"][cv_bus],"conv"));push!(argz["topology"]["t0"][cv_bus],"conv"=>cv["p_pacmax"]);end
#Cost tabulation
                cst=cv["p_pacmax"]*data["convdc"][i]["cost"]
                if !(haskey(converter_cost["t0"],string(i)));push!(converter_cost["t0"],string(i)=>cst);end
                if !(haskey(converter_cost["t0"],"all"));push!(converter_cost["t0"],"all"=>cst);else;converter_cost["t0"]["all"]=converter_cost["t0"]["all"]+cst;end
                converter_cost["all"]=converter_cost["all"]+cst
                println(string(i)*": "*string(cv["p_pacmax"])*" Cost: "*string(cst))
        end;
        println("%%%% Converters t2 %%%%")
        for (i,cv) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"][string(argz["hours_length"]+1)]["convdc"]), by=x->parse(Int64,x))
#Equipment tabulation
                cv_bus=string(data["convdc"][string(i)]["busdc_i"])
                if !(haskey(argz["topology"]["t2"],cv_bus));push!(argz["topology"]["t2"],cv_bus=>Dict());end
                if !(haskey(argz["topology"]["t2"][cv_bus],"conv"));push!(argz["topology"]["t2"][cv_bus],"conv"=>cv["p_pacmax"]);end
#Cost tabulation
                cst=(cv["p_pacmax"]-result_mip["solution"]["nw"]["1"]["convdc"][i]["p_pacmax"])*data["convdc"][i]["cost"]*2/3*(1/((1+argz["dr"])^(10)))
                if !(haskey(converter_cost["t2"],string(i)));push!(converter_cost["t2"],string(i)=>cst);end
                if !(haskey(converter_cost["t2"],"all"));push!(converter_cost["t2"],"all"=>cst);else;converter_cost["t2"]["all"]=converter_cost["t2"]["all"]+cst;end
                converter_cost["all"]=converter_cost["all"]+cst
                println(string(i)*": "*string(cv["p_pacmax"])*" Cost: "*string(cst))
        end;
        println("%%%% Converters tinf %%%%")
        for (i,cv) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"][string(length(result_mip["solution"]["nw"]))]["convdc"]), by=x->parse(Int64,x))
#Equipment tabulation
                cv_bus=string(data["convdc"][string(i)]["busdc_i"])
                if !(haskey(argz["topology"]["tinf"],cv_bus));push!(argz["topology"]["tinf"],cv_bus=>Dict());end
                if !(haskey(argz["topology"]["tinf"][cv_bus],"conv"));push!(argz["topology"]["tinf"][cv_bus],"conv"=>cv["p_pacmax"]);end
#Cost tabulation
                cst=(cv["p_pacmax"]-result_mip["solution"]["nw"][string(argz["hours_length"]+1)]["convdc"][i]["p_pacmax"])*data["convdc"][i]["cost"]*1/3*(1/((1+argz["dr"])^(20)))
                if !(haskey(converter_cost["tinf"],string(i)));push!(converter_cost["tinf"],string(i)=>cst);end
                if !(haskey(converter_cost["tinf"],"all"));push!(converter_cost["tinf"],"all"=>cst);else;converter_cost["tinf"]["all"]=converter_cost["tinf"]["all"]+cst;end
                converter_cost["all"]=converter_cost["all"]+cst
                println(string(i)*": "*string(cv["p_pacmax"])*" Cost: "*string(cst))
        end;
    end
    return converter_cost
end

function print_owpps(result_mip,argz,data)
    owpp_cost=Dict("totals"=>Dict(),"all"=>0.0,"t0"=>Dict("all"=>0.0),"t2"=>Dict("all"=>0.0),"tinf"=>Dict("all"=>0.0));
    if (haskey(result_mip["solution"]["nw"]["1"],"gen"))
        println("%%%% OWPPS T0 %%%%")
        for (i,wf) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"]["1"]["gen"]), by=x->parse(Int64,x))
            if (haskey(wf,"wf_pacmax"))
#Equipment tabulation
                wf_bus=string(data["gen"][string(i)]["gen_bus"])
                if !(haskey(argz["topology"]["t0"],wf_bus));push!(argz["topology"]["t0"],wf_bus=>Dict());end
                if !(haskey(argz["topology"]["t0"][wf_bus],"wf"));push!(argz["topology"]["t0"][wf_bus],"wf"=>wf["wf_pacmax"]);end
#Cost tabulation
                cst=wf["wf_pacmax"]*data["gen"][i]["invest"]
                if !(haskey(owpp_cost["totals"],string(i)));push!(owpp_cost["totals"],string(i)=>cst);else;owpp_cost["totals"][string(i)]=owpp_cost["totals"][string(i)]+cst;end
                if !(haskey(owpp_cost["t0"],string(i)));push!(owpp_cost["t0"],string(i)=>cst);end
                if !(haskey(owpp_cost["t0"],"all"));push!(owpp_cost["t0"],"all"=>cst);else;owpp_cost["t0"]["all"]=owpp_cost["t0"]["all"]+cst;end
                owpp_cost["all"]=owpp_cost["all"]+cst
                println(string(i)*": "*string(wf["wf_pacmax"])*" Cost: "*string(cst))
        end;end
        println("%%%% OWPPS T2 %%%%")
        for (i,wf) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"][string(argz["hours_length"]+1)]["gen"]), by=x->parse(Int64,x))
            if (haskey(wf,"wf_pacmax"))
#Equipment tabulation
                wf_bus=string(data["gen"][string(i)]["gen_bus"])
                if !(haskey(argz["topology"]["t2"],wf_bus));push!(argz["topology"]["t2"],wf_bus=>Dict());end
                if !(haskey(argz["topology"]["t2"][wf_bus],"wf"));push!(argz["topology"]["t2"][wf_bus],"wf"=>wf["wf_pacmax"]);end
#Cost tabulation
                cst=(wf["wf_pacmax"]-result_mip["solution"]["nw"]["1"]["gen"][i]["wf_pacmax"])*data["gen"][i]["invest"]*2/3*(1/((1+argz["dr"])^(10)))
                if !(haskey(owpp_cost["totals"],string(i)));push!(owpp_cost["totals"],string(i)=>cst);else;owpp_cost["totals"][string(i)]=owpp_cost["totals"][string(i)]+cst;end
                if !(haskey(owpp_cost["t2"],string(i)));push!(owpp_cost["t2"],string(i)=>cst);end
                if !(haskey(owpp_cost["t2"],"all"));push!(owpp_cost["t2"],"all"=>cst);else;owpp_cost["t2"]["all"]=owpp_cost["t2"]["all"]+cst;end
                owpp_cost["all"]=owpp_cost["all"]+cst
                println(string(i)*": "*string(wf["wf_pacmax"])*" Cost: "*string(cst))
        end;end
        println("%%%% OWPPS Tinf %%%%")
        for (i,wf) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"][string(length(result_mip["solution"]["nw"]))]["gen"]), by=x->parse(Int64,x))
            if (haskey(wf,"wf_pacmax"))
#Equipment tabulation
                wf_bus=string(data["gen"][string(i)]["gen_bus"])
                if !(haskey(argz["topology"]["tinf"],wf_bus));push!(argz["topology"]["tinf"],wf_bus=>Dict());end
                if !(haskey(argz["topology"]["tinf"][wf_bus],"wf"));push!(argz["topology"]["tinf"][wf_bus],"wf"=>wf["wf_pacmax"]);end
#Cost tabulation
                cst=(wf["wf_pacmax"]-result_mip["solution"]["nw"][string(argz["hours_length"]+1)]["gen"][i]["wf_pacmax"])*data["gen"][i]["invest"]*1/3*(1/((1+argz["dr"])^(20)))
                if !(haskey(owpp_cost["totals"],string(i)));push!(owpp_cost["totals"],string(i)=>cst);else;owpp_cost["totals"][string(i)]=owpp_cost["totals"][string(i)]+cst;end
                if !(haskey(owpp_cost["tinf"],string(i)));push!(owpp_cost["tinf"],string(i)=>cst);end
                if !(haskey(owpp_cost["tinf"],"all"));push!(owpp_cost["tinf"],"all"=>cst);else;owpp_cost["tinf"]["all"]=owpp_cost["tinf"]["all"]+cst;end
                owpp_cost["all"]=owpp_cost["all"]+cst
                println(string(i)*": "*string(wf["wf_pacmax"])*" Cost: "*string(cst))
        end;end
    end
    return owpp_cost
end

function print_branch(result_mip,argz,data)
    branch_cost=Dict("all"=>0.0,"t0"=>Dict("all"=>0.0),"t2"=>Dict("all"=>0.0),"tinf"=>Dict("all"=>0.0));
    if (haskey(result_mip["solution"]["nw"]["1"],"branch"))
        println("%%%% Cables HVAC t0 %%%%")
        for (i,br) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"]["1"]["branch"]), by=x->parse(Int64,x))
            if (br["p_rateAC"]>0)
            cst=br["p_rateAC"]*data["branch"][i]["cost"]
                if !(haskey(branch_cost["t0"],string(i)));push!(branch_cost["t0"],string(i)=>cst);end
                if !(haskey(branch_cost["t0"],"all"));push!(branch_cost["t0"],"all"=>cst);else;branch_cost["t0"]["all"]=branch_cost["t0"]["all"]+cst;end
                branch_cost["all"]=branch_cost["all"]+cst
            println(string(i)*": "*string(data["branch"][i]["f_bus"])*" - "*string(data["branch"][i]["t_bus"])*" MVA: "*string(br["p_rateAC"])*" Cost: "*string(cst))
            push!(argz["topology"]["t0"]["ac"],[data["branch"][i]["f_bus"],data["branch"][i]["t_bus"],br["p_rateAC"]])
        end;end
        println("%%%% Cables HVAC t2 %%%%")
        for (i,br) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"][string(argz["hours_length"]+1)]["branch"]), by=x->parse(Int64,x))
            if (br["p_rateAC"]>0)
            cst=((br["p_rateAC"]-result_mip["solution"]["nw"]["1"]["branch"][i]["p_rateAC"])*data["branch"][i]["cost"])*2/3*(1/((1+argz["dr"])^(10)))
                if !(haskey(branch_cost["t2"],string(i)));push!(branch_cost["t2"],string(i)=>cst);end
                if !(haskey(branch_cost["t2"],"all"));push!(branch_cost["t2"],"all"=>cst);else;branch_cost["t2"]["all"]=branch_cost["t2"]["all"]+cst;end
                branch_cost["all"]=branch_cost["all"]+cst
            println(string(i)*": "*string(data["branch"][i]["f_bus"])*" - "*string(data["branch"][i]["t_bus"])*" MVA: "*string(br["p_rateAC"])*" Cost: "*string(cst))
            push!(argz["topology"]["t2"]["ac"],[data["branch"][i]["f_bus"],data["branch"][i]["t_bus"],br["p_rateAC"]])
        end;end
        println("%%%% Cables HVAC tinf %%%%")
        for (i,br) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"][string(length(result_mip["solution"]["nw"]))]["branch"]), by=x->parse(Int64,x))
            if (br["p_rateAC"]>0)
            cst=((br["p_rateAC"]-result_mip["solution"]["nw"][string(argz["hours_length"]+1)]["branch"][i]["p_rateAC"])*data["branch"][i]["cost"])*1/3*(1/((1+argz["dr"])^(20)))
                if !(haskey(branch_cost["tinf"],string(i)));push!(branch_cost["tinf"],string(i)=>cst);end
                if !(haskey(branch_cost["tinf"],"all"));push!(branch_cost["tinf"],"all"=>cst);else;branch_cost["tinf"]["all"]=branch_cost["tinf"]["all"]+cst;end
                branch_cost["all"]=branch_cost["all"]+cst
            println(string(i)*": "*string(data["branch"][i]["f_bus"])*" - "*string(data["branch"][i]["t_bus"])*" MVA: "*string(br["p_rateAC"])*" Cost: "*string(cst))
            push!(argz["topology"]["tinf"]["ac"],[data["branch"][i]["f_bus"],data["branch"][i]["t_bus"],br["p_rateAC"]])
        end;end
    end
    return branch_cost
end



function print_branchdc(result_mip,argz,data)
    branch_cost=Dict("all"=>0.0,"t0"=>Dict("all"=>0.0),"t2"=>Dict("all"=>0.0),"tinf"=>Dict("all"=>0.0));
    if (haskey(result_mip["solution"]["nw"]["1"],"branchdc"))
        println("%%%% Cables HVDC t0 %%%%")
        for (i,br) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"]["1"]["branchdc"]), by=x->parse(Int64,x))
            if (br["p_rateA"]>0)
            cst=br["p_rateA"]*data["branchdc"][i]["cost"]
                if !(haskey(branch_cost["t0"],string(i)));push!(branch_cost["t0"],string(i)=>cst);end
                if !(haskey(branch_cost["t0"],"all"));push!(branch_cost["t0"],"all"=>cst);else;branch_cost["t0"]["all"]=branch_cost["t0"]["all"]+cst;end
                branch_cost["all"]=branch_cost["all"]+cst
            println(string(i)*": "*string(data["branchdc"][i]["fbusdc"])*" - "*string(data["branchdc"][i]["tbusdc"])*" MVA: "*string(br["p_rateA"])*" Cost: "*string(cst))
            push!(argz["topology"]["t0"]["dc"],[data["branchdc"][i]["fbusdc"],data["branchdc"][i]["tbusdc"],br["p_rateA"]])
        end;end
        println("%%%% Cables HVDC t2 %%%%")
        for (i,br) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"][string(argz["hours_length"]+1)]["branchdc"]), by=x->parse(Int64,x))
            if (br["p_rateA"]>0)
            cst=((br["p_rateA"]-result_mip["solution"]["nw"]["1"]["branchdc"][i]["p_rateA"])*data["branchdc"][i]["cost"])*2/3*(1/((1+argz["dr"])^(10)))
                if !(haskey(branch_cost["t2"],string(i)));push!(branch_cost["t2"],string(i)=>cst);end
                if !(haskey(branch_cost["t2"],"all"));push!(branch_cost["t2"],"all"=>cst);else;branch_cost["t2"]["all"]=branch_cost["t2"]["all"]+cst;end
                branch_cost["all"]=branch_cost["all"]+cst
            println(string(i)*": "*string(data["branchdc"][i]["fbusdc"])*" - "*string(data["branchdc"][i]["tbusdc"])*" MVA: "*string(br["p_rateA"])*" Cost: "*string(cst))
            push!(argz["topology"]["t2"]["dc"],[data["branchdc"][i]["fbusdc"],data["branchdc"][i]["tbusdc"],br["p_rateA"]])
        end;end
        println("%%%% Cables HVDC tinf %%%%")
        for (i,br) in sort(OrderedCollections.OrderedDict(result_mip["solution"]["nw"][string(length(result_mip["solution"]["nw"]))]["branchdc"]), by=x->parse(Int64,x))
            if (br["p_rateA"]>0)
            cst=((br["p_rateA"]-result_mip["solution"]["nw"][string(argz["hours_length"]+1)]["branchdc"][i]["p_rateA"])*data["branchdc"][i]["cost"])*1/3*(1/((1+argz["dr"])^(20)))
                if !(haskey(branch_cost["tinf"],string(i)));push!(branch_cost["tinf"],string(i)=>cst);end
                if !(haskey(branch_cost["tinf"],"all"));push!(branch_cost["tinf"],"all"=>cst);else;branch_cost["tinf"]["all"]=branch_cost["tinf"]["all"]+cst;end
                branch_cost["all"]=branch_cost["all"]+cst
            println(string(i)*": "*string(data["branchdc"][i]["fbusdc"])*" - "*string(data["branchdc"][i]["tbusdc"])*" MVA: "*string(br["p_rateA"])*" Cost: "*string(cst))
            push!(argz["topology"]["tinf"]["dc"],[data["branchdc"][i]["fbusdc"],data["branchdc"][i]["tbusdc"],br["p_rateA"]])
        end;end
    end
    return branch_cost
end

function plot_clearing_price(time_series)
    
    clrs=generation_color_map()
    

        #low_rng=minimum(marginal_prices)
        #high_rng=maximum(marginal_prices)
        scatter_vec_gen=[
            
            PlotlyJS.scatter(
                y=time_series,
                mode="lines", name="BE",
                line=PlotlyJS.attr(width=2, color="red")
            ) ]
        PlotlyJS.plot(
            scatter_vec_gen, PlotlyJS.Layout(font_size=35,xaxis_range=(0, 432),yaxis_title="€/MWh",xaxis_title="time steps"))
    end

############################## Addition as of 8/10/22 - for Hakan's "justify insanely high re-dispatch costs Q ##################

function rename_gen_df_columns(gen_types,df)
    col_names=Any[]
    for _number in names(df)
        if (sum(_number.==first.(gen_types))>0)
            push!(col_names,last(gen_types[parse(Int64,_number)]))
        else
            push!(col_names,_number)
        end
    end
    DataFrames.rename!(df,Symbol.(col_names),makeunique=true)
    return df
end
   

function gen_load_values(rez,v)
    df=DataFrames.DataFrame()
    rez=sort!(OrderedCollections.OrderedDict(rez), by=x->parse(Int64,x))
    for (k_nw,nw) in rez
        ks=keys(sort!(OrderedCollections.OrderedDict(nw["gen"]), by=x->parse(Int64,x)))
        vs=[nw["gen"][k][v] for k in ks]
        named_tuple = (; zip(Symbol.(ks), vs )...)
        push!(df,named_tuple);
    end
    return df
end

#returns a data frame with NPV/original costs at every generator and load
function bus_values(bus_df,rez,s)
    #constants
    e2me=1000000/rez["1"]["baseMVA"]
    base_year=parse(Int64,s["scenario_years"][1])
    sl=s["scenarios_length"]
    yl=s["years_length"]
    hl=s["hours_length"]

    #undo NPV and scaling
    function undo_npv_hourly(x,current_yr)
        cost = (1+s["dr"])^(current_yr-base_year) * x# npv
        return deepcopy(cost)
    end
    
    function undo_hourly_scaling(cost0)
        cost=cost0*((hl*yl)/(8760*s["scenario_planning_horizon"]))*e2me
        return deepcopy(cost)
    end

    #new vars
    df_NPV_scaled=DataFrames.DataFrame()
    df_scaled=DataFrames.DataFrame()
    df_orig=DataFrames.DataFrame()
    df_names=names(bus_df)
    for (r_num,r) in enumerate(eachrow(bus_df))
        vs_NPV_scaled=[]
        vs_scaled=[]
        vs_orig=[]
        for _name in df_names
            _sc=floor(Int64,(r_num-1)/(yl*hl))
            _yr=ceil(Int64,(r_num-_sc*(yl*hl))/(hl))
            #store NPV cost at single time step
            lam_kcl_r_NPV=rez[string(r_num)]["bus"][string(bus_df[!,_name][r_num])]["lam_kcl_r"]*-1*sl
            push!(vs_NPV_scaled,lam_kcl_r_NPV)
            #store scaled cost at single time step
            lam_kcl_r_scaled=undo_npv_hourly(lam_kcl_r_NPV,parse(Int64,s["scenario_years"][_yr]))
            push!(vs_scaled,lam_kcl_r_scaled)
            #store Original cost at single time step
            lam_kcl_r=undo_hourly_scaling(lam_kcl_r_scaled)
            push!(vs_orig,lam_kcl_r)
        end
        #store each row in overall data frame
        named_tuple = (; zip(Symbol.(df_names), vs_NPV_scaled )...)
        push!(df_NPV_scaled,named_tuple);
        named_tuple = (; zip(Symbol.(df_names), vs_scaled )...)
        push!(df_scaled,named_tuple);
        named_tuple = (; zip(Symbol.(df_names), vs_orig )...)
        push!(df_orig,named_tuple);
    end
    #cost_dict=Dict("NPV"=>df_NPV_scaled,"Scaled"=>df_scaled,"Orig"=>df_orig)
    cost_dict=Dict("NPV"=>df_NPV_scaled,"Orig"=>df_orig)
    return cost_dict
end


#_gens are the list of genrators - 1/column, _sims are symbols of final columns desired
function gen_bid_prices(_gens,_sims)
    df=DataFrames.DataFrame()
    for (_n,_gs) in sort!(OrderedCollections.OrderedDict(_gens), by=x->parse(Int64,x))
        df[!,Symbol(_n)]=first.(_gs["cost"])
    end    
    df=df[!,_sims]
    return df
end
#######################################################################
#######################################################################
#seperate re-dispatch into ramp-up and ramp down
#test_in=DataFrame(A=[3.07467,0.0,0.0], B=[0.0,0.0,-19.8817], C=[-3.07467,0.0,0.0])
#r_up, r_down=decompose_re_dispatch(test_in)
#r_up: 
#Row  │ A        B        C       
#       │ Float64  Float64  Float64 
# ─────┼───────────────────────────
#    1 │ 3.07467      0.0      0.0
#    2 │ 0.0          0.0      0.0
#    3 │ 0.0          0.0      0.0
#r_down:
#Row │ A        B        C       
#│ Float64  Float64  Float64 
#─────┼───────────────────────────
#1 │     0.0   0.0     3.07467
#2 │     0.0   0.0     0.0
#3 │     0.0  19.8817  0.0
function decompose_re_dispatch(_rd)
    r_up=(abs.(_rd).+_rd)./2
    r_down=abs.(_rd.-r_up)
    return r_up, r_down
end
#######################################################################
#######################################################################
#Return a Dtatframe with ID: initial dispatch, FD: Finial Dispatch, RD: Redispatch
#test_in=FileIO.load("C:\\Users\\shardy\\Documents\\julia\\times_series_input_large_files\\UK_DE_DK\\zonal_results_hm14_VOLL5000_rc.jld2")
#test_out=InitialD_FinalD_ReDispatch(test_in)
#test_out:
#Dict{String,DataFrame} with 3 entries:
#  "FD" => 2592×93 DataFrame…
#  "RD" => 2592×93 DataFrame…
#  "ID" => 2592×93 DataFrame…
#test_out["RD"][1:2,Symbol(8)]
#2-element Array{Float64,1}:
# 3.0746729621551054
# 0.0
function InitialD_FinalD_ReDispatch(results)
    #ID: initial dispatch, RD: re-dispatch, FD: final dispatch  
    dk_gen_load=Dict("ID"=>DataFrames.DataFrame(),"RD"=>DataFrames.DataFrame(),"FD"=>DataFrames.DataFrame())
    dk_gen_load["FD"]=gen_load_values(results["result_mip"]["solution"]["nw"],"pg")
    if haskey(results,"result_mip_hm_prices")
        dk_gen_load["ID"]=gen_load_values(results["result_mip_hm_prices"]["solution"]["nw"],"pg")
        dk_gen_load["RD"]=dk_gen_load["FD"].-dk_gen_load["ID"]
    end
    return dk_gen_load
end
