# EEGPlot.jl

A *julia* package based on [Makie.jl](https://docs.makie.org/) to plot electroencephalographic recording (EEG) and event-related potentials (ERP). 

## ⚙️ Static and Interactive mode

Two backends for `Makie.jl` are supported:

- `CairoMakie.jl`, which produces a **STATIC** plot — mainly for saving figures;
- `GLMakie.jl`, which produces an **INTERACTIVE** plot — for data inspection.

!!! note "Switching backend"
    To switch from one backend to the other, use `GLMakie.activate!()` and `CairoMakie.activate!()`.

***

## 📈 Datasets

**EEGPlot** can plot several datasets at the same time, employing two panels:

- the *upper panel* showa an EEG/ERP dataset and can, optionally, overlay another one with the exact same dimension. 

!!! tip "Dataset overlay"
    Using an interactive plot, it is simple to view only the first dataset, only the second, the first and the second or their difference;

- the *lower panel* can show yet another dataset, which may have a different number of channels.

!!! tip "Panel Synchronization"
    When both panels are used, scrolling and zooming in the datasets on the upper and lower panel is **synchronized**.
    This is very useful in several situations, such as inspecting a dataset along with its spatial filters or source separation components, 
    inspecting a dataset decomposed in artifacts plus a cleaned component, etc.

***

## 🧩 Requirements 

- *julia* version ≥ 1.10,
- *Makie* version ≥ 0.24.8,
- the *CairoMakie* and/or *GLMakie* backend for *Makie.jl*.

***

## 📦 Installation

Execute the following commands in Julia's REPL:

```julia
]add https://github.com/Marco-Congedo/EEGPlot.jl
```

***

## —͟͟͞͞★ Quick Start

The following examples use [Eegle.jl](https://github.com/Marco-Congedo/Eegle.jl) for reading example data
and of both *Makie's* backends `GLMakie` and `CairoMakie`. First, install these packages:

```julia
]add Eegle, GLMakie, CairoMakie
```

***

#### Index of working examples

- [Static Plots](@ref) 
- [Plotting Multiple Datasets](@ref) 
- [Interactive Plots](@ref) 
- [ERPs](@ref)

See also [Examples](@ref).

***

### Static Plots

```@example Static; eval=false
using EEGPlot, Eegle, CairoMakie

# read example EEG data, sampling rate and sensor labels from Eegle
X, sr = readASCII(EXAMPLE_Normative_1), 128;
sensors = readSensors(EXAMPLE_Normative_1_sensors);

# plot EEG
eegplot(X, sr, sensors; fig_size=(814, 450)) 

```
[▲ Index of working examples](@ref "Index of working examples")

***

### Plotting Multiple Datasets

The following example illustrates the inspection of [PCA](https://en.wikipedia.org/wiki/Principal_component_analysis) components. The workflow is :

- compute ``u``, the principal axis of data ``X``, as the eigenvector of its covariance matrix associated to the largest eigenvalue,
- compute ``y``, the principal component time series (principal component score or activation), as 
```math
y = X u,
```
- compute ``P``, the data ``X`` projected on this component (subspace projection), as
```math
P = y u^T,
```
- plot ``X`` and overlay ``P`` on the upper panel, ``y`` on the lower panel.

```@example Multiple; eval=false
using EEGPlot, Eegle, LinearAlgebra, CairoMakie

# read example EEG data, sampling rate and sensor labels from Eegle
X, sr = readASCII(EXAMPLE_Normative_1), 128;
sensors = readSensors(EXAMPLE_Normative_1_sensors);

u = eigvecs(covmat(X; covtype=SCM))[:, end]
y = X * reshape(u, :, 1) # using reshape, y will be a Tx1 Matrix
P = y * u'
eegplot(X, sr, sensors; overlay=P, Y=y, Y_size=0.1, fig_size=(814, 614))
```
In the plot above, we see ``X`` in dark grey, ``P`` in brick red and ``y`` in green.

[▲ Index of working examples](@ref "Index of working examples")

***

### Interactive Plots

It is obtained using the *GLMakie* backend instead. The syntax of `eegPlot` does not change ta all. For example, to obtain an interactive plot
of the PCA above, we would do

```julia
using GLMakie

# since you may have been using CairoMakie, make sure to switch backend
GLMakie.activate!()

# read example EEG data, sampling rate and sensor labels from Eegle
X, sr = readASCII(EXAMPLE_Normative_1), 128;
sensors = readSensors(EXAMPLE_Normative_1_sensors);

u = eigvecs(covmat(X; covtype=SCM))[:, end]
y = X * reshape(u, :, 1) # using reshape, y will be a Tx1 Matrix
P = y * u'

# The syntax is exactly the same as above
eegplot(X, sr, sensors; overlay=P, Y=y, Y_size=0.1)
```
Such plots allows [interactions](@ref "Interactions"). It looks like this:

![](assets/fig2.png)

Note that in addition to static plots, interactive plots feature:
- a *central slider* to resize the upper and lower panels,
- a *slider at the bottom of the window* to scroll the data,
- an *help panel* summarizing the interaction controls. 

!!! warning "Check the task bar"
    Interactive plots open as a separate window. The window may open minimized. 

[▲ Index of working examples](@ref "Index of working examples")

***

### ERPs

For an example of plotting evoked potentials, we will consider the example P300 file
provided by `Eegle.jl`. In P300 experiments, we are interested in two classes of ERP, named "target" and "nontarget".
Please see [Eegle.ERPs](https://marco-congedo.github.io/Eegle.jl/stable/ERPs/)
for details on the ERP computations.

```@example ERP; eval=false
using EEGPlot, Eegle, CairoMakie
CairoMakie.activate!()

# read the example file for the P300 BCI paradigm
o = readNY(EXAMPLE_P300_1, rate=4, upperLimit=1.2, bandPass=(1, 24)) # See Eegle.readNY

# compute means (adaptive weights and multivariate regression)
M = mean(o; overlapping=true, weights=:a) # See Eegle.mean

# target and non-target average ERP
T_ERP = M[findfirst(isequal("target"), o.clabels)]
NT_ERP = M[findfirst(isequal("nontarget"), o.clabels)]

eegplot(T_ERP, o.sr, o.sensors; 
        fig_size = (812, 450),
        overlay = NT_ERP, 
        Y_labels = o.sensors,
        win_length = o.wl, # trial length in samples
        px_per_sec = 720,
        init_scale = 0.7,
        X_title = "EPR target (grey) and nontarget (red)")
```

[▲ Index of working examples](@ref "Index of working examples")

***

## 🔌 API

The package exports one function only:

```julia
function eegplot(X, sr, X_labels; args...)
```

### Arguments

1. a matrix ``X \in \mathbb{R}^{T \times N_X}`` for the upper panel, where ``T`` and ``N_X`` are the number of samples and channels,
2. the sampling rate of dataset ``X`` (Int),
3. the labels of ``X`` (Vector of String), which can be omitted.

### Optional Keyword Arguments (kwargs)

| Argument          | Type              | Description               | Default value     |
|:------------------|:------------------|:--------------------------|:------------------|
| `fig_size`        | 2-tuple of Int    | size of the plot          | (1400, 800)       |
| `X_title`         | String            | title of the upper panel  | nothing           |
| `X_color`         | Symbol ([named color](https://juliagraphics.github.io/Colors.jl/stable/namedcolors/)) | color of ``X`` dataset | :grey24 | 
| `overlay`         | Matrix ``\in \mathbb{R}^{T \times N_X}``  | ``overlay`` dataset       | nothing           |
| `overlay_color`   | Symbol ([named color](https://juliagraphics.github.io/Colors.jl/stable/namedcolors/)) | color of the ``overlay`` dataset| :firebrick |
| `diff_color`      | Symbol ([named color](https://juliagraphics.github.io/Colors.jl/stable/namedcolors/)) | color of the difference ``X - overlay``| :cornflower |
| `Y`               | Matrix ``\in \mathbb{R}^{T \times N_Y}``   | lower panel dataset       | nothing           |
| `Y_labels`        | Vector of String  | lower panel labels        | nothing           |
| `Y_title`         | String            | title of the lower panel  | nothing           |
| `Y_color`         | Symbol ([named color](https://juliagraphics.github.io/Colors.jl/stable/namedcolors/)) | color of lower panel dataset| :darkgreen|
| `Y_size`          | 0.05 < Real < 0.95 | title of the lower panel  | nothing           |
| `i_panel`         | Bool              | help panel visibility     | true              |
| `i_panel_font`    | String            | help panel font           | "DejaVu Sans"     |
| `i_panel_font_size`| Int ≥ 4          | help panel font size     | 14                |
| `start_pos`       | Int ≥ 1           | first sample to show      | 1 (first sample)  |
| `win_length`      | Int ≥ 0;  0 = Auto| number of samples to show | 0                 |
| `px_per_sec`      | Int ≥ 100         | number of pixels to cover 1s | 200            |
| `init_scale`      | Real > 0          | initial scaling           | 0.61803...        |
| `scale_change`    | Real > 0          | speed of scale change using [Interactions](@ref) | 0.1   |
| `image_quality`   |  1 ≤ Int ≤ 4      | Image quality for saving using [Interactions](@ref) | 1  |

***

## 💡 Examples

In these examples it is assumed the existence of data ``X\in \mathbb{R}^{T \times N_X}`` with sampling rate `sr` and labels `sensors`.

```julia
using EEGPlot, CairoMakie # or GLMakie for interactive plots

# Plot with default settings
eegplot(X, sr, sensors)

# Save a figure with large size and high quality (ppi)
# (for saving figures CairoMakie is preferable)
fig = eegplot(X, sr, sensors; 
            fig_size = (3000, 1000), 
            image_quality = 4)
save("figure.png", fig)

# Plot without providing labels for X
eegplot(X, sr)

# Two panels; Y must have the same # of samples as X
eegplot(X, sr, sensors; 
        Y = X)

# Overlay; must have the same # of samples and of channels as X
eegplot(X, sr, sensors; 
        overlay = X)

# Both overlay and two panels
eegplot(X, sr, sensors; 
        overlay = X, 
        Y = X)

# Change pixels per second (time-constant)
eegplot(X, sr, sensors; 
        px_per_sec = 300)

# Notice that the data is plotted with the same time-constant
# regardless the sampling rate. For example, doubling the sr
using Eegle # for `resample`
eegplot(resample(X, sr, 2), 256, sensors; 
        px_per_sec = 300)

# Change titles and colors
eegplot(X, sr, sensors; 
        Y = X, 
        X_title = "This the title for the upper panel",
        X_color = :blue,
        Y_title = "This the title for the lower panel",
        Y_color = :darkviolet,
        )

# Start plotting from second 2    
heegplot(X, sr, sensors; 
        start_pos = sr*2)

# Start plotting from an arbitrary sample (345)
eegplot(X, sr, sensors; 
        start_pos = 345)

# Plot from sample 345 to sample 345+sr*2 (2s)
eegplot(X, sr, sensors; 
        start_pos = 129, 
        win_length = sr*4)

```

***

## 🎮 Interactions

The following commands are available only in [interactive mode](@ref "Static and Interactive mode").

!!! warning "Set Focus"
    If the plot does not respond to the controls, set the focus on the plot by clicking anywhere on it.

### ⌨ Keyboard controls

*▴ Upper Panel*

- *'X'*: show the ``X`` dataset
- *'O'*: show the ``overlay`` dataset (if `overlay` [kwarg](@ref "Optional Keyword Arguments (kwargs)") is passed)
- *'B'*: show both ``X`` and ``overlay`` dataset (*idem*)
- *'D'*: show the difference ``X - overlay`` (*idem*)
- *Shift + ↑/↓*: scale ``X`` up/down (use `scale_change` [kwarg](@ref "Optional Keyword Arguments (kwargs)"))

*▾ Lower Panel* (if `Y` [kwarg](@ref "Optional Keyword Arguments (kwargs)") is passed)

- *'Y'*: toggle Y data (lower panel) visibility 
- *Ctrl + ↑/↓*: scale ``Y`` up/down (use `scale_change` [kwarg](@ref "Optional Keyword Arguments (kwargs)"))
- *Slider*: resize the lower panel

*⌖ Navigation* (apply to all visible panels)
- *←/→*: scroll backward and forward the dataset(s) 
- *↑/↓*: scale up and down the dataset(s) (use `scale_change` [kwarg](@ref "Optional Keyword Arguments (kwargs)"))
- *Page Up*: move to begin of dataset(s)
- *Page Down*: move to end of dataset(s)

*⚙ Tools*

- *'M'*: toggle the status of the plot window (maximized/normal)
- *'Esc'*: restore the normal status if the window is maximized
- *'S'*: save the plot in the current directory as a *.png* file (use `image_quality` [kwarg](@ref "Optional Keyword Arguments (kwargs)"))
- *'C'*: copy the plot to the clipboard
- *'H'*: toggle the visibility of the help panel

### ⊕ Mouse Controls

- *Click & Drag*: zoom along the time-axis
- *Ctrl + Click*: reset the view as it was before zooming.

***

## ✍️ About the authors

[Marco Congedo](https://sites.google.com/site/marcocongedo), [Tomas Ros](https://www.tomasros.com/) and Generative AI.

***

## 🌱 Contribute

Please contact the authors if you are interested in contributing.

## 🧭 Index

```@contents
Pages = ["index.md"]
Depth = 3
```
