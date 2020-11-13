# FRB-US with VAR-based Expectations

You can follow the tutorial by reading this page and copying and pasting code
into your Julia REPL session. In this case, you will need the model file
[`FRBUS_VAR.jl`](./models/FRBUS_VAR.jl).

All the code contained here is also available in this file: [`main.jl`](main.jl).

```@contents
Pages = ["main.md"]
Depth = 3
```

```@setup frbus
using StateSpaceEcon
using ModelBaseEcon
using TimeSeriesEcon

using Test
using Plots
using Random
using Distributions

# Fix the random seed for reproducibility.
Random.seed!(1234);

# We need the model file FRBUS_VAR.jl to be on the search path for modules.
unique!(push!(LOAD_PATH, joinpath(mypath, "models"))) # hide

```





