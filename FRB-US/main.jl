
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

using HTTP
