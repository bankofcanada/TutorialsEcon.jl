
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
    C; K; L; w; r; A;
end # variables

@shocks model ea

@autoexogenize model begin
    A = ea
end # autoexogenize

@equations model begin
    @log 1/(C[t]) = β    * (1 / (C[t+1]*(1+g))) * (r[t+1]+1-δ)
    # 1/C    = beta * (1  / (C{+1}*(1+g))) * (r{+1} +1-delta);

    @log (L[t])^γ = w[t] / C[t]
    # L^gamma = w/C;

    # r[t] / A[t] = α     * (exp(logKL[t])) ^ (α-1)
    @log r[t] = α     * A[t] * (K[t-1]/(1+g)) ^ (α-1)     * (L[t]) ^ (1-α)
    # r  = alpha * A    * (K{-1}/(1+g))  ^ (alpha-1) * L      ^ (1-alpha);

    # w[t] / A[t] = (1-α) * (exp(logKL[t])) ^ α
    @log w[t] = (1-α)     * A[t] * (K[t-1]/(1+g)) ^ α      * (L[t]) ^ (-α)
    # w  = (1-alpha) * A    * (K{-1}/(1+g))  ^ alpha  * L      ^ (-alpha);

    # (K[t] + C[t]) / A[t] = ((exp(logKL[t])) ^ α)     * L[t]     + (1-δ)     * (K[t-1]/(1+g)) / A[t]
    K[t] + C[t] = A[t] * (K[t-1]/(1+g)) ^ α     * (L[t]) ^ (1-α)     + (1-δ)     * (K[t-1]/(1+g))
    # K  + C    = A    * (K{-1}/(1+g))  ^ alpha *  L     ^ (1-alpha) + (1-delta) * (K{-1}/(1+g));

    log(A[t]) = λ      * log(A[t-1]) + ea[t]
    # log(A)  = lambda * log(A{-1})  + ea;

end # equations

@initialize(model)

end # module
