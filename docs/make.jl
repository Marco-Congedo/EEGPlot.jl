push!(LOAD_PATH,"../src/")
push!(LOAD_PATH,"docs/src/")

using Documenter
using CairoMakie   # headless backend
using EEGPlot

makedocs(
    sitename = " ",  # hide package name in corner
    authors = "Marco Congedo",
    modules = [EEGPlot],
    pages = [
        "Home" => "index.md",
    ],
)

if get(ENV, "CI", "false") == "true"
    deploydocs(
        repo = "github.com/Marco-Congedo/EEGPlot.jl.git",
        push_preview = true,  # allows preview for PRs
    )
else
    include("local_run.jl")  # optional local run
end
