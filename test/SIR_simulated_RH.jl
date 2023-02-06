using DataDrivenDiffEq
using DataDrivenSparse
using ModelingToolkit, OrdinaryDiffEq, LinearAlgebra, Plots

# gr()

## create a test problem from SIR system
function SIR(u, p, t)
    S, I, R= u
    Ṡ=-0.03*S*I
    İ=0.03*S*I-0.01*I
    Ṙ=0.01*I
    return [Ṡ, İ, Ṙ]
end

function sim1()
    u0=[0.9999; .0001; 0.0]
    steps=1_000
    tspan=(0, steps)
    dt=1

    ######################################################################
    ###################### Continuous Form  ##############################
    ######################################################################

    problem=ODEProblem(SIR, u0, tspan)
    data_SIR=solve(problem, Tsit5(), saveat=dt)#, atol=1e-7, rtol=1e-8)

    tt=collect(0:1:steps)
    plot(tt,data_SIR[1,:], label="Suseptible")
    plot!(tt,data_SIR[2,:], label="Infected")
    plot!(tt,data_SIR[3,:], lael="Removed")
end

#xlims!(1,35)
######################################################

### definition of the problem
function sim2()
    tspan=(0,steps)
    data=data_SIR;
    sir_problem=DataDrivenProblem(data, dt=1)

    ### definition of polynomial basis

    @variables t x(t) y(t) z(t)
    u = [x;y;z]
    basis = Basis(polynomial_basis(u, 2), u, iv = t)


    ### choosing STLSQ as an optimizer
    ### STLSQ is a sparsifying algorithm that cause the solve function to call its "Sindy" method ###

    opt = STLSQ(exp10.(-10:0.1:-1))

    ### solving the problem to extract the model

    ddsol = solve(sir_problem, basis, opt)#, options = DataDrivenCommonOptions(digits = 1))

    ### final differential equations

    println(get_basis(ddsol))

    ### coefficients in the above differential equations

    system=get_basis(ddsol);
    params=get_parameter_map(system)


    ### plot to see the accuracy
    plot(plot(sir_problem, title="data"),plot(ddsol, title="model"), layout=(1,2))
end


####################### Simulation #######################

function ddsol!(u, p, t)
    #û = system(u, p) # Recovered equations
    return system(u, p, t)
end

function sim3()

    estimation_prob = ODEProblem(ddsol!, u0, tspan, get_parameter_values(system))
    estimate = solve(estimation_prob, Tsit5(), saveat = 1)
    plot(estimate, label=["Suseptible" "Infected" "Removed"], color=[:blue :red :green])
    plot!(data, ls=:dash, lw=2,  label=["Suseptible" "Infected" "Removed"], color=[:blue :red :green])

    new_steps=steps+100
    tspan=(0,new_steps)
    estimation_prob = ODEProblem(ddsol!, u0, tspan, get_parameter_values(system))
    estimate = solve(estimation_prob, Tsit5(), saveat = 1)
    problem=ODEProblem(SIR, u0, tspan)
    data_new=solve(problem, Tsit5(), saveat=dt)#, atol=1e-7, rtol=1e-8)
    plot(estimate, label=["Suseptible" "Infected" "Removed"], color=[:blue :red :green])
    plot!(data_new, ls=:dash, lw=2,  label=["Suseptible" "Infected" "Removed"], color=[:blue :red :green])
end

#########################################################################
############################### Discrete Form ###########################
#########################################################################
function ddsol!(u, p, t)
    #û = system(u, p) # Recovered equations
    return system(u, p, t)
end

function sim4()
    u0=[0.9999; .0001; 0.0]
    steps=1_000
    tspan=(0, steps)
    dt=1

    problem=DiscreteProblem(SIR, u0, tspan)
    data_SIR=solve(problem, Tsit5(), saveat=dt)#, atol=1e-7, rtol=1e-8)

    tt=collect(0:1:steps)
    plot(tt,data_SIR[1,:], label="Suseptible")
    plot!(tt,data_SIR[2,:], label="Infected")
    plot!(tt,data_SIR[3,:], label="Removed")

######################################################

### definition of the problem

    tspan=(0,steps)
    data=data_SIR;
    sir_problem=DiscreteDataDrivenProblem(data, dt=1)

    ### definition of polynomial basis

    @variables t x(t) y(t) z(t)
    u = [x;y;z]
    basis = Basis(polynomial_basis(u, 2), u, iv = t)


    ### choosing STLSQ as an optimizer
    ### STLSQ is a sparsifying algorithm that cause the solve function to call its "Sindy" method ###

    opt = STLSQ(exp10.(-10:0.1:-1))

    ### solving the problem to extract the model

    ddsol = solve(sir_problem, basis, opt)#, options = DataDrivenCommonOptions(digits = 1))

    ### final differential equations

    println(get_basis(ddsol))

    ### coefficients in the above differential equations

    system=get_basis(ddsol);
    params=get_parameter_map(system)

    ### plot to see the accuracy
    plot(ddsol, title="model")
    plot(plot(sir_problem, title="data"),plot(ddsol, title="model"), layout=(1,2))
####################### Simulation #######################

    function SIR_discov(u, p, t; ddsol)
        system=get_basis(ddsol);
        # params=get_parameter_map(system)
        return system
    end

    problem=ODEProblem(ddsol!, u0, tspan) # SIR(u, p, t)
    problem=ODEProblem((u,p,t)->SIR_discov(u,p,t; ddsol=ddsol), u0, tspan) # SIR(u, p, t)

    estimation_prob = DiscreteProblem(ddsol!, u0, tspan, get_parameter_values(system))
    estimate = solve(estimation_prob, Tsit5(), saveat = 1)
    plot(estimate, label=["Suseptible" "Infected" "Removed"], color=[:blue :red :green])
    plot!(data, ls=:dash, lw=2,  label=["Suseptible" "Infected" "Removed"], color=[:blue :red :green])
end
