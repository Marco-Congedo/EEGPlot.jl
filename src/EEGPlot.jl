module EEGPlot

using Makie
using GLFW
using Statistics
using ImageClipboard
using Colors

# colors for printing messages
const titleFont = "\x1b[38;5;71m"
const separatorFont = "\x1b[38;5;113m"
const defaultFont = "\x1b[0m"
const greyFont = "\x1b[90m"

export eegplot

# These structure and the `.process_interaction` function allows to manage both 
# click & drag and selecting (pickable) interactions
mutable struct PickAndZoom
    startpos::Union{Nothing,Point2f}
    picked_channel::Observable{Int}
    y_scale::Observable{Float32}
    n_chans::Int
    time_start::Observable{Float64}
    time_window::Observable{Float64}
    init_window::Float64  # <--- Add this
end

function Makie.process_interaction(
    interaction::PickAndZoom,
    event::Makie.MouseEvent,
    ax::Axis
)
    if event.type === MouseEventTypes.leftdown
        interaction.startpos = event.data
        return Consume(true)
    end

    if event.type === MouseEventTypes.leftup && interaction.startpos !== nothing
        # 1. Check for Ctrl + Click (Reset)
        mods = events(ax.scene).keyboardstate
        if Keyboard.left_control in mods || Keyboard.right_control in mods
            interaction.time_start[] = 0.0
            interaction.time_window[] = interaction.init_window
            interaction.picked_channel[] = 0 # Optional: clear selection on reset
            interaction.startpos = nothing
            return Consume(true)
        end

        # 2. If not Resetting, handle Zoom or Pick
        start_x, start_y = interaction.startpos
        end_x, end_y = event.data
        dist_x = abs(end_x - start_x)

        if dist_x > 0.005
            # It was a Drag -> Zoom
            x_min, x_max = extrema([start_x, end_x])
            interaction.time_start[] = x_min
            interaction.time_window[] = x_max - x_min
        else
            # It was a Click -> Pick
            y_val = end_y
            ch = round(Int, interaction.n_chans - (y_val / interaction.y_scale[]))
            if 1 <= ch <= interaction.n_chans
                interaction.picked_channel[] = (interaction.picked_channel[] == ch) ? 0 : ch
            end
        end

        interaction.startpos = nothing
        return Consume(true)
    end
    return Consume(false)
end

##########################################################

function eegplot(X::Matrix{T}, sr::Number, X_labels::Union{Vector{String},Nothing}=nothing;
    fig_size::Union{Symbol,Tuple{Int,Int}}=:auto,
    fig_padding::Int=5,
    font::String="DejaVu Sans",
    X_color::Symbol=:grey24,
    X_labels_font_size::Int=12,
    X_title::String="",
    X_title_font_size::Int=14,
    overlay::Union{Matrix{T},Nothing}=nothing,
    overlay_color::Symbol=:firebrick,
    diff_color::Symbol=:cornflowerblue,
    Y::Union{Matrix{T},Nothing}=nothing,
    Y_color::Symbol=:darkgreen,
    Y_labels::Union{Vector{String},Nothing}=nothing,
    Y_labels_font_size::Int=12,
    Y_title::String="",
    Y_title_font_size::Int=14,
    Y_size::Real=0.5,
    s_labels_font_size::Int=12,
    stim::Union{Vector{Int},Nothing}=nothing,
    stim_labels::Union{Vector{String},Nothing}=nothing,
    stim_colors::Union{Vector{<:Colorant},Nothing}=nothing,
    stim_wl::Int=1,
    stim_α::Real=begin
        stim_wl == 1 ? 0.8 : 0.16180339887498948
    end,
    stim_legend_font::Int=12,
    i_panel::Bool=true,
    i_panel_font_size::Int=13,
    init_scale::T=0.6180339887498948,
    scale_change::T=0.1,
    start_pos::Int=1,
    win_length::Int=0,
    px_per_sec::Int=180, # Constant scale: about 180 pixels = 1 second
    image_quality::Int=1,
) where {T<:Real}

    # Checks
    0 < scale_change < 1 || throw(ArgumentError("📉 argument `scale_change` must verify 0 < scale_change < 1"))
    1 ≤ image_quality ≤ 4 || throw(ArgumentError("📉 argument `image_quality` must verify 1 ≤ image_quality ≤ 4"))
    init_scale > 0 || throw(ArgumentError("📉 argument `init_scale` must be positive"))
    px_per_sec > 0 || throw(ArgumentError("📉 argument `px_per_sec` must be positive, usually in between 150 and 300"))
    mins = floor(Int, sr / 2)
    #win_length > 0 && win_length ≥ mins || throw(ArgumentError("`win_length` must comprise at least sr/2 samples"))
    #1 < start_pos < size(X, 1) - mins || throw(ArgumentError("`start_pos` must verify 1 < start_pos < size(X, 1) (it is given samples)"))
    i_panel_font_size ≥ 4 || throw(ArgumentError("📉 argument `i_panel_font_size` must be at least 4"))
    string(Makie.current_backend()) ∉ ("CairoMakie", "GLMakie", "WGLMakie") && throw(ErrorException("📉 eegplot can be rendered by CairoMakie.jl or WGLMakie.jl (static plots) and by GLMakie.jl (interactive plots). Make sure you are `using` at least one of those."))
    is_interactive = string(Makie.current_backend()) == "GLMakie"

    # ----------------------
    # Screen & Scaling Logic
    # ----------------------

    local screen_w, screen_h = 1920, 1080 # Default
    local actual_fig_size = (1400, 864) # Default fallback

    # Monitor detection
    if get(ENV, "JULIA_PLOT_HEADLESS", "false") == "false"
        try
            monitor = GLFW.GetPrimaryMonitor()
            if monitor != nothing && monitor.handle != C_NULL
                vidmode = GLFW.GetVideoMode(monitor)
                screen_w = vidmode.width
                screen_h = vidmode.height

                if fig_size == :auto
                    actual_fig_size = (Int(round(0.90 * screen_w)), Int(round(0.9 * screen_h)))
                else
                    actual_fig_size = fig_size
                end
            end
        catch
            actual_fig_size = (fig_size == :auto) ? (1400, 864) : fig_size
        end
    else
        actual_fig_size = (fig_size == :auto) ? (1400, 864) : fig_size
    end

    is_fixed = win_length > 0
    # Use 85% of target width for the plot area to leave room for side panels
    init_time_window = is_fixed ? (win_length / sr) : (0.85 * actual_fig_size[1] / px_per_sec)

    # ----------------------
    # Initialization
    # ----------------------
    n_samples, n_chans = size(X)
    duration = n_samples / sr
    final_X_labels = isnothing(X_labels) ? ["Ch$i" for i in 1:n_chans] : X_labels

    if !isnothing(overlay)
        n_samples_o, n_chans_o = size(overlay)
        n_samples_o != n_samples && throw(ArgumentError("📉 argument `overlay` must have the same number of samples (rows) as X."))
        n_chans_o != n_chans && throw(ArgumentError("📉 argument `overlay`  must have the same number of channels (columns) as X."))
    end

    print(titleFont, "\n📈  Producing an EEG plot... ")

    local n_chans_Y = 0
    local final_Y_labels = String[]
    if !isnothing(Y)
        n_samples_Y, n_chans_Y = size(Y)
        n_samples_Y != n_samples && throw(ArgumentError("📉 argument Y must have the same number of sample (rows) as X."))
        final_Y_labels = isnothing(Y_labels) ? [string(i) for i in 1:n_chans_Y] : Y_labels
    end

    # ----------------------
    # State (Observables)
    # ----------------------
    disp_mode = Observable(isnothing(overlay) ? "new" : "both")
    time_window = Observable(Float64(init_time_window))
    time_start = Observable(Float64(start_pos / sr))

    panel_visible = Observable(is_interactive && i_panel)
    y_panel_visible = Observable(!isnothing(Y))
    vsplit = Observable(1 - Y_size) # Matches slider startvalue
    tags_visible = Observable(true)

    # ----------------------
    # Stimulation Logic
    # ----------------------
    if !isnothing(stim)
        length(stim) == n_samples || throw(ArgumentError("📉 argument `stim` must have the same length as X ($(n_samples))"))

        unique_tags = sort(filter(x -> x > 0, unique(stim)))
        if isempty(unique_tags)
            throw(ArgumentError("📉 argument `stim` cannot be all zeros"))
        end

        n_classes = length(unique_tags)
        if unique_tags != collect(1:n_classes)
            throw(ArgumentError("📉 unique non-zero tags in `stim` must be contiguous integers starting from 1 (e.g., 1, 2, ...). Found: $(unique_tags)"))
        end

        # Handle labels
        if isnothing(stim_labels)
            stim_labels = [string(i) for i in 1:n_classes]
        elseif length(stim_labels) != n_classes
            throw(ArgumentError("📉 length of `stim_labels` ($(length(stim_labels))) must match number of classes ($(n_classes))"))
        end

        # Handle colors
        if isnothing(stim_colors)
            stim_colors = Colors.distinguishable_colors(n_classes, [RGB(1, 1, 1), RGB(0, 0, 0)], dropseed=true)
        elseif length(stim_colors) != n_classes
            throw(ArgumentError("📉 length of `stim_colors` ($(length(stim_colors))) must match number of classes ($(n_classes))"))
        end
    end


    # Initialize the picked channel observable
    picked_ch = Observable(0)

    y_scale = Observable(inv(init_scale / 5) * mean(abs.(X .- mean(X))))
    y_scale_Y = Observable(!isnothing(Y) ? inv(init_scale / 5) * mean(abs.(Y .- mean(Y))) : 1.0)

    # Legend elements if needed
    leg_ell = nothing
    if !isnothing(stim)
        if stim_wl == 1
            leg_ell = [LineElement(color=RGBA(c, stim_α), linestyle=nothing) for c in stim_colors]
        else
            leg_ell = [PolyElement(color=RGBA(c, stim_α), strokecolor=:transparent) for c in stim_colors]
        end
    end

    # ----------------------
    # Figure & Layout
    # ----------------------
    fig = Figure(size=actual_fig_size, figure_padding=fig_padding)

    plot_grid = fig[1, 1] = GridLayout(alignmode=Outside(5))
    axes_grid = plot_grid[1, 1] = GridLayout(rowgap=0)

    # Create Main Axis
    axX = Axis(axes_grid[1, 1]; title=X_title,
        titlefont=font,
        titlesize=X_title_font_size,
        xticklabelfont=font,
        xticklabelsize=Y_labels_font_size,
        yticklabelfont=font,
        yticklabelsize=X_labels_font_size)
    axX.titlecolor = :grey24
    axX.titlesize = X_title_font_size
    axX.xticklabelsize = s_labels_font_size
    axX.yticklabelsize = X_labels_font_size
    axX.elements[:title].pickable = false
    deactivate_interaction!(axX, :rectanglezoom)

    # Register the updated interaction for Main Axis
    register_interaction!(axX, :pick_and_zoom,
        PickAndZoom(
            nothing,
            picked_ch,
            y_scale,
            n_chans,
            time_start,
            time_window,
            init_time_window  # Added the reset value
        )
    )


    # Define Second Axis if needed
    local axY = nothing
    local splitter = nothing
    if !isnothing(Y)
        axY = Axis(axes_grid[3, 1]; title=Y_title,
            titlefont=font,
            titlesize=Y_title_font_size,
            xticklabelfont=font,
            xticklabelsize=Y_labels_font_size,
            yticklabelfont=font,
            yticklabelsize=Y_labels_font_size)
        axY.titlecolor = :grey24
        axY.titlesize = Y_title_font_size
        axY.xticklabelsize = s_labels_font_size
        axY.yticklabelsize = Y_labels_font_size
        axY.elements[:title].pickable = false
        deactivate_interaction!(axY, :rectanglezoom)
        # Register the updated interaction for Main Axis
        register_interaction!(axY, :pick_and_zoom,
            PickAndZoom(
                nothing,
                picked_ch,
                y_scale,
                n_chans,
                time_start,
                time_window,
                init_time_window  # Added the reset value
            )
        )

        # LINK AXES: This is crucial for synced zooming
        linkxaxes!(axX, axY)

        if is_interactive
            splitter = Slider(
                axes_grid[2, 1],
                range=0.05:0.01:0.95,
                startvalue=1.0 - vsplit[],
                linewidth=7,
                color_active=:grey50,
                color_inactive=:grey90,
                tellheight=true
            )

            on(splitter.value) do val
                vsplit[] = 1.0 - val
            end

            on(vsplit) do vs
                if y_panel_visible[]
                    rowsize!(axes_grid, 1, Relative(vs))
                    rowsize!(axes_grid, 2, Fixed(10))
                    rowsize!(axes_grid, 3, Relative(1 - vs))
                end
            end
        else
            rowsize!(axes_grid, 1, Relative(1 - Y_size))
            rowsize!(axes_grid, 2, Fixed(0))
            rowsize!(axes_grid, 3, Relative(Y_size))
        end
    end

    # ----------------------
    # Plot Stimulation Tags
    # ----------------------
    if !isnothing(stim)
        # Find indices and tags
        stim_indices = findall(x -> x > 0, stim)
        for idx in stim_indices
            tag = stim[idx]
            color = RGBA(stim_colors[tag], stim_α)
            t_val = (idx - 1) / sr

            if stim_wl == 1
                vlines!(axX, [t_val], color=color, visible=tags_visible)
                if !isnothing(axY)
                    vlines!(axY, [t_val], color=color, visible=tags_visible)
                end
            else
                t_end = (idx - 1 + stim_wl) / sr
                vspan!(axX, [t_val], [t_end], color=color, visible=tags_visible)
                if !isnothing(axY)
                    vspan!(axY, [t_val], [t_end], color=color, visible=tags_visible)
                end
            end
        end
    end

    notify(vsplit)

    # -----------------------------------------------------------
    # Axis Limits & Interaction Logic (The "Zoom" Fix)
    # -----------------------------------------------------------

    # Axis Limits setup (Moved viewport resize logic after display)
    if is_fixed
        colsize!(axes_grid, 1, Fixed(init_time_window * px_per_sec))
    end

    # 2. Update Observables when user zooms/drags with MOUSE

    #=
    on(events(fig).mousebutton) do ev
        if ev.button == Mouse.left && ev.action == Mouse.press
            xxx
        end
    end
    =#

    # register an interaction that runs at high priority so that the axis gets mouse events sooner
    on(events(fig).mousebutton, priority=10) do ev
        false  # consume nothing, just ensure event routing
    end

    # ----------------
    # Scrolling Slider
    # ----------------
    sl_range = lift(time_window) do tw
        # Use a high-resolution range to allow precise positioning
        range(0, stop=max(0, duration - tw), length=10000)
    end

    if is_interactive
        # Pass the exact initial time_start value here
        slider = Slider(plot_grid[2, 1], range=sl_range, startvalue=time_start[])
        rowsize!(plot_grid, 2, Fixed(10))

        # When slider moves, update time_start
        on(slider.value) do val
            time_start[] = val
        end

        # IMPORTANT: Use 'priority' or a check to prevent feedback loops
        # that might snap the value to a slider step.
        on(time_start) do ts
            if abs(slider.value[] - ts) > 1e-6
                set_close_to!(slider, ts)
            end
        end
    end

    # Explicitly trigger the first limit set
    notify(time_start)

    # ----------------------
    # Instructions Panel
    # ----------------------
    instr_text = """
          CONTROLS
      
     ✦  ⌨ Keyboard  ✦

    ▴ Upper Panel
    ─────────────────
    [X] show X data
    [O] show overlay
    [B] show both
    [D] show difference
    [Shift + ↑/↓] scale
    
    ▾ Lower Panel
    ─────────────────
    [Y] toggle Y data
    [Ctrl + ↑/↓] scale
    [Slider] resize

    ⌖ Navigation
    ─────────────────
    [←/→] scroll
    [↑/↓] scale
    [Page Up] begin
    [Page Down] end

    ⚙ Tools
    ─────────────────
    [M] toggle maximize
    [T] toggle tags
    [S] save (.png)
    [C] copy (clipboard)
    [H] toggle help

        ✦  ⊕ Mouse  ✦
    
    [Click & Drag] zoom
    [Ctrl + Click] reset
    """
    instr_panel = Label(fig[1, 3], instr_text;
        tellwidth=true,
        tellheight=false,
        halign=:left,
        valign=:center,
        justification=:left,
        font=font,
        fontsize=i_panel_font_size,
        padding=(10, 10, 10, 10))

    on(panel_visible) do vis
        instr_panel.visible[] = vis
        instr_panel.tellwidth[] = vis
        colsize!(fig.layout, 3, vis ? Auto() : 0)
    end


    if !isnothing(stim)
        stim_legend = Legend(fig[1, 2], leg_ell, stim_labels, "Classes";
            halign=:center, valign=:center,
            margin=(8, 2, 0, 0),
            titlefont=font,
            labelfont=font,
            labelsize=stim_legend_font,
            titlesize=stim_legend_font + 2)

        # Legend visibility depends ONLY on tags_visible
        on(tags_visible) do tv
            stim_legend.blockscene.visible[] = tv
            stim_legend.tellwidth[] = tv
            stim_legend.tellheight[] = false
            colsize!(fig.layout, 2, tv ? Auto() : 0)
        end


        # Initial state
        stim_legend.blockscene.visible[] = tags_visible[]
        stim_legend.tellwidth[] = tags_visible[]
        stim_legend.tellheight[] = false
    end

    # Initial setup
    colsize!(fig.layout, 1, Auto())
    colsize!(fig.layout, 2, !isnothing(stim) && tags_visible[] ? Auto() : 0)
    colsize!(fig.layout, 3, panel_visible[] ? Auto() : 0)

    # Force main row to fill fill the height
    rowsize!(fig.layout, 1, Relative(1))

    colgap!(fig.layout, 0)
    rowgap!(fig.layout, 0)

    # ----------------------
    # Plotting Logic
    # ----------------------

    # 1. Main Data Trace (X)
    points_X = lift(time_start, time_window, y_scale, disp_mode) do t_s, t_w, y_s, mode
        pts = Point2f[]
        (mode == "old" || mode == "diff") && return pts
        s_start = max(1, Int(floor(t_s * sr)) + 1)
        s_end = min(n_samples, Int(floor((t_s + t_w) * sr)))
        idx = s_start:s_end
        ts = (idx .- 1) ./ sr
        for ch in 1:n_chans
            offset = (n_chans - ch) * y_s
            for i in 1:length(ts)
                push!(pts, Point2f(ts[i], X[idx[i], ch] + offset))
            end
            push!(pts, Point2f(NaN, NaN))
        end
        return pts
    end

    # 2. Overlay Data Trace
    points_overlay = lift(time_start, time_window, y_scale, disp_mode) do t_s, t_w, y_s, mode
        pts = Point2f[]
        (isnothing(overlay) || mode == "new") && return pts
        s_start = max(1, Int(floor(t_s * sr)) + 1)
        s_end = min(n_samples, Int(floor((t_s + t_w) * sr)))
        idx = s_start:s_end
        ts = (idx .- 1) ./ sr
        for ch in 1:n_chans
            offset = (n_chans - ch) * y_s
            for i in 1:length(ts)
                val = (mode == "diff") ? (X[idx[i], ch] - overlay[idx[i], ch]) : overlay[idx[i], ch]
                push!(pts, Point2f(ts[i], val + offset))
            end
            push!(pts, Point2f(NaN, NaN))
        end
        return pts
    end

    # 3. PICK HIGHLIGHT (New Logic)
    # This creates a separate set of points for just the one picked channel
    picked_points = lift(time_start, time_window, y_scale, picked_ch, disp_mode) do t_s, t_w, y_s, pc, mode
        pts = Point2f[]
        (pc == 0 || mode == "old" || mode == "diff") && return pts

        s_start = max(1, Int(floor(t_s * sr)) + 1)
        s_end = min(n_samples, Int(floor((t_s + t_w) * sr)))
        idx = s_start:s_end
        ts = (idx .- 1) ./ sr

        offset = (n_chans - pc) * y_s
        for i in 1:length(ts)
            push!(pts, Point2f(ts[i], X[idx[i], pc] + offset))
        end
        return pts
    end

    # Draw background lines
    lines!(axX, points_X; color=X_color, linewidth=1)
    dynamic_overlay_color = lift(disp_mode) do m
        m == "diff" ? diff_color : overlay_color
    end
    lines!(axX, points_overlay; color=dynamic_overlay_color, linewidth=1)


    # 4. Y-Panel Logic
    if !isnothing(Y) && !isnothing(axY)
        points_Y = lift(time_start, time_window, y_scale_Y, y_panel_visible) do t_s, t_w, y_s_y, vis
            pts = Point2f[]
            !vis && return pts
            s_start = max(1, Int(floor(t_s * sr)) + 1)
            s_end = min(n_samples, Int(floor((t_s + t_w) * sr)))
            idx = s_start:s_end
            ts = (idx .- 1) ./ sr
            for ch in 1:n_chans_Y
                offset = (n_chans_Y - ch) * y_s_y
                for i in 1:length(ts)
                    push!(pts, Point2f(ts[i], Y[idx[i], ch] + offset))
                end
                push!(pts, Point2f(NaN, NaN))
            end
            return pts
        end
        lines!(axY, points_Y; color=Y_color, linewidth=1)
    end

    # 5. Axis Formatting & Label Highlighting
    onany(time_start, time_window, y_scale, y_scale_Y, picked_ch) do t_s, t_w, y_s, y_s_y, pc
        xlims!(axX, t_s, t_s + t_w)
        ylims!(axX, -y_s, n_chans * y_s)

        axX.yticks = ([(n_chans - i) * y_s for i in 1:n_chans], final_X_labels)

        # FIX: Change back to a single color to avoid the crash
        axX.yticklabelcolor = :grey24

        if !isnothing(axY)
            xlims!(axY, t_s, t_s + t_w)
            ylims!(axY, -y_s_y, n_chans_Y * y_s_y)
            axY.yticks = ([(n_chans_Y - i) * y_s_y for i in 1:n_chans_Y], final_Y_labels)
        end
    end

    # ----------------------
    # Keyboard Interaction
    # ----------------------
    original_window_state = Observable((x=30, y=30, w=actual_fig_size[1], h=actual_fig_size[2]))
    is_interactive && on(events(fig).keyboardbutton) do ev
        if ev.action in (Keyboard.press, Keyboard.repeat)
            step = time_window[] * 0.1
            mods = events(fig).keyboardstate

            # println(ev.key)

            # display mode for the upper panel
            if ev.key == Keyboard.x
                disp_mode[] = "new"
            elseif ev.key == Keyboard.o
                !isnothing(overlay) ? (disp_mode[] = "old") : println(separatorFont, "📈 This command requires the use of keyword argument `overlay`")
            elseif ev.key == Keyboard.b
                !isnothing(overlay) ? disp_mode[] = "both" : println(separatorFont, "📈 This command requires the use of keyword argument `overlay`")
            elseif ev.key == Keyboard.d
                !isnothing(overlay) ? disp_mode[] = "diff" : println(separatorFont, "📈 This command requires the use of keyword argument `overlay`")

                # Toggle window state (maximized, normal)
            elseif ev.key in (Keyboard.m, Keyboard.semicolon) # arranges both QWERTY and AZERTY Keyboards
                try
                    window = GLFW.GetCurrentContext()
                    win_w, win_h = GLFW.GetWindowSize(window)
                    vidmode = GLFW.GetVideoMode(GLFW.GetPrimaryMonitor())

                    if abs(win_w - vidmode.width) < 50 && abs(win_h - vidmode.height) < 50
                        orig = original_window_state[]
                        GLFW.RestoreWindow(window)
                        GLFW.SetWindowPos(window, orig.x, orig.y)
                        GLFW.SetWindowSize(window, orig.w, orig.h)
                    else
                        curr_x, curr_y = GLFW.GetWindowPos(window)
                        curr_w, curr_h = GLFW.GetWindowSize(window)
                        original_window_state[] = (x=curr_x, y=curr_y, w=curr_w, h=curr_h)
                        GLFW.RestoreWindow(window)
                        GLFW.SetWindowPos(window, 0, 0)
                        GLFW.SetWindowSize(window, vidmode.width, vidmode.height)
                    end
                catch e
                    @warn "📉 Help Toggling error: $e"
                end

            elseif ev.key == Keyboard.escape # exit maximize state 
                orig = original_window_state[]
                window = GLFW.GetCurrentContext()
                GLFW.RestoreWindow(window)
                GLFW.SetWindowPos(window, orig.x, orig.y)
                GLFW.SetWindowSize(window, orig.w, orig.h)

                # scale up, one or both panels
            elseif ev.key == Keyboard.up
                scale_down = 1.0 - scale_change
                if Keyboard.left_shift in mods || Keyboard.right_shift in mods
                    y_scale[] *= scale_down
                elseif Keyboard.left_control in mods || Keyboard.right_control in mods
                    y_scale_Y[] *= scale_down
                else
                    y_scale[] *= scale_down
                    y_scale_Y[] *= scale_down
                end

                # scale down, one or both panels    
            elseif ev.key == Keyboard.down
                scale_up = 1.0 + scale_change
                if Keyboard.left_shift in mods || Keyboard.right_shift in mods
                    y_scale[] *= scale_up
                elseif Keyboard.left_control in mods || Keyboard.right_control in mods
                    y_scale_Y[] *= scale_up
                else
                    y_scale[] *= scale_up
                    y_scale_Y[] *= scale_up
                end

                # scroll back
            elseif ev.key == Keyboard.left
                set_close_to!(slider, max(0.0, time_start[] - step))

                # scroll right
            elseif ev.key == Keyboard.right
                set_close_to!(slider, min(duration - time_window[], time_start[] + step))

                # go to begin of recording
            elseif ev.key == Keyboard.page_up
                set_close_to!(slider, 0.0)

                # go to end of recording
            elseif ev.key == Keyboard.page_down
                set_close_to!(slider, duration - time_window[])

                # toggle Help panel
            elseif ev.key == Keyboard.h
                panel_visible[] = !panel_visible[]

                # save image
            elseif ev.key == Keyboard.s
                i = 1
                while isfile("eeg_plot_$i.png")
                    i += 1
                end
                filename = "eeg_plot_$i.png"
                save(filename, Makie.colorbuffer(fig; px_per_unit=image_quality))
                @info (separatorFont, "📈 plot saved as $(filename)", defaultFont)

            elseif ev.key == Keyboard.t
                tags_visible[] = !tags_visible[]

                # copy image to Clipboard
            elseif ev.key == Keyboard.c
                clipboard_img(Makie.colorbuffer(fig; px_per_unit=image_quality))
                @info (separatorFont, "📈 plot copied to Clipboard", defaultFont)

                # Toggle down panel
            elseif ev.key in (Keyboard.y, Keyboard.z) && !isnothing(axY) # arranges both QWERTY and AZERTY keyboards
                y_panel_visible[] = !y_panel_visible[]
                if y_panel_visible[]
                    rowsize!(axes_grid, 1, Relative(vsplit[]))
                    rowsize!(axes_grid, 2, Fixed(10))
                    rowsize!(axes_grid, 3, Relative(1.0 - vsplit[]))
                    axY.blockscene.visible[] = true
                    splitter.blockscene.visible[] = true
                else
                    rowsize!(axes_grid, 1, Relative(1.0))
                    rowsize!(axes_grid, 2, Fixed(0))
                    rowsize!(axes_grid, 3, Fixed(0))
                    axY.blockscene.visible[] = false
                    splitter.blockscene.visible[] = false
                end
                trim!(axes_grid)

                # close
            elseif ev.key == Keyboard.s
                for win in GLFW.GetWindows()
                    GLFW.SetWindowShouldClose(win, true)
                end

            end
        end
    end

    notify(y_scale)
    if !isnothing(splitter)
        splitter.blockscene.visible[] = y_panel_visible[]
    end
    if is_interactive && get(ENV, "JULIA_PLOT_HEADLESS", "false") == "false"
        display(fig)
        try
            # Position window at (30, 30)
            window = GLFW.GetCurrentContext()
            if window != nothing && window.handle != C_NULL
                GLFW.SetWindowPos(window, 5, 35)
            end

            # Register viewport resize logic AFTER display to avoid world-age errors
            if !is_fixed
                on(axX.scene.viewport) do rect
                    # Use invokelatest for extra stability during initialization period
                    Base.invokelatest() do
                        time_window[] = Float64(rect.widths[1]) / px_per_sec
                    end
                end
                # Manually trigger the first update
                notify(axX.scene.viewport)
            end
        catch
            # Ignore errors
        end
    end
    resize_to_layout!(fig) # Forces window to shrink/expand to fit the fixed axis precisely
    println(defaultFont, "Done ")
    return fig
end

end # module
