################## loads external packages ##############################
using Test

include("data/input/test/test_script_full.jl")
##################### File parameters #################################

@test isapprox(main_test(), -5.816710439500935e6; atol = 0.1) 
