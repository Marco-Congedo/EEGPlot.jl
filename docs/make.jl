using Documenter
using CairoMakie 

# Force static backend for headless documentation building
CairoMakie.activate!()

using EEGPlot 

makedocs(
    sitename = "EEGPlot.jl",
    authors = "Marco Congedo, Tomas Ros",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://Marco-Congedo.github.io/EEGPlot.jl",
        edit_link = "master",  # Changed from "main" to "master"
        repolink = "https://github.com/Marco-Congedo/EEGPlot.jl"
    ),
    modules = [EEGPlot],
    pages = [
        "Home" => "index.md",
    ]
)

deploydocs(
    repo = "github.com/Marco-Congedo/EEGPlot.jl.git",
    devbranch = "master",   # Changed from "main" to "master"
    push_preview = true     # Allows you to see the docs before merging the PR
)