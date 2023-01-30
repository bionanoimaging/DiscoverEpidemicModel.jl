using DataDrivenDiffEq
using ModelingToolkit, OrdinaryDiffEq, LinearAlgebra, Plots

gr()

## create a test problem from Lorenz system
function SIR(u, p, t)
    S, I, R= u
    Ṡ=-0.3*S*I
    İ=0.3*S*I-0.1*I
    Ṙ=0.1*I
    return [Ṡ, İ, Ṙ]
end

u0=[0.999; .001; 0.0]
tspan=(0.0, 100.0)
dt=1
problem=ODEProblem(SIR, u0, tspan)
data_SIR=solve(problem, Tsit5(), saveat=dt, atol=1e-7, rtol=1e-8)

tt=collect(0:1:100)
plot(tt,data_SIR[1,:], label="Suseptible")
plot!(tt,data_SIR[2,:], label="Infected")
plot!(tt,data_SIR[3,:], label="Removed")

######################################################
using DataDrivenDiffEq
using ModelingToolkit, OrdinaryDiffEq, LinearAlgebra, Plots
using DataDrivenSparse

### definition of the problem

tspan=(0,100)
data=data_SIR;
sir_problem=DataDrivenProblem(data, dt=1)

### definition of polynomial basis

@variables t x(t) y(t) z(t)
u = [x;y;z]
basis = Basis(polynomial_basis(u, 2), u, iv = t)


### choosing STLSQ as an optimizer
### STLSQ is a sparsifying algorithm that cause the solve function to call its "Sindy" method ###

opt = STLSQ(exp10.(-5:0.1:-1))


### solving the problem to extract the model

ddsol = solve(sir_problem, basis, opt)#, options = DataDrivenCommonOptions(digits = 1))

### final differential equations

println(get_basis(ddsol))

### coefficients in the above differential equations

system=get_basis(ddsol);
params=get_parameter_map(system)

### plot to see the accuracy
plot(plot(sir_problem, title="data"),plot(ddsol, title="model"), layout=(1,2))


########################## Prediction ################################### 
####################### soluton as a callable struct #######################


function ddsol!(u, p, t)
    #û = system(u, p) # Recovered equations
    return system(u, p, t)
end


### recovering the first time range ###############
tspan=(0,100)
estimation_prob = ODEProblem(ddsol!, u0, tspan, get_parameter_values(system))
estimate = solve(estimation_prob, Tsit5(), saveat = 1)
plot(estimate, label=["Suseptible" "Infected" "Removed"])
plot!(estimate, ls=:dash, lw=2, label=["Suseptible" "Infected" "Removed"])

### predicting 30 days ############################
tspan=(0,130)
estimation_prob = ODEProblem(ddsol!, u0, tspan, get_parameter_values(system))
estimate = solve(estimation_prob, Tsit5(), saveat = 1)
plot(estimate, label=["Suseptible" "Infected" "Removed"])

### starting from an arbitrary time ###############
tspan=(0,40)
u0=[0.7, 0.1, 0.2]
estimation_prob = ODEProblem(ddsol!, u0, tspan, get_parameter_values(system))
estimate = solve(estimation_prob, Tsit5(), saveat = 1)
plot(estimate, label=["Suseptible" "Infected" "Removed"])


###################################################
"""
eqs=equations(system)
get_iv(system)

using ModelingToolkit
using DifferentialEquations

#@parameters σ=28.0 ρ=10.0 β=8/3 δt=0.1
#@variables t w(t)=1.0 x(t)=0.0 y(t)=0.0 z(t)=0.0

nn=length(get_parameter_map(system))
params_new=Matrix{Float64}(undef, nn,1)
#@parameters params_new[1:16]
for i in 1:nn
    params_new[i,1]=params[i][2]
end



tspan=(0,100)

@named sys = ODESystem(
    eqs, 
    get_iv(system), 
    states(system),
    parameters(system);
    #tspan=tspan
    )

#@named sys=NonlinearSystem(eqs, states(system), parameters(system))

ps = get_parameter_map(system)

u0map=data_SIR[:,1]#[w=>0.99, x=>0.01, y=>0.0, z=>0.0]
ode_prob = ODEProblem(sys, u0map, tspan, get_parameter_values(system))#, params_new)#ps)
#ode_prob = NonlinearProblem(sys, u0map)#, tspan, params_new)#ps)
estimate = solve(ode_prob, Tsit5(), saveat=1, atol=1e-7, rtol=1e-8);
plot(estimate)
xlims!(0,0.5)
ylims!(0,2)
vscodedisplay(data)
"""

