
# VSCode users:
# Do not run next line of code with Ctrl-Enter!
# Run next line of code with Alt-Enter (run line), Shift-Enter (run cell), or Ctrl-F5 (run file)
mypath = dirname(@__FILE__)
## ##########################################################################
# Initialization

using ModelBaseEcon
using StateSpaceEcon
using TimeSeriesEcon

using Test
using Plots
using Random
using Distributions

# Fix the random see for reproducibility
Random.seed!(1234); 

nothing
## ##########################################################################
# update models files if necessary

models_path = joinpath(mypath, "models")

if !isfile(joinpath(models_path, "FRBUS_VAR.jl")) || (
        isfile(joinpath(models_path, "frbus_package.zip")) && mtime(joinpath(models_path, "FRBUS_VAR.jl")) 
            < mtime(joinpath(models_path, "frbus_package.zip")))
    @info "Updating model files"
    include("update_models.jl")
end

## ##########################################################################
# load model

unique!(push!(LOAD_PATH, joinpath(mypath, "models")))

using FRBUS_VAR

m = FRBUS_VAR.model

