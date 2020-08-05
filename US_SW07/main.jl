
#  if you copy-paste the following line into REPL it'll not work.
#  This is what happens if you run it with Ctrl-Enter.

# VSCode users:
# Do not run next line of code with Ctrl-Enter!
# Run next line of code with Alt-Enter (line), Shift-Enter (run cell), or Ctrl-F5 (run file)
mypath = dirname(@__FILE__)

using Pkg
Pkg.activate(joinpath(mypath, ".."))


using ModelBaseEcon
using StateSpaceEcon
using TimeSeriesEcon

## ###

# The model is in a module by the same name. 
# Before we can load it (with `using`) we have to tell Julia where to find its file.
unique!(push!(LOAD_PATH, mypath))
using SW07
m = SW07.model

## ###

# If the model is too big, you only see a summary.
# To see the entire model, use `fullprint`
fullprint(m)

## #


