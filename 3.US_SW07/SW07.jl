
"""
Smets and Wouters 2007
Model available at: https://www.macromodelbase.com/ under "US_SW07"
Also at: https://github.com/IMFS-MMB/mmb-rep/tree/master/US_SW07
Paper: Smets, F., Wouters, R., 2007. Shocks and frictions in US business cycles: A bayesian DSGE approach. The American Economic Review 97(3), 586–606.
"""
module SW07

using ModelBaseEcon

model = Model()
model.flags.ssZeroSlope = true

@parameters model begin
    # fixed parameters
    ctou = .025;      # depreciation rate
    clandaw = 1.5;    # SS markup labor market
    cg = 0.18;        # exogenous spending GDP-ratio
    curvp = 10;       # curvature Kimball aggregator goods market
    curvw = 10;       # curvature Kimball aggregator labor market

    # estimated parameters initialisation
    ctrend = 0.4312;                  # quarterly trend growth rate to GDP
    cgamma = @link ctrend / 100 + 1;
    constebeta = 0.1657;
    cbeta = @link 100 / (constebeta + 100);     # discount factor
    constepinf = 0.7869;              # quarterly SS inflation rate
    cpie = @link constepinf / 100 + 1;
    constelab = 0.5509;
    
    calfa = 0.1901;           # labor share in production

    csigma = 1.3808;          # intertemporal elasticity of substitution
    cfc = 1.6064; 
    cgy = 0.5187;
    
    csadjcost = 5.7606;      # investment adjustment cost
    chabb =     0.7133;       # habit persistence 
    cprobw =    0.7061;       # calvo parameter labor market
    csigl =     1.8383; 
    cprobp =    0.6523;       # calvo parameter goods market
    cindw =     0.5845;       # indexation labor market
    cindp =     0.2432;       # indexation goods market
    czcap =     0.5462;       # capital utilization
    crpi =      2.0443;       # Taylor rule reaction to inflation
    crr =       0.8103;       # Taylor rule interest rate smoothing
    cry =       0.0882;       # Taylor rule long run reaction to output gap
    crdy =      0.2247;       # Taylor rule short run reaction to output gap
    
    crhoa =     0.9577;
    crhob =     0.2194;
    crhog =     0.9767;
    crhoqs =    0.7113;
    crhoms =    0.1479; 
    crhopinf =  0.8895;
    crhow =     0.9688;
    cmap =      0.7010;
    cmaw  =     0.8503;

    # derived from steady state
    clandap = @link cfc;
    cbetabar = @link cbeta * cgamma^(-csigma);
    cr = @link cpie / (cbeta * cgamma^(-csigma));
    crk = @link (cbeta^(-1)) * (cgamma^csigma) - (1 - ctou);
    cw = @link (calfa^calfa * (1 - calfa)^(1 - calfa) / (clandap * crk^calfa))^(1 / (1 - calfa));
    cikbar = @link (1 - (1 - ctou) / cgamma);
    cik = @link (1 - (1 - ctou) / cgamma) * cgamma;
    clk = @link ((1 - calfa) / calfa) * (crk / cw);
    cky = @link cfc * (clk)^(calfa - 1);
    ciy = @link cik * cky;
    ccy = @link 1 - cg - cik * cky;
    crkky = @link crk * cky;
    cwhlc = @link (1 / clandaw) * (1 - calfa) / calfa * crk * cky / ccy;
    cwly = @link 1 - crk * cky;
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
    ea; eb; eg; em; epinf; eqs; ew;
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

    # flexible economy
    0 * (1 - calfa) * a[t] + 1 * a[t] = calfa * rkf[t] + (1 - calfa) * (wf[t])
    zcapf[t] = (1 / (czcap / (1 - czcap))) * rkf[t]
    rkf[t] = (wf[t]) + labf[t] - kf[t]
    kf[t] = kpf[t - 1] + zcapf[t]
    "investment Euler equation"
    invef[t] = (1 / (1 + cbetabar * cgamma)) * (invef[t - 1] + cbetabar * cgamma * invef[t + 1] + (1 / (cgamma^2 * csadjcost)) * pkf[t]) + qs[t]
    pkf[t] = -rrf[t] - 0 * b[t] + (1 / ((1 - chabb / cgamma) / (csigma * (1 + chabb / cgamma)))) * b[t] + (crk / (crk + (1 - ctou))) * rkf[t + 1] + ((1 - ctou) / (crk + (1 - ctou))) * pkf[t + 1]
    "consumption Euler equation"
    cf[t] = (chabb / cgamma) / (1 + chabb / cgamma) * cf[t - 1] + (1 / (1 + chabb / cgamma)) * cf[t + 1] + ((csigma - 1) * cwhlc / (csigma * (1 + chabb / cgamma))) * (labf[t] - labf[t + 1]) - (1 - chabb / cgamma) / (csigma * (1 + chabb / cgamma)) * (rrf[t] + 0 * b[t]) + b[t]
    "aggregate resource constraint"
    yf[t] = ccy * cf[t] + ciy * invef[t] + g[t] + crkky * zcapf[t]
    "aggregate production function"
    yf[t] = cfc * (calfa * kf[t] + (1 - calfa) * labf[t] + a[t])
    wf[t] = csigl * labf[t] + (1 / (1 - chabb / cgamma)) * cf[t] - (chabb / cgamma) / (1 - chabb / cgamma) * cf[t - 1]
    "accumulation of installed capital"
    kpf[t] = (1 - cikbar) * kpf[t - 1] + (cikbar) * invef[t] + (cikbar) * (cgamma^2 * csadjcost) * qs[t]

    # sticky price - wage economy
    "marginal cost"
    mc[t] = calfa * rk[t] + (1 - calfa) * (w[t]) - 1 * a[t] - 0 * (1 - calfa) * a[t]
    "capital utilization"
    zcap[t] = (1 / (czcap / (1 - czcap))) * rk[t]
    "rental rate of capital"
    rk[t] = w[t] + lab[t] - k[t]
    "Capital installed used one period later in production"
    k[t] = kp[t - 1] + zcap[t]
    "investment Euler equation"
    inve[t] = (1 / (1 + cbetabar * cgamma)) * (inve[t - 1] + cbetabar * cgamma * inve[t + 1] + (1 / (cgamma^2 * csadjcost)) * pk[t]) + qs[t]
    "arbitrage equation for value of capital"
    pk[t] = -r[t] + pinf[t + 1] - 0 * b[t] + (1 / ((1 - chabb / cgamma) / (csigma * (1 + chabb / cgamma)))) * b[t] + (crk / (crk + (1 - ctou))) * rk[t + 1] + ((1 - ctou) / (crk + (1 - ctou))) * pk[t + 1]
    "consumption Euler equation"
    c[t] = (chabb / cgamma) / (1 + chabb / cgamma) * c[t - 1] + (1 / (1 + chabb / cgamma)) * c[t + 1] + ((csigma - 1) * cwhlc / (csigma * (1 + chabb / cgamma))) * (lab[t] - lab[t + 1]) - (1 - chabb / cgamma) / (csigma * (1 + chabb / cgamma)) * (r[t] - pinf[t + 1] + 0 * b[t]) + b[t]
    "aggregate resource constraint"
    y[t] = ccy * c[t] + ciy * inve[t] + g[t] + 1 * crkky * zcap[t]
    "aggregate production function"
    y[t] = cfc * (calfa * k[t] + (1 - calfa) * lab[t] + a[t])
    "Phillips Curve"
    pinf[t] = (1 / (1 + cbetabar * cgamma * cindp)) * (cbetabar * cgamma * pinf[t + 1] + cindp * pinf[t - 1] + ((1 - cprobp) * (1 - cbetabar * cgamma * cprobp) / cprobp) / ((cfc - 1) * curvp + 1) * (mc[t])) + spinf[t]
    w[t] = (1 / (1 + cbetabar * cgamma)) * w[t - 1] + (cbetabar * cgamma / (1 + cbetabar * cgamma)) * w[t + 1] + (cindw / (1 + cbetabar * cgamma)) * pinf[t - 1] - (1 + cbetabar * cgamma * cindw) / (1 + cbetabar * cgamma) * pinf[t] + (cbetabar * cgamma) / (1 + cbetabar * cgamma) * pinf[t + 1] + (1 - cprobw) * (1 - cbetabar * cgamma * cprobw) / ((1 + cbetabar * cgamma) * cprobw) * (1 / ((clandaw - 1) * curvw + 1)) * (csigl * lab[t] + (1 / (1 - chabb / cgamma)) * c[t] - ((chabb / cgamma) / (1 - chabb / cgamma)) * c[t - 1] - w[t]) + 1 * sw[t]

    "Monetary Policy Rule"
    r[t] = crpi * (1 - crr) * pinf[t] + cry * (1 - crr) * (y[t] - yf[t]) + crdy * (y[t] - yf[t] - y[t - 1] + yf[t - 1]) + crr * r[t - 1] + ms[t]
    a[t] = crhoa * a[t - 1] + ea[t]
    b[t] = crhob * b[t - 1] + eb[t]
    "exogenous spending (also including net exports)"
    g[t] = crhog * (g[t - 1]) + eg[t] + cgy * ea[t]
    qs[t] = crhoqs * qs[t - 1] + eqs[t]
    ms[t] = crhoms * ms[t - 1] + em[t]
    "cost push shock"
    spinf[t] = crhopinf * spinf[t - 1] + epinfma[t] - cmap * epinfma[t - 1]
    epinfma[t] = epinf[t]
    sw[t] = crhow * sw[t - 1] + ewma[t] - cmaw * ewma[t - 1]
    ewma[t] = ew[t]
    "accumulation of installed capital"
    kp[t] = (1 - cikbar) * kp[t - 1] + cikbar * inve[t] + cikbar * cgamma^2 * csadjcost * qs[t]

    # measurement equations
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
