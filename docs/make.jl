# Locally, run from within the /docs environment

using Pkg
Pkg.activate(@__DIR__)
Pkg.develop(path=joinpath(curdir, "..")) 
Pkg.instantiate()                         

using Documenter
using CairoMakie
using EEGPlot

# Set plotting to headless mode to prevent hangs
ENV["GKSwstype"] = "100"

makedocs(
    sitename = " ", # hack to hide the name of the pkg in the upper-left corner of the index.md page
    authors = "Marco Congedo",          # (as the name is in the logo, we do not need it)
    modules = [EEGPlot],
    pages = [
        "Home" => "index.md",
    ],
)

if get(ENV, "CI", "false") # true if is run by CI
    deploydocs(
        repo = "github.com/Marco-Congedo/EEGPlot.jl.git", 
        # Allow to see the docs before merging the PR. They will be cleaned up by an action
        push_preview = true     
    )
else 
    include("local_run.jl") # run docs locally using LiveServer.jl
end

