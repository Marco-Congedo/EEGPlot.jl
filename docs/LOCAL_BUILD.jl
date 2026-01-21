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
    sitename = " ", # ← space: hack to hide the name as it is in the logo
    authors="Marco Congedo, Tomas Ros",
    format = Documenter.HTML(repolink = "..."),
    modules = [EEGPlot],
    remotes = nothing, # ELIMINATE for deploying
    pages = [
        "index.md"
    ]
)

