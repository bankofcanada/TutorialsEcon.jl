
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

# Fix the random seed for reproducibility
Random.seed!(1234); 

nothing
## ##########################################################################
#### Part 1: The model

### Loading the model

# The model is described in its own dedicated module, which is contained in its
# own file, `simple_RBC.jl`. We can load the module with `using simple_RBC`; the model itself
# is a global variable called `model` within that module.

# unique!(push!(LOAD_PATH, mypath))
unique!(push!(LOAD_PATH, joinpath(pwd(),"src","Tutorials","simple_RBC")))
using simple_RBC
m = simple_RBC.model
m.verbose = true;

clear_sstate!(m)
sssolve!(m; method = :auto)
check_sstate(m)

sim_rng = 2000Q1:2039Q4
p = Plan(m, sim_rng)

ss = steadystatedata(m, p)
exog = deepcopy(ss)
exog[sim_rng[1], :ea] .= 0.001;

irf = simulate(m, p, exog; fctype=fcslope, initial_guess = ss, deviation = false);

## ##########################################################################
### Examining the model

# If the model is not too big, we can see the entire model with `fullprint`.
# fullprint(m)

# We can also examine individual components using the commands `parameters`,
# `variables`, `shocks`, `equations`.
# parameters(m)

## ...

## Appendix

### References

# [Villemot, S., 2013. First order approximation of stochastic models.](https://archives.dynare.org/DynareShanghai2013/order1.pdf)