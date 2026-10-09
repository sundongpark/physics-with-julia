using GLMakie

# Simulate a damped harmonic oscillator after release
function simulate(
    mass,
    spring_constant,
    damping,
    initial_position,
    initial_velocity,
    dt,
    duration,
)
    position = initial_position
    velocity = initial_velocity

    times = Float64[0.0]
    positions = Float64[position]

    for time in dt:dt:duration
        # Spring force and damping force
        acceleration =
            (-spring_constant * position - damping * velocity) / mass

        # Update velocity first, then position
        velocity += acceleration * dt
        position += velocity * dt

        push!(times, time)
        push!(positions, position)
    end

    return times, positions
end

# Add pulling and holding phases before release
function add_pull_and_hold(
    times,
    positions,
    pull_duration,
    hold_duration,
    fps,
)
    pull_frames = round(Int, pull_duration * fps)
    hold_frames = round(Int, hold_duration * fps)

    staged_times = Float64[]
    staged_positions = Float64[]

    initial_position = positions[1]

    # Pull smoothly from equilibrium to the initial position
    for i in 1:pull_frames
        progress = (i - 1) / max(pull_frames - 1, 1)

        # Smooth start and stop during pulling
        smooth_progress = 0.5 - 0.5 * cos(pi * progress)

        push!(staged_times, (i - 1) / fps)
        push!(staged_positions, smooth_progress * initial_position)
    end

    # Hold the mass before release
    for i in 1:hold_frames
        time = pull_duration + (i - 1) / fps

        push!(staged_times, time)
        push!(staged_positions, initial_position)
    end

    # Append the physical motion after release
    release_time = pull_duration + hold_duration

    for i in eachindex(times)
        push!(staged_times, release_time + times[i])
        push!(staged_positions, positions[i])
    end

    return staged_times, staged_positions
end

# Create zigzag points representing a spring
function make_spring_points(
    wall_x,
    mass_x;
    turns = 8,
    amplitude = 0.08,
)
    spring_start = wall_x + 0.15
    spring_end = mass_x - 0.18

    spring_x = Float64[wall_x, spring_start]
    spring_y = Float64[0.0, 0.0]

    segment_length = (spring_end - spring_start) / (2 * turns)

    for i in 1:(2 * turns)
        x = spring_start + i * segment_length
        y = isodd(i) ? amplitude : -amplitude

        push!(spring_x, x)
        push!(spring_y, y)
    end

    push!(spring_x, spring_end)
    push!(spring_y, 0.0)

    push!(spring_x, mass_x)
    push!(spring_y, 0.0)

    return spring_x, spring_y
end

# Create the spring-mass visualization and displacement graph
function create_figure(times, positions)
    max_position = maximum(abs.(positions))

    x_limit = max_position * 1.6
    wall_x = -x_limit

    figure = Figure(size = (800, 700))

    motion_axis = Axis(
        figure[1, 1],
        limits = (-x_limit, x_limit, -0.4, 0.4),
        aspect = DataAspect(),
        title = "Damped Harmonic Oscillator",
    )

    hidedecorations!(motion_axis)

    # Wall and equilibrium position
    vlines!(motion_axis, [wall_x], linewidth = 4)
    vlines!(motion_axis, [0.0], linestyle = :dash)

    mass_position = Observable([positions[1]])

    spring_x_initial, spring_y_initial =
        make_spring_points(wall_x, positions[1])

    spring_x = Observable(spring_x_initial)
    spring_y = Observable(spring_y_initial)

    lines!(
        motion_axis,
        spring_x,
        spring_y,
        linewidth = 3,
    )

    scatter!(
        motion_axis,
        mass_position,
        [0.0],
        marker = :rect,
        markersize = 35,
    )

    graph_axis = Axis(
        figure[2, 1],
        limits = (
            0,
            times[end],
            -max_position * 1.1,
            max_position * 1.1,
        ),
        xlabel = "Time (s)",
        ylabel = "Displacement (m)",
    )

    hlines!(graph_axis, [0.0])

    trace_time = Observable([times[1]])
    trace_position = Observable([positions[1]])

    lines!(
        graph_axis,
        trace_time,
        trace_position,
        linewidth = 2,
    )

    return (
        figure,
        mass_position,
        spring_x,
        spring_y,
        trace_time,
        trace_position,
        wall_x,
    )
end

# Update the visualization to a specific frame
function update_frame!(
    mass_position,
    spring_x,
    spring_y,
    trace_time,
    trace_position,
    wall_x,
    times,
    positions,
    frame,
)
    mass_position[] = [positions[frame]]

    current_spring_x, current_spring_y =
        make_spring_points(wall_x, positions[frame])

    spring_x[] = current_spring_x
    spring_y[] = current_spring_y

    trace_time[] = times[1:frame]
    trace_position[] = positions[1:frame]
end

# Save the animation as an MP4 file
function save_video(
    figure,
    mass_position,
    spring_x,
    spring_y,
    trace_time,
    trace_position,
    wall_x,
    times,
    positions,
    output_path,
    fps,
)
    record(
        figure,
        output_path,
        eachindex(times);
        framerate = fps,
    ) do frame
        update_frame!(
            mass_position,
            spring_x,
            spring_y,
            trace_time,
            trace_position,
            wall_x,
            times,
            positions,
            frame,
        )
    end
end

# Show the animation in a GLMakie window
function show_animation(
    figure,
    mass_position,
    spring_x,
    spring_y,
    trace_time,
    trace_position,
    wall_x,
    times,
    positions,
    fps,
)
    GLMakie.closeall()

    # Reset to the first frame
    update_frame!(
        mass_position,
        spring_x,
        spring_y,
        trace_time,
        trace_position,
        wall_x,
        times,
        positions,
        1,
    )

    screen = GLMakie.Screen()
    display(screen, figure)

    @async begin
        for frame in eachindex(times)
            update_frame!(
                mass_position,
                spring_x,
                spring_y,
                trace_time,
                trace_position,
                wall_x,
                times,
                positions,
                frame,
            )

            sleep(1 / fps)
        end
    end

    return screen
end

# Configure and run the simulation
function run()
    # Physical parameters
    mass = 1.0
    spring_constant = 12.0
    damping = 0.4

    initial_position = 1.0
    initial_velocity = 0.0

    # Simulation settings
    fps = 60
    dt = 1 / fps
    duration = 20.0

    # Animation staging
    pull_duration = 1.0
    hold_duration = 0.5

    times, positions = simulate(
        mass,
        spring_constant,
        damping,
        initial_position,
        initial_velocity,
        dt,
        duration,
    )

    times, positions = add_pull_and_hold(
        times,
        positions,
        pull_duration,
        hold_duration,
        fps,
    )

    (
        figure,
        mass_position,
        spring_x,
        spring_y,
        trace_time,
        trace_position,
        wall_x,
    ) = create_figure(times, positions)

    output_dir = joinpath(
        @__DIR__,
        "..",
        "..",
        "output",
    )

    mkpath(output_dir)

    output_path = joinpath(
        output_dir,
        "harmonic-oscillator.mp4",
    )

    save_video(
        figure,
        mass_position,
        spring_x,
        spring_y,
        trace_time,
        trace_position,
        wall_x,
        times,
        positions,
        output_path,
        fps,
    )

    screen = show_animation(
        figure,
        mass_position,
        spring_x,
        spring_y,
        trace_time,
        trace_position,
        wall_x,
        times,
        positions,
        fps,
    )

    println("Saved: $output_path")

    return screen, figure
end

app = run()