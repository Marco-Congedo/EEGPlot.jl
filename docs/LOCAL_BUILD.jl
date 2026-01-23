# Nota Bene: Run it while in the \docs environment (ALT+Enter)

push!(LOAD_PATH,"../src/")
push!(LOAD_PATH,"docs/src/")

using Pkg
Pkg.activate(@__DIR__)
Pkg.develop(PackageSpec(path=joinpath(@__DIR__, "..")))  # Local EEGPlot
Pkg.instantiate()
using EEGPlot 

using Documenter, DocumenterInterLinks

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

