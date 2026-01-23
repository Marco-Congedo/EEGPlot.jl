

# allow being runned from within the /docs or /EEGPlots environment
curdir = @__DIR__
if lowercase(basename(@__DIR__)) == lowercase("EegPlot") 
    curdir = joinpath(curdir, "docs")
end

using Pkg
Pkg.activate(curdir)

using Documenter
using CairoMakie 

Pkg.develop(PackageSpec(path=joinpath(curdir, "..")))  # Local EEGPlot
Pkg.instantiate()
using EEGPlot 

ci = get(ENV, "CI", "false") == "true"

makedocs(
    sitename = " ", # hack to hide the package name in the upper-left corner (it is in the logo already)
    authors = "Marco Congedo",
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

# deploy docs if run remotely by CI.yml, otherwise run LiveServer to visualize the docs
if ci
    deploydocs(
        repo = "github.com/Marco-Congedo/EEGPlot.jl.git", 
        branch = "gh-pages",
        devbranch = "master",
        # Allow to see the docs before merging the PR. They will be cleaned up by an action
        push_preview = true     
    )
else 
    include("local_run.jl")
end