module IEEE_energy_markets_test_case
import JLD2#pin to v0.4.0
import PlotlyJS
import Gurobi
import JuMP#pin to v0.21.10
import JSON
import CSV
import XLSX
import Memento#pin to v1.1.2
import Dates
import DataFrames
import OrderedCollections
import FileIO
import Geodesy
import PowerModels;const _PM = PowerModels#pin to v0.17.2
import PowerModelsACDC;const _PMACDC = PowerModelsACDC
import InfrastructureModels;const _IM = InfrastructureModels
import MathOptInterface;const _MOI = MathOptInterface

include("prob/cordoba_acdc_wf_strg.jl")
include("prob/cordoba_acdc_wf_split.jl")
include("prob/power_models_functions.jl")
include("prob/infrastructure_models_functions.jl")
include("core/objective.jl")
include("core/constraints.jl")
include("core/storage.jl")
include("core/variables.jl")
include("io/profile_data.jl")
include("io/functions.jl")
include("io/print_m_file.jl")
include("io/post_process.jl")
include("io/economics_IEEE/economics_IEEE.jl")

try 
    println("You are working on blunt localhost.")  
    include("C:\\Users\\shardy\\Documents\\julia\\packages\\economics\\src\\economics.jl")#blunt
catch
    println("You are working on winter server.") 
    include("C:\\Users\\shardy\\Documents\\GitHub\\economics.jl\\src\\economics.jl")#winter
end
const _ECO = economics
end # module
