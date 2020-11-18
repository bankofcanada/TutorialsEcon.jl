# FRB-US with VAR-based Expectations

## Getting started

If you wish to run the code of this tutorial, or to experiment for yourself,
make sure to follow the instructions in
[Introduction/Getting_started](../index.md#Getting-started)

```@setup frbus
using StateSpaceEcon
using ModelBaseEcon
using TimeSeriesEcon

using Test
using Plots
using Random

# Fix the random seed for reproducibility.
Random.seed!(1234);

# We need the model file FRBUS_VAR.jl to be on the search path for modules.
unique!(push!(LOAD_PATH, realpath("./models"))) # hide

```

## The Model File

We recommend placing the model definition in its own Module in a separate Julia
source file. Although this is not strictly necessary, it helps to keep the code
well organized and it also allows us to take advantage of pre-compilation. The
first time we load the model file it takes some time to compile, and after that
loading is much faster.

The FRB-US model we will be working with is located in
[`models/FRBUS_VAR.jl`](models/FRBUS_VAR.jl).  This file was automatically
generated from the `model.xml` file contained within
[`frbus_package.zip`](https://www.federalreserve.gov/econres/us-models-package.htm).

### Some Notes About the Julia Model File

1. Some variables are declared as *log variables* using the `@log` declaration
   within a `@variables` block. For example

   ```julia
   @variables model begin
       # ... #
       "Investment in equipment, current \$" @log ebfin
       "Personal consumption expenditures, current \$ (NIPA definition)" @log ecnian
       # ... #
   end
   ```

    A full discussion of log variables is beyond the scope of this tutorial. However
    a very simplified explanation is that this improves the stability of the
    numerical solver for variables which are always positive.

2. Variables which do not have an associated equation and for which data is
   always given are declared *exogenous* using an `@exogenous` block. For
   example

   ```julia
   @exogenous model begin
       # Exogenous variables:
       "Potential government employment ratio (relative to business)" adjlegrt
       "Dummy, post-1979 indicator" d79a
       "Dummy, 1980-1995 indicator" d8095
       # ... #
   end
   ```

3. The EViews syntax is translated to Julia syntax. EViews functions `d()` and
   `dlog()` are replaced with their equivalent StateSpaceEcon *meta functions*
   `@d()` and `@dlog()`. EViews `@movav()` is left alone, because a
   StateSpaceEcon *meta function* by the same name already exists and does the
   same thing. Finally, the EViews `@recode` is replaced with the equivalent
   Julia function `ifelse()`, or were appropriate with a `min()` or a `max()`.

4. Several equations contain expressions matching the pattern
   `1 / (1 + exp(±cx))`, where `c` is a large constant (usually 25) and `x` is
   some expression. This function is a smooth approximation of the indicator
   function. While mathematically the derivative of this function converges to
   approximately zero everywhere outside a very small interval containing 0,
   numerically it causes problems because it results in either 0/0 or ∞/∞. To
   remedy this situation, we replace such patterns with the equivalent call to
   `indicator(∓cx)`, where the function `indicator()` is defined in the model
   file.

   ```julia
   export indicator
   "Indicator function" @inline indicator(x) = convert(typeof(x), x>zero(x))
   ```

### Regenerating the Model File

We have included the script [`update_models.jl`](update_models.jl). It is not necessary for
running the code below, but it may be helpful for further experimentation.

If the model file is missing, for some reason or another, this script will
automatically download `frbus_package.zip` and process the `model.xml` within it
to re-generate `model/FRBUS_VAR.jl`. This could also be useful if you make
modifications to `model.xml` (including not only the equations, but also the
parameter values), or if you want to use a different FRBUS package from the one
posted on the FRBUS website. In this case, simply place your `frbus_package.zip`
in the `models/` directory and run `update_models.jl`. Of course such
modifications can also be done directly into the existing `models/FRBUS_VAR.jl`
file.

Note that after updating `models/FRBUS_VAR.jl`, it'd be best to restart the REPL.
The first time you load the new model module it'll take a bit longer due to
pre-compilation.

## Load the Model

Assuming that the `models/` directory is already in the `LOAD_PATH` list, we can
load the model by loading its module. Once loaded, the module contains a
variable `model` which represents the model object.

```@repl frbus
using FRBUS_VAR
m = FRBUS_VAR.model
```

We see that the model has a number of variables, shocks, equations, and
parameters. The total number of variables include exogenous variables.

```@repl frbus
m.variables
```

We also see that the model object includes a number of auxiliary equations.
These equations (and variables) are automatically added as substitutions for
expressions that must be positive.

```@repl frbus
m.auxeqns
```

For example, we see that variable `aux1` was added with the first equation in
the above list. At the same time, in equation for `dpgap`, the expression
`log(phr[t] * pxp[t])` has been replaced by `aux1[t]`.

```@repl frbus
m.equations[2]
```

A detailed discussion of auxiliary variables and equations is beyond the scope
of this tutorial. It suffices to say that we can safely ignore their presence
for now.

## Load the Longbase Data

Unfortunately the `longbase` data is available only in EViews format, which
cannot be read automatically by open source software (at least to my knowledge).
For convenience here we have included the version of `longbase` from 23-07-2020
in a csv format and a function that loads that data. The function is defined
in file [`load_longbase.jl`](load_longbase.jl). Note that this is not a module,
so we load it by calling `include()`, not `using`.

```@repl frbus
include("load_longbase.jl")
longbase = load_longbase("longbase_23072020.csv")
@test size(longbase) == (834, 659) # hide
```

## Load `set_policy.jl`

The model contains a number of switch variables which control which monetary
policy function is used and which fiscal policy function is used at each period
of the simulation. For convenience we have included functions `set_mp!()` and
`set_fp!()`, which are defined in [`set_policy.jl`](set_policy.jl).

```@repl frbus
include("set_policy.jl")
@doc set_mp!

dmp_switches

@doc set_fp!

dfp_switches
```

## Prepare the Simulation Plan

The simulation is controlled by a [`Plan`](@ref) object. The plan is defined by
a model object and simulation range. The full range handled by the plan contains
additional periods before and after the simulation range, which account for
initial and final conditions. By default, the simulation plan is setup such that
all shocks are exogenous and all variables are endogenous, except for the
variables that are declared either in an `@exogenous` block or with the `@exog`
declaration within an `@variables` block in the model file.

```@repl frbus
sim = 2020Q1:2025Q4     # simulation range
p = Plan(m, sim)        # the plan object

ini = firstdate(p):first(sim) - 1      # range of initial conditions
fin = last(sim) + 1:lastdate(p)        # range of final conditions
```

Note that the `fin` range is actually empty. This is because this model doesn't
have any leads.

## Prepare the Exogenous Data

We start with a simulation data that is set to 0 everywhere and we assign the
data from `longbase`.

```@repl frbus
ed = zerodata(m, p);
ed .= longbase[p.range];
```

Next we set the monetary policy, the fiscal policy and a few other switches.

```@repl frbus
# set monetary policy
set_mp!(ed, :dmpintay);

# turn off zero bound and policy thresholds;
# hold policy maker's perceived equilibrium real interest rate
ed.dmptrsh .= 0.0;
ed.rffmin .= -9999;
ed.drstar .= 0.0;

# set fiscal policy
set_fp!(ed, :dfpsrp);

@test all(sum(abs, ed[dmp_switches], dims=2) .== 1) # hide
@test all(sum(abs, ed[dfp_switches], dims=2) .== 1) # hide

```

## Back out the Shocks

The first simulation test is to compute the shocks given the variable paths from
`longbase`. To do this, we swap the variables and shocks, making variables
exogenous and shocks endogenous. The mapping between variables and their
corresponding shocks is declared in the model file, so we can simply call
[`autoexpgenize!`](@ref). We make a copy of the plan `p`, so that the original
plan would not be modified. We also make a copy of the exogenous data `ed`, so
that the original would remain unchanged.

```@repl frbus
p_0 = autoexogenize!(copy(p), m, sim)
ed_0 = copy(ed)
```

Now we run the [`simulate`](@ref) command. Note that the first time we run a
function in Julia, it takes a bit longer due to compilation time. In this case,
it takes much longer, because the model is very large and each and every
equation gets compiled, together with its automatic derivative.

```@repl frbus
sol_0 = @time simulate(m, ed_0, p_0; verbose=true, tol=1e-12);
@test sol_0[m.variables] ≈ ed[m.variables]
```

The compilation is done once and reused every call after that. So the second
call to [`simulate`](@ref) is much, much faster.

```@repl frbus
sol_0 = @time simulate(m, ed_0, p_0; verbose=true, tol=1e-12);
```

## Recover the Baseline Case

Next simulation is a sanity test. If we run a simulation with the shocks set to
the values we just backed out, the resulting variable paths must match the ones
we started with.

Once again we start with a exogenous data set everywhere to 0. Then we assign
only the initial conditions and the shocks we just backed out.

```@repl frbus
p_r = Plan(m, sim);
ed_r = zerodata(m, p_r);

# initial conditions for the variables are taken from longbase
ed_r[ini, m.variables] = longbase[ini, m.variables];

# shocks are taken from from sol_0
ed_r[p_r.range, m.shocks] = sol_0[p_r.range, m.shocks];

# exogenous variables are also taken  from sol_0
exogenous = m.variables[isexog.(m.variables)];
ed_r[p_r.range, exogenous] = sol_0[p_r.range, exogenous];
```

Now, the only thing that's left is to set the initial guess for the endogenous
variables. If we leave it at 0, that would be an initial guess too far from the
solution and the Newton-Raphson will diverge. If we set it to the known
solution, that would diminish this exercise to merely verifying that it is
indeed a solution (we already know that). So, to make things a bit more
interesting, we add a bit of noise to the true solution.

```@repl frbus
endogenous = m.variables[.!isexog.(m.variables)];
ed_r[sim, endogenous] = longbase[sim, endogenous] .+ 0.01.*randn(length(sim), length(endogenous));
```

Once again we have to set the monetary policy and the fiscal policy rules, as
well as the values of some of the other switches.

```@repl frbus
set_mp!(ed_r, :dmpintay);
ed_r.dmptrsh .= 0.0;
ed_r.rffmin .= -9999;
ed_r.drstar .= 0.0;
set_fp!(ed_r, :dfpsrp);
```

And finally we can run the simulation and check to make sure that indeed the
recovered simulation matches the base case.

```@repl frbus
sol_r = @time simulate(m, ed_r, p_r, verbose=true, tol=1e-12);
@test sol_r ≈ sol_0
```

## Simulate a shock

The last exercise is to simulate the impulse response to a unit shock in `rffintay`.

```@repl frbus
m.rffintay
```

We start with the base case and add 1 to the `rffintay_a` shock at the first period of the simulation.

```@repl frbus
p_1 = Plan(m, sim);
ed_1 = copy(sol_0);

ed_1.rffintay_a[first(sim)] += 1;
sol_1 = @time simulate(m, ed_1, p_1;  verbose=true, tol=1e-9);

```

Finally, we can plot the impulse response function to see what we've done.

```@repl frbus
# compute the differences between the base case and the shocked simulation.
dd = hcat(SimData(p.range),
    d_rff=sol_1.rff - sol_0.rff,
    d_rg10=sol_1.rg10 - sol_0.rg10,
    d_lur=sol_1.lur - sol_0.lur,
    d_pic4=sol_1.pic4 - sol_0.pic4,
);

# produce the plot
plot(dd[sim], vars=(:d_rff, :d_rg10, :d_lur, :d_pic4), 
     legend=false, size=(600, 400));
```

```@setup frbus
savefig("irf.png")
```

[![Impulse Response Graph](irf.png)](irf.png)
