using DataDrivenDiffEq
using ModelingToolkit, OrdinaryDiffEq, LinearAlgebra, Plots

gr()

### create a test problem from Lorenz system
function lorenz(u, p, t)
    x, y, z= u
    ẋ=10.0*(y-x)
    ẏ=x*(28.0-z)-y
    ż=x*y-(8/3)*z
    return [ẋ, ẏ, ż]
end

u0=[-8.0; 7.0; 27.0]
tspan=(0.0, 100.0)
dt=0.001
problem=ODEProblem(lorenz, u0, tspan)
data=solve(problem, Tsit5(), saveat=dt, atol=1e-7, rtol=1e-8)


plot(data[1,:], data[2,:], data[3,:])

#############################################################
### Sindy ###################################################
using DataDrivenSparse

### definition of the problem
ddprob = DataDrivenProblem(data)

### definition of polynomial basis
@variables t x(t) y(t) z(t)
u = [x;y;z]
basis = Basis(polynomial_basis(u, 5), u, iv = t)

### choosing STLSQ as an optimizer
### STLSQ is a sparsifying algorithm that cause the solve function to call its "Sindy" method ###
opt = STLSQ(exp10.(-5:0.1:-1))

### solving the problem to extract the model
ddsol = solve(ddprob, basis, opt, options = DataDrivenCommonOptions(digits = 1))

### final differential equations
println(get_basis(ddsol))

### coefficients in the above differential equations
system=get_basis(ddsol);
params=get_parameter_map(system)

plot(plot(ddprob, title="data"),plot(ddsol, title="model"), layout=(1,2))


#############################################################################
### Dynamic Mode Decomposition ##############################################
using DataDrivenDMD

@variables t x(t) y(t) z(t)
u = [x;y;z]
Ψ = Basis(polynomial_basis(u, 5), u, iv = t)


res = solve(ddprob, Ψ, DMDPINV(), digits = 1)

system=get_basis(res)

println(get_basis(res))
params=get_parameter_map(system)


