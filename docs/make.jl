using Documenter
using EEGPlot

makedocs(
    sitename = "EEGPlot",
    authors="Marco Congedo, Tomas Ros",
    format = Documenter.HTML(),
    modules = [EEGPlot],
    pages = [
        "index.md"
    ]
)

deploydocs(
   repo = "github.com/Marco-Congedo/EEGPlot.jl.git",
   branch = "gh-pages",
   push_preview = true,
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
