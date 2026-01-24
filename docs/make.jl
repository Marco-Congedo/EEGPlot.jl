#push!(LOAD_PATH,"../src/")
#push!(LOAD_PATH,"docs/src/")

using Pkg
Pkg.activate(@__DIR__)
Pkg.develop(path=joinpath(@__DIR__, ".."))  # local EEGPlot
Pkg.instantiate()   

using Documenter
using CairoMakie   # headless backend
using EEGPlot

CI = get(ENV, "CI", "false") == "true"

makedocs(
    sitename = " ",  # hide package name in upper-left corner of page index.md
    authors = "Marco Congedo",
    modules = [EEGPlot],
    format = Documenter.HTML(;  prettyurls = CI,
                                sidebar_sitename = false,),
    pages = [
        "Home" => "index.md",
    ],
)

if CI
    deploydocs(
        repo = "github.com/Marco-Congedo/EEGPlot.jl.git",
        devbranch = "master",
        push_preview = true,  # allows preview for PRs
    )
else
    include("local_run.jl")  # optional local run
end
