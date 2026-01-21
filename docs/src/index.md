# EEGPlot.jl

**EEGPlot** in a julia package to plot electroencephalographic recording (EEG) and event-related potentials (ERP).

In all cases the dataset is a matrix ``X \in \mathbb{R}^{T \times N_X}``, where ``T`` is the number
of time samples and ``N_X`` the number of channels.

**EEGPlot** can show at the same one, two or three datasets, on two panels:
- the upper panel can show a dataset `X` and overlay another of the same shape,
- the lower panel can show a third dataset, ``Y \in \mathbb{R}^{T \times N_Y}``, where ``N_Y`` can be different from ``N_X``.

#### here goes a plot

## Requirements 

**Julia**: version ≥ 1.10

## ⚙️ Installation

Execute the following commands in Julia's REPL:

```julia
]add EEGPlot
```

## —͟͟͞͞★ Quick Start

!!! note
    All examples make use of [Eegle.jl](https://github.com/Marco-Congedo/Eegle.jl) for reading example data.

    As backend for plotting library [Makie.jl](https://docs.makie.org/)
    `GLMakie` and `CairoMakie` are used. First, install the following packages:

    ```julia
    ]add Eegle, GLMakie, CairoMakie
    ```


```@example 1
using EEGPlot, Eegle, CairoMakie 

# read example EEG data, sampling rate 
# and sensor labels from Eegle.jl
X, sr = readASCII(EXAMPLE_Normative_1), 128;
sensors = readSensors(EXAMPLE_Normative_1_sensors);

# plot EEG with default settings
eegplot(X, sr, sensors; fig_size = (814, 510)) 
```

***

To generate an interactive plot, just use the GLMakie backend instead:

```julia
using GLMakie
GLMakie.activate!() # switch the backend

eegplot(X, sr, sensors)
```

## ✍️ About the authors

Generative AI supervised by [Marco Congedo](https://sites.google.com/site/marcocongedo) and [Tomas Ros](https://www.tomasros.com/).

## 🌱 Contribute

Please contact the authors if you are interested in contributing.

## 🎓 Documentation

The package exports only function:
