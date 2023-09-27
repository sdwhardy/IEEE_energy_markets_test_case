################################### Clustering ##################################
demand2050=(sum.(eachrow(scenario_data["Demand"]["DE2040"][!,Not(Symbol("time_stamp"))])).+sum.(eachrow(scenario_data["Demand"]["GA2040"][!,Not(Symbol("time_stamp"))])).+sum.(eachrow(scenario_data["Demand"]["NT2040"][!,Not(Symbol("time_stamp"))])))./3
demand2050=sum.(eachrow(scenario_data["Demand"]["DE2040"][!,Not(Symbol("time_stamp"))]))
res="Offshore Wind"
year="2014"
country="BE00"

net_res=scenario_data["Generation"]["RES"][res][country][year][!,Symbol(country)].*0
count=0
for res in ["Offshore Wind"]#keys(scenario_data["Generation"]["RES"])
    for country in keys(scenario_data["Generation"]["RES"][res])
        for year in ["2014"]
            if !(isempty(scenario_data["Generation"]["RES"][res][country]))
                count=count+1
                net_res=net_res+scenario_data["Generation"]["RES"][res][country][year][!,Symbol(country)]
            end
        end
    end
end
net_res=net_res/count

using Plots, Clustering, PlotlyJS

df=DataFrame("time_stamp"=>scenario_data["Generation"]["RES"][res][country][year][!,Symbol("time_stamp")],"res"=>net_res,"demand"=>demand2050,"ratio"=>demand2050./net_res)
X=vcat(df[!,:res]',df[!,:demand]')
R=kmeans(X,2;maxiter=200,display=:iter)

a=assignments(R)


every=Array{GenericTrace{Dict{Symbol,Any}},1}()
for t in 1:1:4
cluster_1 = PlotlyJS.scatter(;x=[df[!,:demand][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]>0.35)], y=[df[!,:res][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]>0.35)], mode="markers")#, marker_color="red")#,text=[k for (k,v) in map["busac_i"]])
push!(every, cluster_1)
end

for t in 1:1:4
    cluster_2 = PlotlyJS.scatter(;x=[df[!,:demand][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]<=0.35)], y=[df[!,:res][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]<=0.35)], mode="markers")#, marker_color="red")#,text=[k for (k,v) in map["busac_i"]])
    push!(every, cluster_2)
    end


PlotlyJS.plot(every)

every=Array{GenericTrace{Dict{Symbol,Any}},1}()
for t in 1:1:4
cluster_1 = PlotlyJS.scatter(;x=[df[!,:demand][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]>0.275)], y=[df[!,:res][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]>0.275)], mode="markers+text",text=[df[!,:time_stamp][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]>0.275)])#, marker_color="red")#,text=[k for (k,v) in map["busac_i"]])
push!(every, cluster_1)
end

for t in 1:1:4
    cluster_2 = PlotlyJS.scatter(;x=[df[!,:demand][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]<=0.275)], y=[df[!,:res][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]<=0.275)], mode="markers+text",text=[df[!,:time_stamp][n] for (n,i) in enumerate(a) if (i==t && df[!,:res][n]<=0.275)])#, marker_color="red")#,text=[k for (k,v) in map["busac_i"]])
    push!(every, cluster_2)
    end


PlotlyJS.plot(every)