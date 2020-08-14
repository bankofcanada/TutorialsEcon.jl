
"""
Smets and Wouters 2007
Model available at: https://www.macromodelbase.com/ under "US_SW07"
Paper: Smets, F., Wouters, R., 2007. Shocks and frictions in US business cycles: A bayesian DSGE approach. The American Economic Review 97(3), 586–606.
"""
module SW07

using ModelBaseEcon

model = Model()
model.flags.ssZeroSlope = true

# Define global constants
global const ctrend = 0.4312
global const cgamma = ctrend / 100 + 1
global const constepinf = 0.7869
global const cpie = constepinf / 100 + 1
global const cfc = 1.6064
global const clandap = cfc
global const csigma = 1.3808
global const constebeta = 0.1657
global const cbeta = 100 / (constebeta + 100) # discount factor
global const ctou = 0.0250
global const crk = (cbeta^(-1)) * (cgamma^csigma) - (1 - ctou)
global const calfa = 0.1901
global const cw = (calfa^calfa * (1 - calfa)^(1 - calfa) / (clandap * crk^calfa))^(1 / (1 - calfa))
global const cik = (1 - (1 - ctou) / cgamma) * cgamma
global const clk = ((1 - calfa) / calfa) * (crk / cw)
global const cky = cfc * (clk)^(calfa - 1)
global const cg = 0.1800
global const ccy = 1 - cg - cik * cky
global const clandaw = 1.5000

@parameters model begin
    cbetabar = cbeta * cgamma^(-csigma)
    cgy = 0.5187
    chabb = 0.7133
    cikbar = (1 - (1 - ctou) / cgamma)
    cindp = 0.2432
    cindw = 0.5845
    ciy = cik * cky
    cmap = 0.7010 
    cmaw = 0.8503
    constelab = 0.5509
    cprobp = 0.6523 
    cprobw = 0.7061 
    cr = cpie / (cbeta * cgamma^(-csigma))
    crdy = 0.2247 
    crhoa = 0.9577 
    crhob = 0.2194 
    crhog = 0.9767 
    crhoms = 0.1479 
    crhopinf = 0.8895 
    crhoqs = 0.7113 
    crhow = 0.9688
    crkky = crk * cky
    crpi = 2.0443 
    crr = 0.8103 
    cry = 0.0882 
    csadjcost = 5.7606 
    csigl = 1.8383 
    curvp = 10.0000
    curvw = 10.0000
    cwhlc = (1 / clandaw) * (1 - calfa) / calfa * crk * cky / ccy
    cwly = 1 - crk * cky 
    czcap = 0.5462
    
    # # Make all parameters (left-hand side) 
    # # equal to the global constants (right-hand side)
    # # Do not touch this part
    # ctrend = ctrend 
    # cgamma = cgamma
    # constepinf = constepinf
    # cpie = cpie
    # cfc = cfc
    # clandap = clandap
    # csigma = csigma
    # constebeta = constebeta
    # cbeta = cbeta
    # ctou = ctou
    # crk = crk
    # calfa = calfa
    # cw = cw
    # cik = cik
    # clk = clk
    # cky = cky
    # ccy = ccy
    # clandaw = clandaw
    
end

@variables model begin
    a; b; c; cf; dc;
    dinve; dw; dy; epinfma; ewma;
    g; inve; invef; k; kf;
    kp; kpf; lab; labf; labobs;
    mc; ms; pinf; pinf4; pinfobs;
    pk; pkf; qs; r; rk;
    rkf; robs; rrf; spinf; sw;
    w; wf; y; yf; zcap;
    zcapf;
end

@shocks model begin
    ea; eb; eg; em; epinf;
    eqs; ew;
end

@autoexogenize model begin
    labobs = eg
    robs = em
    pinfobs = epinf
    dy = ea
    dc = eb
    dinve = eqs
    dw = ew
end

@equations model begin
    0 * (1 - calfa) * a[t] + 1 * a[t] = calfa * rkf[t] + (1 - calfa) * (wf[t])
    zcapf[t] = (1 / (czcap / (1 - czcap))) * rkf[t]
    rkf[t] = (wf[t]) + labf[t] - kf[t]
    kf[t] = kpf[t - 1] + zcapf[t]
    invef[t] = (1 / (1 + cbetabar * cgamma)) * (invef[t - 1] + cbetabar * cgamma * invef[t + 1] + (1 / (cgamma^2 * csadjcost)) * pkf[t]) + qs[t]
    pkf[t] = -rrf[t] - 0 * b[t] + (1 / ((1 - chabb / cgamma) / (csigma * (1 + chabb / cgamma)))) * b[t] + (crk / (crk + (1 - ctou))) * rkf[t + 1] + ((1 - ctou) / (crk + (1 - ctou))) * pkf[t + 1]
    cf[t] = (chabb / cgamma) / (1 + chabb / cgamma) * cf[t - 1] + (1 / (1 + chabb / cgamma)) * cf[t + 1] + ((csigma - 1) * cwhlc / (csigma * (1 + chabb / cgamma))) * (labf[t] - labf[t + 1]) - (1 - chabb / cgamma) / (csigma * (1 + chabb / cgamma)) * (rrf[t] + 0 * b[t]) + b[t]
    yf[t] = ccy * cf[t] + ciy * invef[t] + g[t] + crkky * zcapf[t]
    yf[t] = cfc * (calfa * kf[t] + (1 - calfa) * labf[t] + a[t])
    wf[t] = csigl * labf[t] + (1 / (1 - chabb / cgamma)) * cf[t] - (chabb / cgamma) / (1 - chabb / cgamma) * cf[t - 1]
    kpf[t] = (1 - cikbar) * kpf[t - 1] + (cikbar) * invef[t] + (cikbar) * (cgamma^2 * csadjcost) * qs[t]
    mc[t] = calfa * rk[t] + (1 - calfa) * (w[t]) - 1 * a[t] - 0 * (1 - calfa) * a[t]
    zcap[t] = (1 / (czcap / (1 - czcap))) * rk[t]
    rk[t] = w[t] + lab[t] - k[t]
    k[t] = kp[t - 1] + zcap[t]
    inve[t] = (1 / (1 + cbetabar * cgamma)) * (inve[t - 1] + cbetabar * cgamma * inve[t + 1] + (1 / (cgamma^2 * csadjcost)) * pk[t]) + qs[t]
    pk[t] = -r[t] + pinf[t + 1] - 0 * b[t] + (1 / ((1 - chabb / cgamma) / (csigma * (1 + chabb / cgamma)))) * b[t] + (crk / (crk + (1 - ctou))) * rk[t + 1] + ((1 - ctou) / (crk + (1 - ctou))) * pk[t + 1]
    c[t] = (chabb / cgamma) / (1 + chabb / cgamma) * c[t - 1] + (1 / (1 + chabb / cgamma)) * c[t + 1] + ((csigma - 1) * cwhlc / (csigma * (1 + chabb / cgamma))) * (lab[t] - lab[t + 1]) - (1 - chabb / cgamma) / (csigma * (1 + chabb / cgamma)) * (r[t] - pinf[t + 1] + 0 * b[t]) + b[t]
    y[t] = ccy * c[t] + ciy * inve[t] + g[t] + 1 * crkky * zcap[t]
    y[t] = cfc * (calfa * k[t] + (1 - calfa) * lab[t] + a[t])
    pinf[t] = (1 / (1 + cbetabar * cgamma * cindp)) * (cbetabar * cgamma * pinf[t + 1] + cindp * pinf[t - 1] + ((1 - cprobp) * (1 - cbetabar * cgamma * cprobp) / cprobp) / ((cfc - 1) * curvp + 1) * (mc[t])) + spinf[t]
    w[t] = (1 / (1 + cbetabar * cgamma)) * w[t - 1] + (cbetabar * cgamma / (1 + cbetabar * cgamma)) * w[t + 1] + (cindw / (1 + cbetabar * cgamma)) * pinf[t - 1] - (1 + cbetabar * cgamma * cindw) / (1 + cbetabar * cgamma) * pinf[t] + (cbetabar * cgamma) / (1 + cbetabar * cgamma) * pinf[t + 1] + (1 - cprobw) * (1 - cbetabar * cgamma * cprobw) / ((1 + cbetabar * cgamma) * cprobw) * (1 / ((clandaw - 1) * curvw + 1)) * (csigl * lab[t] + (1 / (1 - chabb / cgamma)) * c[t] - ((chabb / cgamma) / (1 - chabb / cgamma)) * c[t - 1] - w[t]) + 1 * sw[t]
    r[t] = crpi * (1 - crr) * pinf[t] + cry * (1 - crr) * (y[t] - yf[t]) + crdy * (y[t] - yf[t] - y[t - 1] + yf[t - 1]) + crr * r[t - 1] + ms[t]
    a[t] = crhoa * a[t - 1] + ea[t]
    b[t] = crhob * b[t - 1] + eb[t]
    g[t] = crhog * (g[t - 1]) + eg[t] + cgy * ea[t]
    qs[t] = crhoqs * qs[t - 1] + eqs[t]
    ms[t] = crhoms * ms[t - 1] + em[t]
    spinf[t] = crhopinf * spinf[t - 1] + epinfma[t] - cmap * epinfma[t - 1]
    epinfma[t] = epinf[t]
    sw[t] = crhow * sw[t - 1] + ewma[t] - cmaw * ewma[t - 1]
    ewma[t] = ew[t]
    kp[t] = (1 - cikbar) * kp[t - 1] + cikbar * inve[t] + cikbar * cgamma^2 * csadjcost * qs[t]
    dy[t] = y[t] - y[t - 1] + ctrend
    dc[t] = c[t] - c[t - 1] + ctrend
    dinve[t] = inve[t] - inve[t - 1] + ctrend
    dw[t] = w[t] - w[t - 1] + ctrend
    pinfobs[t] = 1 * (pinf[t]) + constepinf
    pinf4[t] = pinf[t] + pinf[t - 1] + pinf[t - 2] + pinf[t - 3]
    robs[t] = 1 * (r[t]) + constebeta
    labobs[t] = lab[t] + constelab
end

@initialize(model)

end
