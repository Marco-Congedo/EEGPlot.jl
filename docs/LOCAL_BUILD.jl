# Nota Bene: Run it while in the \docs environment (ALT+Enter)

push!(LOAD_PATH,"../src/")
push!(LOAD_PATH,"docs/src/")

using Documenter, DocumenterInterLinks, DocumenterTools, Revise

using Pkg
Pkg.activate(@__DIR__)
Pkg.develop(PackageSpec(path=joinpath(@__DIR__, "..")))  # Local EEGPlot
Pkg.instantiate()
using EEGPlot 

makedocs(
    sitename = " ", # ← space: hack to hide the name in the upper-left corner of the index.md page
    authors="Marco Congedo",
    format = Documenter.HTML(repolink = "..."),
    modules = [EEGPlot],
    remotes = nothing, # ELIMINATE for deploying
    pages = [
        "Home" => "index.md",
    ]
)

