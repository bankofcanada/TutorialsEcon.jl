
"""
Simple RBC Model
Model available at: https://archives.dynare.org/DynareShanghai2013/order1.pdf
Presentation: Villemot, S., 2013. First order approximation of stochastic models. Shanghai Dynare Workshop.
"""
module simple_RBC

using ModelBaseEcon

const model = Model()

model.flags.ssZeroSlope = true
setoption!(model) do o
    o.tol = 1e-14
    o.maxiter = 100
    o.substitutions = false
    o.factorization = :qr
    o.verbose = true
end # options

@parameters model begin
    α = 0.33
    δ = 0.1
    ρ = 0.03
    λ = 0.97
    γ = 0
    g = 0.015
    β = @link 1/(1+ρ)
end # parameters

@logvariables model begin
    "Consumption" C
    "Capital Stock" K
    "Labour" L
    "Real Wage" w
    "Real Rental Rate" r
    "Technological shock" A
end # variables

@shocks model ea

@autoexogenize model begin
    A = ea
end # autoexogenize

@equations model begin
    @log 1/(C[t]) = β * (1 / (C[t+1]*(1+g))) * (r[t+1]+1-δ)
    @log (L[t])^γ = w[t] / C[t]
    @log r[t] = α * A[t] * (K[t-1]/(1+g)) ^ (α-1) * (L[t]) ^ (1-α)
    @log w[t] = (1-α) * A[t] * (K[t-1]/(1+g)) ^ α * (L[t]) ^ (-α)
    @lin K[t] + C[t] = A[t] * (K[t-1]/(1+g)) ^ α * (L[t]) ^ (1-α) + (1-δ) * (K[t-1]/(1+g))
    log(A[t]) = λ * log(A[t-1]) + ea[t]
end # equations

@initialize(model)

end # module


