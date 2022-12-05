using DiscoverEpidemicModel
using Documenter

DocMeta.setdocmeta!(DiscoverEpidemicModel, :DocTestSetup, :(using DiscoverEpidemicModel); recursive=true)

makedocs(;
    modules=[DiscoverEpidemicModel],
    authors="Morteza Babazadeh, Rainer Heintzmann, René Lachmann",
    sitename="DiscoverEpidemicModel.jl",
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/bionanoimaging/DiscoverEpidemicModel.jl.git",
    devbranch="main",
)
