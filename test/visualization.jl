#url="https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv"
#download(url,"covid_data.csv")

using CSV,DataFrames,LsqFit
using PlutoUI,Shapefile,ZipFile
using Plots

#### Loading Data ################
data=CSV.File("covid_data.csv")|> DataFrame
names(data)

#### Separating one Country's data ##############
gd=groupby(data,:Country)
"""
We can change the country name here
"""
country="United Kingdom"
country_province_data=gd[(country,)] |> DataFrame
country_province_matrix=Matrix(country_province_data)
country_province_dates=country_province_matrix[:,5:end]
country_data=sum(eachrow(country_province_dates))


#us_row=filter(:Country=> n-> n=="US",data)
#df_temp=Matrix(us_row)
#us_data=Vector(df_temp[5:end])

#### Cumulitive Plot ##############################
scatter(country_data, m=:o, alpha=0.5, ms=3, xlabel="day", ylabel="cumulative cases in $country", legend=false)
#xlims!(700,750)
#ylims!(0,7000000)
### Showing by dates  ##########
using Dates

date_strings=String.(names(data)[5:end])

date_format=Dates.DateFormat("m/d/y")
dates=parse.(Date, date_strings, date_format)

plot(dates, country_data, xrotation=45, leg=:topleft, label="$country data", m=:o, ms=3, alpha=0.5)
xlabel!("data")
ylabel!("cumulitive cases")
title!("$country cumulitive confirmed cases")

### Daily Cases ###########################

daily_cases=diff(country_data)
plot(dates[2:end], daily_cases, m=:o, leg=false, alpha=0.5)
xlabel!("days")
ylabel!("daily $country cases")

### Plotting Weekly mean #########

using Statistics

running_mean=[mean(daily_cases[i-6:i]) for i in 7:length(daily_cases)]

#plot(daily_cases, label="raw daily cases")
#plot!(dates[7:end], running_mean, label="Weekly cases", m=:o, leg=:topleft)

daily_cases_n=daily_cases[7:end]
dates_n= dates[8:end]
weekly_cases_n=running_mean

plot(dates_n, daily_cases_n, xrotation=45, label="raw daily cases")
plot!(dates_n, weekly_cases_n, label="Weekly cases", m=:o, leg=:topleft)


### log plot #####################
#replace!(daily_cases, x-> x<0 => NaN)
for i in eachindex(daily_cases)
    if daily_cases[i]<0
        daily_cases[i]=daily_cases[i-1]
    end
end
plot(replace(daily_cases, 0=> NaN), yscale=:log10, leg=false, m=:o)
ylabel!("Confirmed cases in $country")
xlabel!("Day")
title!("$country confirmed COVID-19 cases")

xlims!(0,100)

exp_period=27:57

#Modeling the exponential exp_period
model(x,(c,α))=c.*exp.(α.*x)
p0=[0.5,0.5]
x_data=exp_period
y_data=daily_cases[exp_period]
fit=curve_fit(model, x_data, y_data, p0)
parameters=coef(fit)

plot(replace(daily_cases, 0=> NaN), yscale=:log10, leg=false, m=:o, alpha=0.5)
xlims!(0,100)

line_range=25:60
plot!(line_range ,model(line_range,parameters), lw=3, ls=:dash, alpha=0.7)
####################################################################











