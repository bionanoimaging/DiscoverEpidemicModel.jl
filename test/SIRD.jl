using DataFrames
using CSV
using Plots


gr()
### loading data #####
######################

df=CSV.File("time-series-19-covid-combined_csv.csv") |> DataFrame

### selecting data from a country
####################################

gdf=groupby(df, :Country)

country="US"
country_province_data=gdf[(country,)] |> DataFrame
country_province_matrix=Matrix(country_province_data)




### Here we should change the country_province_matrix and calculate sum of cases in each day, for provinces of a country
### otherwise we can use the row with the province field by "missing" value


### plotting the cumulitive data 
#################################
for_plot=country_province_matrix[:,4:6]
temp=Matrix{Int64}(undef, size(for_plot))
temp=convert.(Int64, values(for_plot))
plot(temp)

### daily confirmed, recovered and deaths
#########################################

s=size(temp)
daily=Matrix{Int64}(undef,s[1]-1, s[2])

for i in 1:3
    daily[:,i]=diff(temp[:,i])
end


### removing negative value which induced by errors in the dataset
for i in 1:3
    for j in 1:size(daily)[2]
        if daily[i,j]<0
            daily[i,j]=0
        end
    end
end
plot(daily[1:325,:])
vscodedisplay(daily')


### Calculating weekly average
###############################
using Statistics

s=size(temp)
weekly=Matrix{Float64}(undef,s[1]-7, s[2])
for i in 1:3
    weekly[:,i]=[mean(daily[j-6:j,i]) for j in 7:size(daily)[1]]
end
plot(weekly[1:320,:], alpha=0.7, label=["Confirmed" "recovered" "Death"])
xlims!(0,320)
ylims!(0,300000)

vscodedisplay(weekly)
### Calculating suseptibles
###########################

population=350000
suseptible=Vector{Float64}(undef,size(weekly)[1])
for i in 1:length(suseptible)
    suseptible[i]=population-sum(weekly[i,:])
end
plot!(suseptible[1:320], alpha=0.7, label="Susiptible")

data=Matrix{Float64}(undef,4,320)  ### There is no report for recovered after day 320 ############
data[1,:]=suseptible[1:320]
for i in 2:4
    data[i,:]=weekly[1:320,i-1]
end
vscodedisplay(data)

### saving the Data ##############

us_df=DataFrame(data', ["suseptible", "Infected", "Recovered", "Dead"])
CSV.write("us_data.csv", us_df)

### Reading the Data ############

raw_data=CSV.File("us_data.csv") |> DataFrame
data=Matrix(raw_data)'

### Normalising the Data ########

Max=maximum(data)
Min=minimum(data)
for i in 1:size(data)[1]
    for j in 1:size(data)[2]
        data[i,j]=(data[i,j]-Min)/(Max-Min)
    end
end

### modeling with Sindy ###############################
######################################################

using DataDrivenDiffEq
using ModelingToolkit, OrdinaryDiffEq, LinearAlgebra, Plots
using DataDrivenSparse

### definition of the problem

sir_problem=DiscreteDataDrivenProblem(data)

### definition of polynomial basis

@variables t w(t) x(t) y(t) z(t)
u = [w;x;y;z]
basis = Basis(polynomial_basis(u, 4), u, iv = t)


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


### Dynamic Mode Decomposition ##############################################
using DataDrivenDMD

@variables t x(t) y(t) z(t)
u = [x;y;z]
Ψ = Basis(polynomial_basis(u, 5), u, iv = t)


res = solve(sir_problem, basis, DMDPINV(), digits = 1)

system=get_basis(res)

println(get_basis(res))
params=get_parameter_map(system)



