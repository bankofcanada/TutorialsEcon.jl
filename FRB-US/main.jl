
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
# update models files if necessary

models_path = joinpath(mypath, "models")

if !isfile(joinpath(models_path, "FRBUS_VAR.jl")) || (
        isfile(joinpath(models_path, "frbus_package.zip")) && mtime(joinpath(models_path, "FRBUS_VAR.jl")) 
            < mtime(joinpath(models_path, "frbus_package.zip")))
    @info "Updating model files"
    include("update_models.jl")
end

## ##########################################################################
# load model

unique!(push!(LOAD_PATH, joinpath(mypath, "models")))

using FRBUS_VAR

m = FRBUS_VAR.model

## ##########################################################################
# load longbase data

include("load_longbase.jl")
longbase = load_longbase("longbase_23072020.csv")

## ##########################################################################
# set policy functions

include("set_policy.jl")

## ##########################################################################
# 

# simulation range
simstart = 2020Q1
simend = 2025Q4

sim = simstart:simend
ini = (-m.maxlag:-1) .+ simstart
fin = simend .+ (1:m.maxlead)

# simulation plan
p = Plan(m, sim)

# exogenous data
ed = zerodata(m, p)

ed .= longbase[p.range]

# set the monetary policy rule
set_mp!(ed, :dmpintay)

# turn off zero bound and policy thresholds; 
# hold policy maker's perceived equilibrium real interest rate
ed.dmptrsh .= 0.0
ed.rffmin .= -9999
ed.drstar .= 0.0

# set fiscal policy
set_fp!(ed, :dfpsrp)

nothing
## ##########################################################################
# back out shocks

p_0 = autoexogenize!(copy(p), m, sim)
ed_0 = copy(ed)
sol_0 = @time simulate(m, ed_0, p_0; verbose=true, tol=1e-12)

## ##########################################################################
# recover baseline simulation with the shocks

p_r = Plan(m, sim)
ed_r = zerodata(m, p_r)

# initial conditions from longbase
ed_r[ini, m.variables] = longbase[ini, m.variables]

# add a little bit of noise as initial guess for the Newton-Raphson solver
ed_r[sim, m.variables] = longbase[sim, m.variables] .+ 0.01.*randn(length(sim), length(m.variables))

# shocks from sol_0
ed_r[p_r.range, m.shocks] = sol_0[p_r.range, m.shocks]

# exogenous variables from sol_0 
exogenous = m.variables[isexog.(m.variables)]
ed_r[p_r.range, exogenous] = sol_0[p_r.range, exogenous]

set_mp!(ed_r, :dmpintay)
ed_r.dmptrsh .= 0.0
ed_r.rffmin .= -9999
ed_r.drstar .= 0.0
set_fp!(ed_r, :dfpsrp)

sol_r = simulate(m, ed_r, p_r, verbose=true, tol=1e-9)

@test sol_r ≈ sol_0

## ##########################################################################
# simulate shock

p_1 = Plan(m, sim)
ed_1 = copy(sol_0)

ed_1.rffintay_a[simstart] += 1
sol_1 = @time simulate(m, ed_1, p_1;  verbose=true, tol=1e-9)

## ##########################################################################
# plot IRF

using Plots

dd_ours = hcat(SimData(p.range), 
    d_rff=sol_1.rff - sol_0.rff,
    d_rg10=sol_1.rg10 - sol_0.rg10,
    d_lur=sol_1.lur - sol_0.lur,
    d_pic4=sol_1.pic4 - sol_0.pic4,
)

plot(dd_ours[sim], 
    vars=(:d_rff, :d_rg10, :d_lur, :d_pic4),
)

