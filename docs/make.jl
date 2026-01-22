using Documenter

using Pkg
Pkg.activate(@__DIR__)
Pkg.develop(PackageSpec(path=joinpath(@__DIR__, "..")))  # Local EEGPlot
Pkg.instantiate()
using EEGPlot 

makedocs(
    sitename = "EEGPlot",
    authors="Marco Congedo, Tomas Ros",
    format = Documenter.HTML(repolink = "..."),
    modules = [EEGPlot],
    pages = [
        "Home" => "index.md",
    ]
)

deploydocs(
   repo = "github.com/Marco-Congedo/EEGPlot.jl.git",
   branch = "gh-pages",
   # target = "build",
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
