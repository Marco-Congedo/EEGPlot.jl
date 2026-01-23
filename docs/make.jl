# docs/make.jl
# Works whether run from /docs or /EEGPlot
curdir = @__DIR__
if lowercase(basename(@__DIR__)) == lowercase("EEGPlot")
    curdir = joinpath(curdir, "docs")
end

using Pkg
Pkg.activate(curdir)
Pkg.instantiate()                # install dependencies

# Use local EEGPlot
Pkg.develop(path=joinpath(curdir, ".."))

using Documenter
using CairoMakie   # headless backend
using EEGPlot

ci = get(ENV, "CI", "false") == "true"

makedocs(
    sitename = " ",  # hide package name in corner
    authors = "Marco Congedo",
    modules = [EEGPlot],
    pages = [
        "Home" => "index.md",
    ],
)

if ci
    deploydocs(
        repo = "github.com/Marco-Congedo/EEGPlot.jl.git",
        push_preview = true,  # allows preview for PRs
    )
else
    include("local_run.jl")  # optional local run
end
