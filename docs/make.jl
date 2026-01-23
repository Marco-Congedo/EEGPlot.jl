using Pkg
Pkg.activate(@__DIR__)
Pkg.develop(path=joinpath(@__DIR__, "..")) # local EEGPlot
Pkg.instantiate()                         

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
