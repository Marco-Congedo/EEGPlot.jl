using Documenter
using CairoMakie 

# Force static backend for headless documentation building
CairoMakie.activate!()

using Documenter, DocumenterInterLinks

using Pkg
Pkg.activate(@__DIR__)
Pkg.develop(PackageSpec(path=joinpath(@__DIR__, "..")))  # Local EEGPlot
Pkg.instantiate()
using EEGPlot 


makedocs(
    sitename = "EEGPlot.jl",
    authors = "Marco Congedo, Tomas Ros",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        edit_link = "master",  
        repolink = "..."
    ),
    modules = [EEGPlot],
    pages = [
        "Home" => "index.md",
    ]
)

deploydocs(
    repo = "github.com/Marco-Congedo/EEGPlot.jl.git",
    devbranch = "master",   
    push_preview = true     # Allow to see the docs before merging the PR
)