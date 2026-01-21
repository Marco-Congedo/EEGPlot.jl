using Documenter
using EEGPlot

makedocs(
    sitename = "EEGPlot",
    format = Documenter.HTML(),
    modules = [EEGPlot]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
