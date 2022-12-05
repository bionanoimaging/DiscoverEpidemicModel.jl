using DiscoverEpidemicModel
using Documenter

DocMeta.setdocmeta!(DiscoverEpidemicModel, :DocTestSetup, :(using DiscoverEpidemicModel); recursive=true)

makedocs(;
    modules=[DiscoverEpidemicModel],
    authors="Morteza Babazadeh, Rainer Heintzmann, René Lachmann",
    repo="https://github.com/renerichter/DiscoverEpidemicModel.jl/blob/{commit}{path}#{line}",
    sitename="DiscoverEpidemicModel.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://renerichter.github.io/DiscoverEpidemicModel.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/renerichter/DiscoverEpidemicModel.jl",
    devbranch="main",
)
