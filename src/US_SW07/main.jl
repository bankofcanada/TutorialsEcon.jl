
#  if you copy-paste the following line into REPL it'll not work.
#  This is what happens if you run it with Ctrl-Enter.

# VSCode users:
# Do not run next line of code with Ctrl-Enter!
# Run next line of code with Alt-Enter (line), Shift-Enter (run cell), or Ctrl-F5 (run file)
mypath = dirname(@__FILE__)

using Pkg
Pkg.activate(joinpath(mypath, "..", ".."))


using ModelBaseEcon
using StateSpaceEcon
using TimeSeriesEcon

using  ModelBaseEcon: parameters, variables, shocks, equations

## ##########################################################################

# The model is in a module by the same name.
# Before we can load it (with `using`) we have to tell Julia where to find it.
unique!(push!(LOAD_PATH, mypath))
using SW07
m = SW07.model

## ##########################################################################

# If the model is too big, you only see a summary.
# To see the entire model, use `fullprint`
fullprint(m)

# We can also examine individual components of the model. For example
variables(m)
shocks(m)
parameters(m)
equations(m)

# The model parameters can be accessed and even modified from the model
# object using the dot notation.
m.cmaw

## ##########################################################################

# Part 1: Solving the steady state problem. 

# This needs to be done in order
# to use the steady state for the final conditions.

# Start by resetting any previous information about the steady state.
# This is done with `clear_sstate!`. This is not really necessary, but
# it helps to have this code here in case we come back to rerun the cell.
clear_sstate!(m);

# Next we solve for the steady state with a call to `ssolve!`
sssolve!(m);

# The steady state of the model is stored internally within the model instance.
# This is why the two functions we called so far do not return any useful value,
# rather they modify the steady state solution stored in `m`.

# The steady state can be examined (and even modified) by accessing `m.sstate`.
# Using dot notation one can read and write the current steady state values.
m.sstate.a

# At any point we can check whether the steady state solution stored in the model
# object is in fact a steady state solution. This is done by calling
# `check_sstate` It returns an `Int` equal to the number of steady state equations
# that are violated.
check_sstate(m) 

# We want this number to be 0, although with non-linear models sometimes we
# have truncation and round-off errors. We can control the accuracy of the
# solution using the `tol` option in `sssolve!` above and the tolerance of the
# check by passing the same option to `check_sstate`
m.sstate.a = 1e-7
check_sstate(m)
check_sstate(m, tol=1e-6)


# With the `verbose=true` option, the violated equations are printed,
# sorted from the highest residuals at the top with decreasing residuals going down.
check_sstate(m, tol=1e-7, verbose=true)

# 
m.sstate.a = 0.0
check_sstate(m)

# Finally, compare the steady state we obtained with the known steady state for this model.

# TODO

## ##########################################################################

# Part 2: Impulse response.

# TODO


