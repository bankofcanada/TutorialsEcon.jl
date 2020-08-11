
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

using ModelBaseEcon
using StateSpaceEcon
using TimeSeriesEcon

# using  ModelBaseEcon: parameters, variables, shocks, equations

## ##########################################################################

using RecipesBase
@recipe plot(sd::SimData...; vars=nothing, names=nothing) = begin
    if vars === nothing
        error("Must specify variables to plot")
    elseif vars == :all
        vars = StateSpaceEcon._names(sd[1])
    end
    if length(vars) > 10
        error("Too many variables. Split into pages.")
    end
    if names === nothing
        names = ["data$i" for i = 1:length(sd)]
    end
    layout --> length(vars)
    title --> reshape(map(string, [vars...]), 1, :)
    label --> repeat(reshape([names...], 1, :), inner=(1, length(vars)))
    linewidth --> 2
    left_margin --> 4 * Plots.mm
    for s in sd
        for v in vars
            @series begin
                s[v]
            end
        end
    end
end

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

(ss ≈ steadystatedata(m, p)) |> display


# Impulse response when we shock epinf
exog[last(init) + 1, :epinf] = 0.1
irf = simulate(m, exog, p; fctype=fcslope)

vars = ("pinf", "y", "r", "lab")

plt = plot(ss, irf, vars=vars, names=("SS", "IRF"), titlefont=font(11))
savefig(plt, "irf.png")
display(plt)

## ##########################################################################
# Stochastic shock 

shock = 2004Q1 .+ (0:7)  # shock 8 quarters starting 2001

p = Plan(m, 2000Q1:2049Q3)  # simulate 15 years beyond the last shock  

init = p.range[1:m.maxlag]
term = p.range[end .+ (-m.maxlead + 1:0)]

exog = zerodata(m, p)

# set initial conditions to steady state
for v in variables(m)
    exog[init, v] = m.sstate.:($v).level
end

ss = steadystatedata(m, p)

# assign shocks according to their distributions
shk_dist = (ea = Normal(0.0, 0.4618), 
            eb = Normal(0.0, 1.8513), 
            eg = Normal(0.0, 0.6090), 
            eqs = Normal(0.0, 0.6017), 
            em = Normal(0.0, 0.2397), 
            epinf = Normal(0.0, 0.1455), 
            ew = Normal(0.0, 0.2089))

Random.seed!(1234);

for (s, d) in pairs(shk_dist)
    exog[shock, s] = rand(d, length(shock))
end

sim_a = simulate(m, exog, p; fctype=fcslope);
sim_u = simulate(m, exog, p; fctype=fcslope, anticipate=false);

plt_attrs() = (layout = @layout([a b; c d; e f; g _]),
    titlefont = font(11),
    size = (600, 800),
    linewidth = 1.5,
    legend = false, 
    names = ("SS", "Ant", "Unant"))

plt = plot(ss, sim_a, sim_u, vars=shocks(m); plt_attrs()...)
savefig(plt, "shocks.png")
display(plt)

plt = plot(ss, sim_a, sim_u, vars=keys(m.autoexogenize); plt_attrs()...)
savefig(plt, "responses.png")
display(plt)


