# Smets and Wouters 2007

## Reference

[Smets, F., Wouters, R., 2007. Shocks and frictions in US business cycles: A bayesian DSGE approach. The American Economic Review 97(3), 586–606.](https://www.aeaweb.org/articles?id=10.1257/aer.97.3.586)

## [Replication Data](@id replication_data)

The replication data can be downloaded from http://doi.org/10.3886/E116269V1<br>
You may need to create an account, if you don't already have one.
Download the zip file and extract its contents in the data/116269-V1/ directory.

```@setup sw07
using StateSpaceEcon
using ModelBaseEcon
using TimeSeriesEcon

using  ModelBaseEcon: parameters, variables, shocks, equations
```

## Part 1: the model

### Load the model

The model is described in its own dedicated module, which in turn is contained
in its own file, `SW07.jl`. We can load the module with `using SW07`, then the
model itself is a global variable called `model` within that module.

```@repl sw07
unique!(push!(LOAD_PATH, joinpath(pwd(), "..", "..", "src", "US_SW07"))) # hide
using SW07
m = SW07.model
```

### Examine the model

This model is too big to fit all of its details in the REPL window, so only a
summary information is displayed. We can see the entire model with `fullprint`.

```@repl sw07
fullprint(m)
```

We can also examine individual components using the commands `parameters`,
`variables`, `shocks`, `equations`.

```@repl sw07
parameters(m)
```

### Setting the model parameters

We must not change any part of the model in the running Julia session except for
the model parameters and steady state constraints. If we want to add variables,
shocks, or equations, we must do so in the model module file and restart Julia
to load the new model.

When it comes to parameters, we can access them by their names from the model
object using dot-notation.

```@repl sw07
# read a parameter value
m.crr
# modify a parameter value
m.cgy = 0.5187
```

!!! note In this model the values of the parameters have been set according to
the [`replication data`](@ref replication_data).







