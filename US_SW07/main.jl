
# VSCode users:
# Do not run next line of code with Ctrl-Enter!
# Run next line of code with Alt-Enter (line), Shift-Enter (run cell), or Ctrl-F5 (run file)
mypath = dirname(@__FILE__)

## ##########################################################################
# Initialization

using Pkg
Pkg.activate(joinpath(mypath, "..", ".."))
using Plots
using Random
using Distributions
using Test

using ModelBaseEcon
using StateSpaceEcon
using TimeSeriesEcon

## ##########################################################################
#### Part 1: The model

### Load the model

# The model is described in its own dedicated module, which in turn is contained
# in its own file, `SW07.jl`. We can load the module with `using SW07`, then the
# model itself is a global variable called `model` within that module.
unique!(push!(LOAD_PATH, mypath))
using SW07
m = SW07.model

## ##########################################################################
### Examine the model

# This model is too big to fit all of its details in the REPL window, so only a
# summary information is displayed. We can see the entire model with `fullprint`.
fullprint(m)

# We can also examine individual components using the commands `parameters`,
# `variables`, `shocks`, `equations`.
parameters(m)

## ##########################################################################
### Setting the model parameters

# We must not change any part of the model in the running Julia session except for
# the model parameters and [steady state constraints](@ref
# steady_state_constraints). If we want to add variables, shocks, or equations, we
# must do so in the model module file and restart Julia to load the new model.
    
# When it comes to the model parameters, we can access them by their names from
# the model object using dot-notation.
m.crr # read a parameter value
m.cgy = 0.5187 # modify a parameter value

# !!! note 
#     In this model the values of the parameters have been set according to the
#     [`replication data`](@ref replication_data).

## ##########################################################################
### The model flags and options

# In addition to model parameters, which are values that appear in the model
# equations, the model object also holds two other sets of parameters, namely
# flags and options.

# Flags are (usually boolean) values which characterize the type of model this is.
# For example a linear model should have its `linear` flag set to `true`.
# Typically this is done in the model file before calling [`@initialize`](@ref).
m.flags

# Options are values that adjust the operations of the algorithms. For example, we
# have `tol` and `maxiter`, which set the desired accuracy and maximum number of
# iterations for the iterative solvers. These can be adjusted as needed at any
# time. Another useful option is `verbose`, which controls the verbosity.

# Many functions in `StateSpaceEcon` have optional arguments by the same names as
# the names of model options. When the argument is not explicitly given in the
# function call, these functions will use the value from the model option of the
# same name.
m.verbose = true
m.options


## ##########################################################################
#### Part 2: The Steady state solution

# The steady state is a special solution of the dynamic system, one that remains
# constant over time. It is important on its own, but also it can be useful in
# several ways. One example is that linearizing the model requires a particular
# solution about which to linearize and the steady state is the one typically used.

# In addition to the steady state we also consider another kind of special
# solution, which grows linearly in time. If we know that the steady state
# solution is constant (i.e. its slope is zero), we can set the model flag
# `ssZeroSlope` to `true`. This is not required, however in a large model it might
# help the steady state solver converge faster to the solution.

# The model object `m` stores information about the steady state. This includes
# the steady state solution itself as well as a (possibly empty) set of additional
# constraints that apply only to the steady state. This information can be
# accessed via `m.sstate`.
m.sstate

## ##########################################################################
### Steady state constraints

# Sometimes the steady state is not unique, and one can use steady state
# constraints to specify the particular steady state one wants. Also, if the model
# is non-linear, these constraints can be used to help the steady state solver
# converge. Steady state constraints can be added with the [`@steadystate`](@ref)
# macro. It can be as simple as giving a specific value or we can write an
# equation with multiple variables. We're allowed to use model parameters in these
# equations as well.

@steadystate m a = 5
m.sstate

# We can clean up the constraints by emptying the constraints container.

empty!(m.sstate.constraints)
m.sstate

# !!! note "Important note"
#     Steady state constraints that are always valid can be pre-defined in the model file.
#     In that case, all calls to the [`@steadystate`](@ref) macro must be made after calling
#    [`@initialize`](@ref).

## ##########################################################################
### Solve for the steady state

# The steady state solution is stored within the model object. Before solving, we
# have to specify an initial condition. If the model is linear, this makes no
# difference, but in a non-linear model a good or a bad initial guess might be the
# difference between success and failure of the steady state solver.

# We can do this by calling [`clear_sstate!`](@ref). This call removes any
# previously stored solution, sets the initial condition, and runs the pre-solve
# pass of the steady state solver. The initial guess can be given with the `lvl`
# and `slp` arguments; if not, an initial guess is chosen automatically.

# Once that's done, we call [`sssolve!`](@ref) to find the steady state. This
# function returns a `Vector{Float64}` containing the steady state solution, but
# it also writes that solution into the model object. The vector is of length
# `2*nvariables(m)` and contains the level and the slope for each variable.

clear_sstate!(m)
sssolve!(m);

# If in doubt, we can use [`check_sstate`](@ref) to make sure the steady state solution
# stored in the model object indeed satisfies the steady state system of equations.
# This function returns the number of equations that are not satisfied.
# A value of 0 is what we want to see. In verbose mode, the it also lists the
# problematic equations and their residuals.

check_sstate(m)

## ##########################################################################
### Examine the steady state

# We can access the steady state solution via `m.sstate` using the dot notation.
m.sstate.dc

# We can also assign new values, but we should be careful to make sure it remains
# a valid steady state solution.
m.sstate.dc.slope = 0.001
check_sstate(m)

# Okay, let's undo that.
m.sstate.dc.slope = 0
check_sstate(m)

# We can examine the entire steady state solution with [`printsstate`](@ref).
printsstate(m)


## ##########################################################################
#### Part 3: Simulation plan

p = Plan(m, 2000Q1:2039Q4)

init = p.range[1:m.maxlag]
term = p.range[end .+ (-m.maxlead + 1:0)]

exog = zerodata(m, p)

# set initial conditions
for var in variables(m)
    exog[init, var] = m.sstate[var].level
end

# final conditions - use fcslope, no need to set anything in exog
ss = simulate(m, exog, p; fctype=fcslope)

@test ss ≈ steadystatedata(m, p)

# Impulse response when we shock epinf
exog[last(init) + 1, :epinf] = 0.1
irf = simulate(m, exog, p; fctype=fcslope)

plot(ss, irf,
     vars=(:pinfobs, :dy, :labobs, :robs),
     names=("SS", "IRF"),
     legend=[true false false false],
     size=(600, 400)
    );
savefig("irf.png")

## ##########################################################################
# Stochastic shock 

sim_rng = 2000Q1:2049Q4      # simulate 50 years starting 2000
shk_rng = 2004Q1 .+ (0:7)    # shock 8 quarters starting in 2004
p = Plan(m, sim_rng)
init = first(p.range):first(sim_rng) - 1
term = last(sim_rng) + 1:last(p.range)
exog = zerodata(m, p);
for v in variables(m)
    exog[init, v] = m.sstate[v].level
end

shk_dist = (ea = Normal(0.0, 0.4618),
            eb = Normal(0.0, 1.8513),
            eg = Normal(0.0, 0.6090),
            eqs = Normal(0.0, 0.6017),
            em = Normal(0.0, 0.2397),
            epinf = Normal(0.0, 0.1455),
            ew = Normal(0.0, 0.2089));
Random.seed!(1234); # hide
for (shk, dist) in pairs(shk_dist)
    exog[shk_rng, shk] = rand(dist, length(shk_rng))
end
exog[shk_rng, shocks(m)]

sim_a = simulate(m, exog, p; fctype=fcslope, anticipate=true);
sim_u = simulate(m, exog, p; fctype=fcslope, anticipate=false);

observed = (:dy, :dc, :dinve, :labobs, :pinfobs, :dw, :robs);
ss = steadystatedata(m, p);
plot(ss, sim_a, sim_u,
     vars=observed,
     names=("SS", "Anticipated", "Unanticipated"),
     legend=[true (false for i = 1:6)...],
     linewidth=1.5,   # hide
     size=(900, 600)  # hide
    );
savefig("stoch_shk.png")


## ##########################################################################
# Back out shocks from historical data

hist_rng = first(sim_rng):last(shk_rng)

endogenize!(p, shocks(m), hist_rng);
exogenize!(p, observed, hist_rng);
display(p)

exog = zerodata(m, p)
for v in variables(m)
    exog[init, v] = m.sstate[v].level
end

for v in observed
    exog[hist_rng, v] = sim_a[v]
end
back_a = simulate(m, exog, p, fctype=fcslope, anticipate=true);

for v in observed
    exog[hist_rng, v] = sim_u[v]
end
back_u = simulate(m, exog, p, fctype=fcslope, anticipate=false);

@test sim_a[shocks(m)] ≈ back_a[shocks(m)]
@test sim_u[shocks(m)] ≈ back_u[shocks(m)]

@test sim_a ≈ back_a
@test sim_u ≈ back_u



