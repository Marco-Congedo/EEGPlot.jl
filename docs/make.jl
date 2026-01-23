
# allow being runned from within the /docs or /EEGPlots environment
# allow being run from within /docs or /EEGPlot
curdir = @__DIR__
if lowercase(basename(@__DIR__)) == lowercase("EEGPlot")
    curdir = joinpath(curdir, "docs")
end

using Pkg
Pkg.activate(curdir)

Pkg.develop(path=joinpath(curdir, ".."))  # local EEGPlot
Pkg.instantiate()                         

using Documenter
using CairoMakie
using EEGPlot

ci = get(ENV, "CI", "false") == "true"

makedocs(
    sitename = " ", # hack to hide the name of the pkg in the upper-left corner of the index.md page
    authors = "Marco Congedo",          # (as the name is in the logo, we do not need it)
    modules = [EEGPlot],
    pages = [
        "Home" => "index.md",
    ],
)

if ci
    deploydocs(
        repo = "github.com/Marco-Congedo/EEGPlot.jl.git", 
        # Allow to see the docs before merging the PR. They will be cleaned up by an action
        push_preview = true     
    )
else 
    include("local_run.jl")
end

