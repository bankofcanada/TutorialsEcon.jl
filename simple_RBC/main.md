# Simple RBC Model

You can follow the tutorial by reading this page and copying and pasting code
into your Julia REPL session. In this case, you will need the model file,
[`simple_RBC.jl`](simple_RBC.jl).

```@contents
Pages = ["main.md"]
Depth = 3
```

## Part 1: The model

### The simple RBC model

In this tutorial, we will use the simple RBC model presented by [Villemot (2013)](https://archives.dynare.org/DynareShanghai2013/order1.pdf).

A representative agent maximizes the expected discounted sum of his utility by choosing consumption ``C_t`` and labour ``L_t`` for ``t=1,...,\infty``.

```math
\displaystyle\sum_{n=1}^\infty\beta^{t-1}E_t\left[\log(C_t)-\frac{L_t^{1+\gamma}}{1+\gamma}\right]
```

The household provides labour and rents capital to firms.
* ``\beta=\frac{1}{1+\rho}`` is the discount rate and ``\rho \in (0,\infty)`` is the rate of time preference;
* ``\gamma \in (0,\infty)`` is a labour supply parameter.

The household faces the following sequence of budget constraints:

```math
\displaystyle K_t=K_{t-1}(1-\delta)+w_tL_t+r_tK_{t-1}-C_t
```

Where:
* ``K_t`` is the capital at the end of the period;
* ``\delta \in (0,1)`` is the rate of depreciation of capital;
* ``w_t`` is the real wage;
* ``r_t`` is the real rental rate.

The production function is written as:

```math
\displaystyle Y_t=A_tK_{t-1}^\alpha((1+g)^tL_t)^{1-\alpha}
```

Where:
* ``g \in (0,\infty)`` is the growth rate;
* ``\alpha`` is the output elasticity of labour.

``A_t`` is a technological shock that follows an AR(1) process.

```math
\displaystyle \log(A_t)=\lambda\log(A_{t-1})+e_t
```

Where:
* ``e_t`` is an i.i.d. zero-mean normally distributed error term with a standard deviation of ``\gamma``;
* ``\lambda \in (0,1)`` is a parameter governing the persistence of the shock.

### The household problem

The constrained maximization problem can be written as a Lagrangian:

```math
\displaystyle \mathcal{L}(C_t,L_t,K_t) = \sum_{t=1}^\infty\beta^{t-1}E_t\left[\log(C_t)-\frac{L_t^{1+\gamma}}{1+\gamma}-\mu_t(K_t-K_{t-1}(1-\delta)-w_tL_t-r_tK_{t-1}+C_t)\right]
```

The first order conditions are:
```math
\begin{aligned}
    \frac{\partial\mathcal{L}}{\partial C_t} &= \left(\frac{1}{1+\rho}\right)^{t-1} \left(\frac{1}{C_t} - \mu_t \right) = 0 \\
    \frac{\partial\mathcal{L}}{\partial L_t} &= \left(\frac{1}{1+\rho}\right)^{t-1} \left(L_t^\gamma - \mu_t w_t \right) = 0 \\
    \frac{\partial\mathcal{L}}{\partial K_t} &= -\left(\frac{1}{1+\rho} \right)^{t-1} \mu_t + \left(\frac{1}{1+\rho} \right)^t E_t
        \left(\mu_{t+1}(1-\delta+r_t) \right) = 0
\end{aligned}
```

Once we eliminate the Lagrange multiplier ``\mu_t``, we get:
```math
\begin{aligned}
    L_t^\gamma &= \frac{w_t}{C_t} \\
    \frac{1}{C_t} &= \frac{1}{1+\rho} E_t \left(\frac{1}{C_{t+1}}(r_{t+1}+1-\delta) \right)
\end{aligned}
```

### The firm problem

The firm chooses labour and capital in order to maximize profits:

```math
\displaystyle \max_{L_t,K_{t-1}} A_t K_{t-1}^\alpha ((1+g)^t L_t)^{1-\alpha} - r_t K_{t-1} - w_t L_t
```

The first order conditions are:
```math
\begin{aligned}
    r_t &= \alpha A_t K_{t-1}^{\alpha-1}((1+g)^t L_t)^{1-\alpha} \\
    w_t &= (1-\alpha)A_t K_{t-1}^\alpha ((1+g)^t)^{1-\alpha} L_t^{-\alpha}
\end{aligned}
```

### The goods market equilibrium

Aggregate demand must equal aggregate supply to clear the goods market.

```math
\displaystyle K_t + C_t = K_{t-1}(1-\delta)+A_t K_{t-1}^\alpha ((1+g)^t L_t)^{1-\alpha}
```

### The dynamic equilibrium

The dynamic equations are obtained by combining the first order conditions of the household and firm problems 
with the goods market equilibrium.

Based on the goods market equilibrium, consumption and capital must be growing at the same rate: ``g_c=g_k=g``.

Thus, we can define stationary variables as:
```math
\begin{aligned}
    \hat{C}_t &= \frac{C_t}{(1+g)^t} \\
    \hat{K}_t &= \frac{K_t}{(1+g)^t} \\
    \hat{w}_t &= \frac{w_t}{(1+g)^t}
\end{aligned}
```

Once stationarized (see [Villemot (2013)](https://archives.dynare.org/DynareShanghai2013/order1.pdf)), the dynamic equations can be written as:

```math
\begin{aligned}
    \frac{1}{\hat{C}_t} &= \frac{1}{1+\rho} E_t \left(\frac{1}{\hat{C}_{t+1}(1+g)}(r_{t+1}+1-\delta) \right) \\
    L_t^\gamma &= \frac{\hat{w}_t}{\hat{C}_t} \\
    r_t &= \alpha A_t \left( \frac{\hat{K}_{t-1}}{1+g} \right)^{\alpha-1} L_t^{1-\alpha} \\
    \hat{w}_t &= (1-\alpha) A_t \left( \frac{\hat{K}_{t-1}}{1+g} \right)^\alpha L_t^{-\alpha} \\
    \hat{K}_t + \hat{C}_t &= \frac{\hat{K}_{t-1}}{1+g} (1-\delta) + A_t \left( \frac{\hat{K}_{t-1}}{1+g} \right)^\alpha L_t^{1-\alpha}
\end{aligned}
```

The next part will discuss how to implement the simple RBC model in `StateSpaceEcon`.

## Part 2: Implementation of the model in `StateSpaceEcon`

### Installing the packages

We start by installing the packages needed for this tutorial.

```@repl simple_RBC
using StateSpaceEcon, ModelBaseEcon, TimeSeriesEcon, Test, Plots, Random, Distributions
# Fix the random seed for reproducibility.
Random.seed!(1234);

```

### Writing the model file

In `StateSpaceEcon`, a model is written in its own dedicated module, which is contained in its
own file, [`simple_RBC.jl`](simple_RBC.jl).

A docstring can be added to the model to provide more details:
```julia
    """
    Simple RBC Model
    Model available at: https://archives.dynare.org/DynareShanghai2013/order1.pdf
    Presentation: Villemot, S., 2013. First order approximation of stochastic models. Shanghai Dynare Workshop.
    """
```

Then, the module is created with the same name as the model and the associated file name.
The model will be constructed with macros taken from the package `ModelBaseEcon`.
So, we need to load the module `ModelBaseEcon` within the module `simple_RBC` with `using ModelBaseEcon`.
The model will itself be a global variable called `model` within the module `simple_RBC`.
The command `const` declares global variables that will not change and the function `Model()` constructs a new model object.

```julia
module simple_RBC
    using ModelBaseEcon
    const model = Model()
    # Write the rest of the model below.
end # module
```

The model object can hold three sets of parameters: flags, options and model parameters. Flags and options can be adjusted from the model file itself after the constant declaration. Typically, this is done in the model file before calling [`@initialize`](@ref).

Flags are (usually boolean) values which characterize the type of model we have.
For example, we can specify that the model is stationary by setting the flag `ssZeroSlope` to `true`.

```julia
model.flags.ssZeroSlope = true
```
 
Options are values that adjust the operations of the algorithms.
We can preset model options with the function [`setoption!`](@ref).
Below, we set the desired accuracy with `tol` and we set `maxiter` for the maximum number of
iterations for the iterative solvers. Auxiliary variables will not be created and substituted to help the solver (`substitutions`). We will opt for QR factorization, which is slower but more robust than LU factorization. Finally, we will set `verbose` to `true` to provide more information from the commands.

```julia
setoption!(model) do o
    o.tol = 1e-14
    o.maxiter = 100
    o.substitutions = false
    o.factorization = :qr
    o.verbose = true
end # options
```

Many functions in `StateSpaceEcon` have optional arguments of the same name as a
model option. When the argument is not explicitly given in the function call,
these functions will use the value from the model option of the same name. \

The rest of the model is specified with macros which do not have to be in any particular order. \
\
In addition to falgs and options, the model object also holds model parameters, which are values that appear in the model
equations. The macro [`@parameters`](@ref) assigns parameter values to the model. A link between parameters can be created with the macro `@link`. Below, the parameter ``\beta`` depends on the parameter ``\rho``.

```julia
@parameters model begin
    α = 0.33
    δ = 0.1
    ρ = 0.03
    λ = 0.97
    γ = 0
    g = 0.015
    β = @link 1/(1+ρ)
end # parameters
```

Similarly, model variables are specified with the macro [`@variables`](@ref). Variables can be declared one line at a time (as with the parameters previously), or over one line by separating them with semicolons `;`. Alternatively, we use the macro [`@logvariables`](@ref) to indicate to the solver the work with the log of the variables. For instance, instead of working with ``C_t``, the solver will work directly with the logarithm as a standalone variable (``logC_t=e^{\log(C_t)}``). This can help the solver to avoid computing the logarithm of a negative value.

```julia
@logvariables model begin
    C; K; L; w; r; A;
end # variables
```

The macro [`@shocks`](@ref) declares model shocks.

```julia
@shocks model begin
    ea
end # shocks
```

In this case, a `begin` block is not necessary and the technology shock can be declared in one line.

```julia
@shocks model ea
```

The macro [`@autoexogenize`](@ref) links a variable with a shock. This can be useful to back out historical shocks with the command [`autoexogenize!`](@ref) (see below for an example).

```julia
@autoexogenize model begin
    A = ea
end # autoexogenize
```

The dynamic equations of the model are embedded within the macro [`@equations`](@ref). The variables have to be indexed with `t`. For instance, `K[t-1]` refers to the capital stock on `t-1` and `C[t+1]` refers to the expectation on `t` for consumption on `t+1`, or ``E_t(C_{t+1})``. When variables can be separated by a logarithm, it will help the solver to put the macro `@log` in from of an equation. In this way, the residual will be computed as the difference between the logarithm on the left-hand side and the logarithm on the right-hand side. For instance, the solver will prefer to work with the second equation below, which is linear.

```math
\begin{aligned}
    \frac{1}{\hat{C}_t} &= \frac{1}{1+\rho} E_t \left(\frac{1}{\hat{C}_{t+1}(1+g)}(r_{t+1}+1-\delta) \right) \\
    \log{{\hat{C}_t}} &= \log{(1+\rho)} + E_t \left(\log{\hat{C}_{t+1}}\log(1+g)-\log(r_{t+1}+1-\delta) \right)
\end{aligned}
```

```julia
@equations model begin
    @log 1/(C[t]) = β * (1 / (C[t+1]*(1+g))) * (r[t+1]+1-δ)
    @log (L[t])^γ = w[t] / C[t]
    @log r[t] = α * A[t] * (K[t-1]/(1+g)) ^ (α-1) * (L[t]) ^ (1-α)
    @log w[t] = (1-α) * A[t] * (K[t-1]/(1+g)) ^ α * (L[t]) ^ (-α)
    K[t] + C[t] = A[t] * (K[t-1]/(1+g)) ^ α * (L[t]) ^ (1-α) + (1-δ) * (K[t-1]/(1+g))
    log(A[t]) = λ * log(A[t-1]) + ea[t]
end # equations
```

Once the parameters, the variables, the shocks and the equations have been specified, the macro [`@initialize`](@ref) constructs the model within the module `simple_RBC`.

```julia
@initialize(model)
```

### Loading the model

We load the module that contains the model with `using simple_RBC`; the
model itself is a global variable called `model` within that module, which we assign to `m` in the `Main` module.

!!! note "Important note"
    For the `using simple_RBC` command to work, we need the model file [`simple_RBC.jl`](simple_RBC.jl) to be on the search path for modules. We can do this by:
    1) Pushing the file path to `LOAD_PATH` global variable (which we do below for simplicity);
    2) Adding the model as a standalone package and installing it as: `using Pkg; Pkg.add("/[path to the package]/simple_RBC")`

```@repl simple_RBC
unique!(push!(LOAD_PATH, realpath(".")));
using simple_RBC
m = simple_RBC.model
```

### Examining the model

We can see the entire model with `fullprint`.
```@repl simple_RBC
fullprint(m)
```

We can see the flags and the options of the model.

```@repl simple_RBC
m.flags
m.options
```

We can also examine individual components using the commands `parameters`, `variables`, `shocks` and `equations`.
```@repl simple_RBC
parameters(m)
variables(m)
shocks(m)
equations(m)
```

### Setting the model parameters

We must not change any part of the model in the active Julia session except for
the model parameters and steady state constraints if any (see the [Smets and Wouters (2007)](https://bankofcanada.github.io/DocsEcon.jl/dev/Tutorials/US_SW07/main/) tutorial). If we want to add variables, shocks, or equations, we
must do so in the model module file and restart a new Julia session to load the new model.

When it comes to the model parameters, we can access them by their names from
the model object using the dot notation.

```@repl simple_RBC
m.β # read a parameter value
m.α = 0.33 # modify a parameter value
```

Parameters can be linked to other parameters with the macro [`@link`](@ref):

```@repl simple_RBC
parameters(m)[:β]
```

If ``\rho`` changes, ``\beta`` will automatically be updated.

```@repl simple_RBC
m.ρ = 0.05
m.β
m.ρ = 0.03
m.β
```

However, the dynamic links only work with parameter values. Otherwise, the function [`update_links!`](@ref) needs to be called to refresh all the links.

```julia
update_links!(m)
```

!!! note "Important note"
    Links will not be automatically updated if:
    * Links contain a reference outside the model parameters, such as the steady state or a model in a parent module
    * A parameter is not a number, such as if an element of a parameter vector is updated.
## Part 3: The steady state solution

The steady state is a special solution of the dynamic system that remains
constant over time. It is important on its own, but also it can be useful in
several ways. For example, linearizing the model requires a particular solution
about which to linearize, and the steady state is typically used for this
purpose.

In addition to the steady state, we also consider another kind of special
solution which grows linearly in time. If we know that the steady state solution
is constant (i.e., its slope is zero), we can set the model flag `ssZeroSlope`
to `true`. This is not required; however in a large model it might help the
steady state solver converge faster to the solution.

The model object `m` stores information about the steady state. This includes
the steady state solution itself, as well as a (possibly empty) set of additional
constraints that apply only to the steady state. This information can be
accessed via `m.sstate`.

```@repl simple_RBC
m.sstate
```

### Solving for the steady state

The steady state solution is stored within the model object. Before solving, we
have to specify an initial condition. If the model is linear, this makes no
difference, but in a non-linear model a good or a bad initial guess might be the
difference between success and failure of the steady state solver.

We specify the initial guess by calling [`clear_sstate!`](@ref). This call
removes any previously stored solution, sets the initial guess, and runs the
pre-solve pass of the steady state solver. The initial guess can be given with
the `lvl` and `slp` arguments; if not provided, an initial guess is chosen
automatically.

Once that's done, we call [`sssolve!`](@ref) to find the steady state. We can see below that `sssolve!` cannot find a steady state solution.

```@repl simple_RBC
clear_sstate!(m)
sssolve!(m);
```

The Newton-Raphson solution algorithm used by default has failed to converge. Instead, the `:auto` method starts with the Levenberg-Marquardt algorithm and automatically switches to Newton-Raphson when it starts to converge.

```@repl simple_RBC
clear_sstate!(m)
sssolve!(m; method = :auto)
```

The function `sssolve!` returns a `Vector{Float64}` containing the steady state solution, and
it also writes that solution into the model object. The vector is of length
`2*nvariables(m)` and contains the level and the slope for each variable.

If in doubt, we can use [`check_sstate`](@ref) to make sure the steady state
solution stored in the model object indeed satisfies the steady state system of
equations. This function returns the number of equations that are not satisfied.
A value of 0 is what we want to see. In verbose mode, it also lists the
problematic equations and their residuals.

```@repl simple_RBC
check_sstate(m)
```

### Examining the steady state

We can access the steady state solution via `m.sstate` using the dot notation.

```@repl simple_RBC
m.sstate.C
```

We can also assign new values to the steady state solution, but we should be
careful to make sure it remains a valid steady state solution.

```@repl simple_RBC
m.sstate.C.level = 1.0050
@test check_sstate(m) > 0
```

As the code above shows, a wrong steady state solution (based on the specified
precision in the `tol` option) will result in one or more equation not being
satisfied. Let's put back the correct value.

```@repl simple_RBC
m.sstate.C.level = 1.0030433070390223
@test check_sstate(m) == 0
```

We can examine the entire steady state solution with [`printsstate`](@ref).

```@repl simple_RBC
printsstate(m)
```

## Part 4: Impulse response

### Simulation plan

Before we can simulate the model, we have to decide on the length of the
simulation and what data is available for each period, i.e., what values are
known (exogenous). This is done with an object of type [`Plan`](@ref).

To create a plan, all we need is the model object and a range for the
simulation.

```@repl simple_RBC
sim_rng = 2000Q1:2039Q4
p = Plan(m, sim_rng)
```

The plan shows us the list of exogenous values (variables or shocks) for each
period or sub-range of the simulation. By default, all shocks are exogenous and
all variables are endogenous.

We also see that the range of the plan has been extended before and after the
simulation range. This is necessary because we need to set initial and final
conditions. The number of periods for initial conditions is equal to the largest
lag in the model. Similarly, final conditions have to be imposed over as many
periods as the largest lead.

```@repl simple_RBC
p.range          # the full range of the plan
init_rng = first(p.range):first(sim_rng)-1   # the range for initial conditions
final_rng = last(sim_rng)+1:last(p.range)     # the range for final conditions
@test length(init_rng) == m.maxlag
@test length(final_rng) == m.maxlead
```

The function [`exportplan`](@ref) can be used to save a plan to a TXT or CSV file which can be opened to visualize the plan. Alternatively, the function [`importplan`](@ref) can load the plan back into Julia from the TXT or CSV file.

### Exogenous data

We have to provide the data for the simulation. We start with all zeros and fill
in the external data, which must include initial conditions for all variable and
shocks, exogenous values (according to the plan), and possibly final conditions.

#### Initial conditions

In this example, we want to simulate an impulse response, so it makes sense to
start from the steady state.

```@repl simple_RBC
exog = steadystatedata(m, p)
```

#### Final conditions

For the final conditions, we can use the steady state again, because we expect
that the economy will eventually return to it if the simulation is sufficiently
long past the last shock. We can do this by assigning the values of the steady
state to the final periods after the simulation, similarly to what we did with the
initial conditions.

Alternatively, we can specify that we want to use the steady state in the call
to simulate by passing `fctype=fclevel`. Yet another possibility is to set the
final condition so that the solution slope matches the slope of the steady state
by setting `fctype=fcslope`. In both cases, we do not need to set anything in
the exogenous data array because those values would be ignored.

!!! tip "Pro tip"
    In the simple RBC model, the two ways of using the steady state
    for final conditions (level or slope) are equivalent, because the steady
    state here is stationary and unique. In models where the steady state has
    non-zero slope, or the steady state has zero slope but the level is not
    unique, we should use `fctype=fcslope`.

If the steady state is not solved or if we prefer not to depend on it, we can use `fctype=fcnatural`.
The final conditions will be constructed assuming that the last simulation period reflects the first difference of the steady state.
For a stationary model, the simulation needs to be long enough so that variables do not change anymore.
In a model where the steady state has non-zero slope, non-stationary variables have to grow at a stable pace by the end of the simulation.

We can set the default option for the simple RBC model outside the model dedicated module.

```@repl simple_RBC
m.options.fctype = fcnatural
```
Otherwise, this option can be set within the model model but the StateSpaceEcon package must be installed within the module. For instance:

``` julia
module simple_RBC
    using ModelBaseEcon
    using StateSpaceEcon
    const model = Model()
    model.flags.ssZeroSlope = true
    setoption!(model) do o
        o.tol = 1e-14
        o.maxiter = 100
        o.substitutions = false
        o.factorization = :qr
        o.verbose = true
        o.fctype = fcnatural
    end # options
    # Rest of the model...
end
```

#### A quick sanity check

If we were to run a simulation where the economy started in the steady state and
there were no shocks at all, we'd expect that the economy would remain in steady
state forever.

```@repl simple_RBC
ss = simulate(m, p, exog);
@test ss ≈ steadystatedata(m, p)
```

The simulated data, `ss`, should equal (up to the accuracy of the solution) the
steady state data. Similar to [`steadystatedata`](@ref), we can use
[`zerodata`](@ref) to create a data set containing with zeros to work in the deviation from the steady state
solution.

```@repl simple_RBC
zz = simulate(m, p, zerodata(m, p); deviation = true);
@test zz ≈ zerodata(m, p)
```

#### Exogenous data

All shocks are exogenous by default. All we have left to do is to set the value
of the shock.

Let's say that we want to shock `ea` for the first four quarters by `0.1`.

```@repl simple_RBC
exog[sim_rng[1:4], :ea] .= 0.1;
exog[shocks(m)]
```

#### Running the simulation

We call [`simulate`](@ref), providing the model, the exogenous data, and the
plan. We also specify the type of final condition we want to impose if we want to diverge from the option setting saved in the model.

```@repl simple_RBC
irf = simulate(m, p, exog; fctype=fcslope)
```

We can now take a look at how some of the variables in the model have
responded to this shock. We use `plot` from the `Plots` package. We
specify the variables we want to plot using `vars` and the names of the
datasets being plotted (for the legend) in the `labels` option.

```@repl simple_RBC
gr(display_type=:inline) # hide
model_vars = [var.name for var in m.variables]; # model variables are taken from the model
plot(ss, irf,
     vars=model_vars,
     labels=("Steady state","Impulse response"),
     legend=[true (false for i = 2:length(model_vars))...],
     size=(600, 400),
     xrotation = 45,margin = 4Plots.mm,
    );
```

```@setup simple_RBC
savefig("irf.png")
```

[![Impulse Response Graph](irf.png)](irf.png)

## Part 5: Stochastic shocks simulation

Now let's run a simulation with stochastic shocks. We will have random shocks
over two years and then have no shocks for several years afterwards to allow
time for the economy to return to its steady state.

```@repl simple_RBC
sim_rng = 2000Q1:2049Q4      # simulate 50 years starting 2000
shk_rng = 2004Q1 .+ (0:7)    # shock 8 quarters starting in 2004
p = Plan(m, sim_rng)
exog = steadystatedata(m, p);
```

The distribution of the shock is assumed normal with mean zero. We use packages `Distributions` and `Random` to draw the
necessary random values.

```@repl simple_RBC
shk_dist = (ea = Normal(0.0, 0.10),);
for (shk, dist) in pairs(shk_dist)
    exog[shk_rng, shk] .= rand(dist, length(shk_rng))
end
exog[shk_rng, shocks(m)]
```

Now we are ready to simulate. We can set the shocks to be anticipated or
unanticipated by setting the `anticipate` parameter in [`simulate`](@ref).

```@repl simple_RBC
sim_a = simulate(m, p, exog; fctype=fcnatural, anticipate=true);
sim_u = simulate(m, p, exog; fctype=fcnatural, anticipate=false);
```

As before, we can review the responses of variables to the shock using `plot`.

```@repl simple_RBC
observed = collect(keys(m.autoexogenize)); # the observed variable is from the autoexogenize list
ss = steadystatedata(m, p);
gr(display_type=:inline) # hide
plot(ss, sim_a, sim_u,
     vars=model_vars,
     labels=("SS", "Anticipated", "Unanticipated"),
     legend=[true (false for i = 2:length(model_vars))...],
     linewidth=1.5,   # hide
     size=(900, 600),  # hide
     xrotation = 45, margin = 4Plots.mm,
    );
```

```@setup simple_RBC
savefig("stoch_shk.png")
```

[![Stochastic Shock Response Graph](stoch_shk.png)](stoch_shk.png)

We see that when the shock is anticipated, the variables start to react to
them right away; in the unanticipated case, there is no movement until the
technology shock actually hit.

## Part 5: Backing out historical shocks

Now let's pretend that the simulated values for `A` are historical data and that we do
not know the magnitude of the shock `ea`. We can treat the observed (simulated)
values of the variable `A` as known by making them exogenous. At the same time we
will make the shock endogenous, so that we can solve for their values during
the simulation.

We use [`exogenize!`](@ref) and [`endogenize!`](@ref) to set up a plan in which
the observed variable is exogenous and the shock is endogenous throughout the stochastic range.

```@repl simple_RBC
endogenize!(p, shocks(m), shk_rng);
exogenize!(p, observed, shk_rng);
p
```

Another possibility is to use the `autoexogenize` command, which will use the default pairing provided in the model under `@autoexogenize`.

```@repl simple_RBC
autoexogenize!(p, m, shk_rng)
```

As we can see above, the plan now reflects our intentions.

Finally, we need to set up the exogenous data. This time we do not specify the
shocks; instead, we assign the known data for the observed variables for the
historic range. We start with initial conditions.

```@repl simple_RBC
exog = steadystatedata(m, p);
```

We take the observed data from the simulation above. We show the anticipated
version first.

```@repl simple_RBC
for v in observed
    exog[shk_rng, v] .= sim_a[v]
end
back_a = simulate(m, p, exog; fctype=fcnatural, anticipate=true);
```

Now we show the unanticipated case.

```@repl simple_RBC
for v in observed
    exog[shk_rng, v] .= sim_u[v]
end
back_u = simulate(m, p, exog; fctype=fcnatural, anticipate=false);
```

If we did everything correctly, the shocks we recovered must match the
shocks we used when we simulated the data.

```@repl simple_RBC
@test sim_a[:ea] ≈ back_a[:ea]
@test sim_u[:ea] ≈ back_u[:ea]
```

Moreover, we must have the unobserved variables match as well. In fact, all the
data must match over the entire simulation range.

```@repl simple_RBC
@test sim_a ≈ back_a
@test sim_u ≈ back_u
```

## Appendix

### References

[Villemot, S., 2013. First order approximation of stochastic models.](https://archives.dynare.org/DynareShanghai2013/order1.pdf)