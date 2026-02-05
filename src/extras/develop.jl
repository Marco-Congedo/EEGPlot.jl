#   This script is not part of the EEGPlot.jl package.
#   It allows to build the package locally from the source code,
#   without actually installing the package.
#   You won't need this script for using the package.
#   MUST USE JULIA V1.11.6 OR MUST DELETE THE MANIFEST.YOML FILE AND 
#   REACTIVATE THE ENVIRONMENT WITH: using Pkg; Pkg.activate("."); Pkg.instantiate()
#
#   MIT License
#   Copyright (c) 2026, Marco Congedo, CNRS, Grenobe, France:
#   https://sites.google.com/site/marcocongedo/home
#
#   DIRECTIONS:
#   1) If you have installed the EEGPlot.jl from github or Julia registry, uninstall it.
#   3) Run this block (With VS code, click anywhere here and hit ALT+Enter)
#
begin
  push!(LOAD_PATH, abspath(@__DIR__, "..") )
  using Revise, EEGPlot
end