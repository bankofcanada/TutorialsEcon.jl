
# VSCode users:
# Do not run next line of code with Ctrl-Enter!
# Run next line of code with Alt-Enter (line), Shift-Enter (run cell), or Ctrl-F5 (run file)
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
# A value of 0 is what we want to see. In verbose mode, it also lists the
# problematic equations and their residuals.

@test check_sstate(m) == 0

## ##########################################################################
### Examine the steady state

# We can access the steady state solution via `m.sstate` using the dot notation.
m.sstate.dc

# We can also assign new values, but we should be careful to make sure it remains
# a valid steady state solution.
m.sstate.dc.level = 0.43121
@test check_sstate(m) > 0

# Okay, let's undo that.
m.sstate.dc.level = 0.4312
@test check_sstate(m) == 0

# We can examine the entire steady state solution with [`printsstate`](@ref).
printsstate(m)


## ##########################################################################
#### Part 3: Impulse response

### Simulation plan

# Before we can simulate the model, we have to decide on the length of the
# simulation and for each period what data is available, i.e. what values are
# known or exogenous. This is done with an object of type [`Plan`](@ref).

# To create a plan all we need is the model and a period for the simulation.
sim_rng = 2000Q1:2039Q4
p = Plan(m, sim_rng)

# The plan shows us a list of dates or ranges and for each the list of exogenous
# values (variables or shocks). By default, all shocks are exogenous and all
# variables are endogenous.

# We also see that the range of the plan has been extended before and after the
# simulation range. This is necessary, because we need to set initial and final
# conditions. The number of periods for initial conditions is equal to the largest
# lag in the model. Similarly, terminal conditions have to be imposed over as many
# periods as the largest lead.

p.range          # the full range of the plan
init = first(p.range):first(sim_rng) - 1   # the range for initial conditions
term = last(sim_rng) + 1:last(p.range)     # the range for final conditions
@test length(init) == m.maxlag
@test length(term) == m.maxlead

## ##########################################################################
### Exogenous data

# We have to provide the data for the simulation. We start with all zeros and fill
# in the external data, which must include initial conditions for all variable and
# shocks, exogenous values (according to the plan) and possibly final conditions.

#### Initial conditions

# In this example, we want to simulate an impulse response, so it makes sense to
# start from the steady state and that's what we set as the initial condition.
# The initial conditions for the shocks we leave at 0.

exog = zerodata(m, p);
for var in variables(m)
    exog[init, var] = m.sstate[var].level
end
exog

# !!! tip "Pro tip"
#     The above works here because the steady state is stationary, i.e. all slopes
#     are zero. If we had a model with linear growth steady state, we could do
#     something like this (see [`@rec`](@ref)):

for var in variables(m)
    ss = m.sstate[var]
    exog[init, var] = ss.level
    if ss.slope != 0
        # recursively update by adding the slope
        @rec init[2:end] exog[t, var] = exog[t - 1, var] + ss.slope
    end
end

#### Final conditions

# For the final conditions we can use the steady state again, because we expect
# that the economy will eventually return to it, if it's given enough time after
# the last shock. We can do this by assigning the values of the steady state to
# the final periods after the simulation, similar to what we did with the initial
# conditions.

# Alternatively, we can specify that we want to use the steady state in the call
# to simulate by passing `fctype=fclevel`. Yet another possibility is to set the
# final condition so that the solution slope matches the slope of the steady state
# by setting `fctype=fcslope`. In both cases, we don't need to set anything in the
# exogenous data array because those values would be ignored.

# !!! tip "Pro tip"
#     In this model the two ways of using the steady state for final conditions
#     are equivalent, because the steady state here is stationary and unique. When
#     the steady state has non-zero slope, or if the steady state has zero slope
#     but the level is not unique, we should use `fctype=fcslope`.

#### A quick sanity check

# If we were to run a simulation where the economy started in the steady state and
# there were no shocks at all, we'd expect that the economy would remain in steady
# state forever.

ss = simulate(m, exog, p; fctype=fcslope);

# The simulated data, `ss`, should equal (up to the accuracy of the solution) the
# steady state data. Similar to [`zerodata`](@ref), we can use [`steadystatedata`](@ref)
# to create a data set containing the steady state solution.

@test ss ≈ steadystatedata(m, p)

#### Exogenous data

# All shocks are exogenous by default. All we have left to do is set the value of 
# the shock.

# Let's say that we want to shock `epinf` for the first 4 quarters by `0.1`.

exog[sim_rng[1:4], :epinf] = 0.1;
exog[shocks(m)]

#### Running the simulation

# We call [`simulate`](@ref), providing the model, the exogenous data and the plan.
# We also specify the type of final condition we want to impose.

irf = simulate(m, exog, p, fctype=fcslope);

# We can now take a look at how some of the observable variables in the model have
# responded to this shock. We can use `plot` from the `Plots` package to for that.
# We can specify the variables we want to plot using `vars=` and the names of the
# datasets being plotted (for the legend) in the `names=` option.

plot(ss, irf,
     vars=(:pinfobs, :dy, :labobs, :robs),
     names=("SS", "IRF"),
     legend=[true false false false],
     size=(600, 400)
    );

png_fname = joinpath(mypath, "irf.png")
rm(png_fname, force=true)
savefig(png_fname)
@test isfile(png_fname)

## ##########################################################################
#### Part 4: Stochastic shocks simulation

# Now let's do a stochastic shock simulation. We'll have random shocks over 2 year
# and then simulate without any new shocks for several years after that to allow
# time for the economy to relax back to its steady state.

sim_rng = 2000Q1:2049Q4      # simulate 50 years starting 2000
shk_rng = 2004Q1 .+ (0:7)    # shock 8 quarters starting in 2004
p = Plan(m, sim_rng)
init = first(p.range):first(sim_rng) - 1
term = last(sim_rng) + 1:last(p.range)
exog = zerodata(m, p);
for v in variables(m)
    exog[init, v] = m.sstate[v].level
end

# The distributions of the shocks are assumed normal with mean 0 and standard
# deviations that were estimated. We can use the `Distributions` and `Random`
# packages to draw the necessary random values.

shk_dist = (ea = Normal(0.0, 0.4618),
            eb = Normal(0.0, 1.8513),
            eg = Normal(0.0, 0.6090),
            eqs = Normal(0.0, 0.6017),
            em = Normal(0.0, 0.2397),
            epinf = Normal(0.0, 0.1455),
            ew = Normal(0.0, 0.2089));

for (shk, dist) in pairs(shk_dist)
    exog[shk_rng, shk] = rand(dist, length(shk_rng))
end
exog[shk_rng, shocks(m)]

# Now we're ready to simulate. We can set the shocks as being anticipated or
# unanticipated. This is done by setting the `anticipate=` option in
# [`simulate`](@ref).

sim_a = simulate(m, exog, p; fctype=fcslope, anticipate=true);
sim_u = simulate(m, exog, p; fctype=fcslope, anticipate=false);

# we can take a look again at the responses of the observed variables to these
# shocks.

observed = (:dy, :dc, :dinve, :labobs, :pinfobs, :dw, :robs);
ss = steadystatedata(m, p);
plot(ss, sim_a, sim_u,
     vars=observed,
     names=("SS", "Anticipated", "Unanticipated"),
     legend=[true (false for i = 1:6)...],
     linewidth=1.5,
     size=(900, 600)
    );

png_fname = joinpath(mypath, "stoch_shk.png")
rm(png_fname, force=true)
savefig(png_fname)
@test isfile(png_fname)

# We see that when the shocks are anticipated the variables start to react to them
# right away while in the unanticipated case there's no movement until the
# shocks actually hit.

## ##########################################################################
#### Part 5: Back out historical shocks

# Now let's pretend that the simulated values we just found are historical data
# and that we don't know the values of the shocks. We can treat the observed
# values of the variables as known by making these variables exogenous. At the
# same time we will make the shocks endogenous, so that their values will be
# solved for during the simulation.

# The "history" period is from the first period of the simulation until the last
# shock hit in the previous exercise.

hist_rng = first(sim_rng):last(shk_rng)

# We use [`exogenize!`](@ref) and [`endogenize!`](@ref) to set up a plan in which
# observed variables are exogenous and shocks are endogenous during history.

endogenize!(p, shocks(m), hist_rng);
exogenize!(p, observed, hist_rng);
p

# As we can see, the plan now reflects our intentions.

# Finally, we need to set up the exogenous data. This time we don't specify the
# shocks, rather we assign the known data for the observed variables during the
# historical period. We start with initial conditions.

exog = zerodata(m, p);
for v in variables(m)
    exog[init, v] = m.sstate[v].level
end

# We take the observed data from the simulations above. We'll do the anticipated
# version first.

for v in observed
    exog[hist_rng, v] = sim_a[v]
end
back_a = simulate(m, exog, p, fctype=fcslope, anticipate=true);

# Now we'll repeat with the unanticipated case.

for v in observed
    exog[hist_rng, v] = sim_u[v]
end
back_u = simulate(m, exog, p, fctype=fcslope, anticipate=false);


# If we did everything correctly, the shocks we recovered would exactly match the
# shocks we used when we simulated the "historical data".

@test sim_a[shocks(m)] ≈ back_a[shocks(m)]
@test sim_u[shocks(m)] ≈ back_u[shocks(m)]

# Moreover, we should have the unobserved variables match as well. 
# In fact, all the data should match over the entire simulation range.

@test sim_a ≈ back_a
@test sim_u ≈ back_u
