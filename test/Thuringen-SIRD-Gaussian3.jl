using DataFrames
using CSV
using Plots
using ModelingToolkit, OrdinaryDiffEq, LinearAlgebra
using DifferentialEquations
using DataDrivenDiffEq
using DataDrivenSparse
using StatsPlots
using Statistics
using Distributions


############################################################################
############################################################################
#################### Making the Data #######################################
begin
    training_days=660 #674 days are recorded
    raw_data=CSV.File("Thuringen_SIRD.csv") |> DataFrame
    data=Matrix(raw_data[:,[2, 3, 4]])'

    Max=2_000_000#maximum(data)
    Min=minimum(data)
    for i in 1:size(data)[1]
        for j in 1:size(data)[2]
            data[i,j]=(data[i,j]-Min)/(Max-Min)
        end
    end 

    ############# Beta distribution
    #d=Beta(1.5,2.5)
    #plot(d)

    function factors(α, β, n) ## Beta distribution, coefficients for n days needed (Infected)
        d=Beta(α, β)
        max=pdf(d, mode(d))
        step=1/(n+2-1)
        steps=collect(0.0:step: 1.0)
        coefs=zeros(length(steps))
        for i in eachindex(coefs)
            coefs[i]=pdf(d,steps[i])/max
        end
        return steps[2:end-1], coefs[2:end-1]
    end

    n=21  #### number of days that infection rate of each patient changes
    vals, cofs=factors(1.5,2.5,n) #### α=1.5 and β=2.5, we can change the curve shape by changing α and β

    #plot(cofs)
    #plot!(data')
    ###############################  factors should be  used ######################

    infectious=zeros(674,1);

    #cofs1=reverse(cofs)
    for i in 2:lastindex(infectious)  
        for j in 1:min(n,i-1)
            infectious[i]=infectious[i] + data[1, i-j] * cofs[j]
        end
    end
    #plot(infectious, fill=true, alpha=0.2)

    #xlims!(0,200)
    #ylims!(0,0.0005)
    data1=copy(data)
    data1[2,:]=infectious
    data2=data1[:,1:training_days]
    #### I D
    #X=data1[:,1:674] # data or data1
    X=data2
    #plot(data', fill=true)

    plot(X', label=["Infected" "Infectious Level" "Death"], title="Data")
end
############################################################################
############################################################################
############################# Making control signal ########################
begin
    v_raw_data=CSV.File("Thuringen_daily_vaccination.csv") |> DataFrame
    v_data=Matrix{Float64}(v_raw_data[:,3:5])'


    Max=2_000_000#maximum(v_data)
    Min=minimum(v_data)
    for i in 1:size(v_data)[1]
        for j in 1:size(v_data)[2]
            v_data[i,j]=(v_data[i,j]-Min)/(Max-Min)
        end
    end

    #plot(v_data')
    ####  weekly averaging
    avg_days=7
    s=size(v_data)
    weekly=Matrix{Float64}(undef,s[1], s[2]-avg_days)
    for i in 1:3
        weekly[i,:]=[mean(v_data[i, j-avg_days+1:j]) for j in avg_days:s[2]-1]'
    end
    #plot(weekly', fill=true)

    #weekly=v_data[:,7:end]
    #plot(weekly')
    ############# beta distribution  
    #d=Beta(3,3)
    #plot(d)

    function vfactors(α, β, n) ## Beta distribution, coefficients for n days needed (Infected)
        d=Beta(α, β)
        upto=mode(d)
        max=pdf(d, mode(d))
        step=upto/(n-1)
        steps=collect(0.0:step: upto)
        coefs=zeros(length(steps))
        for i in eachindex(coefs)
            coefs[i]=pdf(d,steps[i])/max
        end
        return steps, coefs
    end

    n=21 ## number of days needed to reach the peak of antibody level after vaccination
    vvals, vcofs=vfactors(4,4,n) #### α=4 and β=4, we can change the curve shape by changing α and β
    #plot(vcofs)


    ###############################  factors should be reversed and used ######################
    dose1=zeros(545,1);
    dose2=zeros(545,1);
    dose3=zeros(545,1);

    vcofs1=reverse(vcofs)
    for i in 1:lastindex(dose1)
        for j in 1:min(n,i)-1
            dose1[i]=dose1[i] + weekly[1, i-j] * vcofs1[j]
            dose2[i]=dose2[i] + weekly[2, i-j] * vcofs1[j]
            dose3[i]=dose3[i] + weekly[3, i-j] * vcofs1[j]
        end 
    end

    #plot(dose1)
    #plot!(dose2)
    #plot!(dose3)


    #plot!(weekly', fill=true)

    dose11=zeros(674,1);
    dose21=zeros(674,1);
    dose31=zeros(674,1);

    for i in 289+avg_days:lastindex(dose11)
        dose11[i]=dose1[i-289+avg_days-1]
        dose21[i]=dose2[i-289+avg_days-1]
        dose31[i]=dose3[i-289+avg_days-1]
    end

    #plot(dose11)
    control=vcat(dose11', dose21', dose31') ### used in prediction
    control1=vcat(dose11[1:training_days]', dose21[1:training_days]', dose31[1:training_days]') ### used in model
    plot(control1', label=["Dose1" "Dose2" "Dose3"], title="Antibody Level")
    #ylims!(0,0.4)
    #plot!(data1', fill=true)

end

#################################################################################
#################################################################################
######################## definition and solving of the problem ##################
begin
    t=collect(0.0:1.0:training_days-1);
    itp_method=InterpolationMethod(LinearInterpolation)
    sir_problem=ContinuousDataDrivenProblem(X, t, itp_method, U = control1)

    #@variables w(t) x(t) y(t) z(t) c(t)
    #u=collect([w;x;y;z])
    #c=collect([c])

    @variables u[1:3] c[1:3]
    u = collect(u)
    c = collect(c)

    #h = Num[polynomial_basis(u, 1); c]
    h = Num[polynomial_basis([u; c], 2);]# exp(c[1]);exp(c[2]);exp(c[3]);]


    basis = Basis(h, u, controls=c)


    ### choosing STLSQ as an optimizer
    ### STLSQ is a sparsifying algorithm that cause the solve function to call its "Sindy" method ###
    opt = STLSQ(exp10.(-1:0.01:15))

    #################################### solving the problem to extract the model
    #using StableRNGs
    #rng = StableRNG(1337)

    #sampler = DataProcessing(split = 0.95, shuffle=true, batchsize = 70, rng = rng)

    ddsol = solve(sir_problem, basis, opt)#, options = DataDrivenCommonOptions(data_processing = sampler, digits = 1))#, options = DataDrivenCommonOptions(data_processing = sampler), digits = 1)
    plot(plot(sir_problem, title="data"),plot(ddsol, title="model"), layout=(1,2))
    ### final differential equations
    #println(get_basis(ddsol))

end
##################################################################
################## recovering the dynamic########################
begin
    ##### range of prediction ####
    start=training_days
    finish=673


    res=ddsol
    sys = get_basis(res)
    println(sys)


    # Optimal parameters
    p_opt = get_parameter_values(sys)
    z0=data1[:,start]
    ztspan=(start,finish)


    function get_dose1(t)
        return control[1, Int(round(t+1))]
    end

    function get_dose2(t)
        return control[2, Int(round(t+1))]
    end

    function get_dose3(t)
        return control[3, Int(round(t+1))]
    end

    # Generate a closure on the system 
    f_recovered = let doese_1 = get_dose1 , dose_2=get_dose2, dose_3=get_dose3
        (x, p, t) -> sys(x, p, t, [doese_1.(t); dose_2.(t); dose_3.(t)])
    end
end

############################################################
############################################################
################### ODE#####################################
begin
    prediction_prob = ODEProblem(f_recovered, z0, ztspan, p_opt)
    prediction = solve(prediction_prob, Tsit5(), saveat=1)
    plot(plot(prediction, label=["Infected" "Infectious Level" "Death"], title="Prediction"), plot(data1[:,start:finish]', label=["Infected" "Infectious Level" "Death"], title="Data"))
end

#########################################################
#########################################################
#################### stochastic #########################
begin
    t_step=1
    beta=0.1
    g(u,p,t)=beta*u   #### stochastic function and its parameters

    ################## StatsPlots ################
    y1 = fill(NaN, finish-start+1, 5000);
    y2 = fill(NaN, finish-start+1, 5000);
    y3 = fill(NaN, finish-start+1, 5000);
    for i  in 1:5000
        prediction_prob = SDEProblem(f_recovered, g, z0, ztspan, p_opt)
        prediction = solve(prediction_prob, EM(), dt=t_step)
        M=Matrix(prediction)
        #tmp=extractInfected(M[1,:], start, finish, data[1,:], cofs)
        y1[:,i]=M[1,:]
        y2[:,i]=M[2,:]
        y3[:,i]=M[3,:]
    end

    errorline(1:finish-start+1, y1[:,:]*2_000_000, errorstyle=:plume, label="Infected(Predicted)")
    plot!(data1[1,start:finish]*2_000_000, label="Data", lw=2, ls=:dash)
end

errorline(1:finish-start+1, y3[:,:]*2000000, errorstyle=:plume, label="Death(Predicted)")
plot!(data1[3,start:finish]*2000000, label="Data")
ylims!(0,5)

