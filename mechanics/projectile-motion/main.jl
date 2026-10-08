using GLMakie

# Simulate projectile motion with linear air drag and ground bounces
function simulate(
    initial_speed,
    launch_angle,
    gravity,
    drag,
    restitution,
    max_bounces,
    dt,
    max_duration,
)
    angle = deg2rad(launch_angle)

    # Initial position and velocity
    position_x = 0.0
    position_y = 0.0

    velocity_x = initial_speed * cos(angle)
    velocity_y = initial_speed * sin(angle)

    # Store trajectory data
    positions_x = Float64[position_x]
    positions_y = Float64[position_y]

    bounce_count = 0

    for _ in 0:dt:max_duration
        # Gravity and linear air drag
        acceleration_x = -drag * velocity_x
        acceleration_y = -gravity - drag * velocity_y

        # Update velocity first, then position
        velocity_x += acceleration_x * dt
        velocity_y += acceleration_y * dt

        position_x += velocity_x * dt
        position_y += velocity_y * dt

        # Bounce on ground impact
        if position_y <= 0.0
            position_y = 0.0
            bounce_count += 1

            if bounce_count > max_bounces
                push!(positions_x, position_x)
                push!(positions_y, position_y)
                break
            end

            velocity_y = -restitution * velocity_y
        end

        push!(positions_x, position_x)
        push!(positions_y, position_y)
    end

    return positions_x, positions_y
end

# Create the visualization
function create_figure(positions_x, positions_y)
    max_x = maximum(positions_x)
    max_y = maximum(positions_y)

    figure = Figure(size = (800, 500))

    axis = Axis(
        figure[1, 1],
        limits = (0, max_x * 1.05, 0, max_y * 1.10),
        aspect = DataAspect(),
        xlabel = "Distance (m)",
        ylabel = "Height (m)",
        title = "Projectile Motion",
    )

    hlines!(axis, [0.0])

    ball_x = Observable([positions_x[1]])
    ball_y = Observable([positions_y[1]])

    trajectory_x = Observable([positions_x[1]])
    trajectory_y = Observable([positions_y[1]])

    lines!(axis, trajectory_x, trajectory_y)
    scatter!(axis, ball_x, ball_y, markersize = 25)

    return figure, ball_x, ball_y, trajectory_x, trajectory_y
end

# Save the animation as an MP4 file
function save_video(
    figure,
    ball_x,
    ball_y,
    trajectory_x,
    trajectory_y,
    positions_x,
    positions_y,
    output_path,
    fps,
)
    record(figure, output_path, eachindex(positions_x); framerate = fps) do i
        ball_x[] = [positions_x[i]]
        ball_y[] = [positions_y[i]]

        trajectory_x[] = positions_x[1:i]
        trajectory_y[] = positions_y[1:i]
    end
end

# Show the animation in a GLMakie window
function show_animation(
    figure,
    ball_x,
    ball_y,
    trajectory_x,
    trajectory_y,
    positions_x,
    positions_y,
    fps,
)
    GLMakie.closeall()

    # Reset to the first frame
    ball_x[] = [positions_x[1]]
    ball_y[] = [positions_y[1]]
    trajectory_x[] = [positions_x[1]]
    trajectory_y[] = [positions_y[1]]

    screen = GLMakie.Screen()
    display(screen, figure)

    @async begin
        for i in eachindex(positions_x)
            ball_x[] = [positions_x[i]]
            ball_y[] = [positions_y[i]]

            trajectory_x[] = positions_x[1:i]
            trajectory_y[] = positions_y[1:i]

            sleep(1 / fps)
        end
    end

    return screen
end

# Configure and run the simulation
function run()
    # Physical parameters
    gravity = 9.81
    drag = 0.08
    restitution = 0.65

    initial_speed = 15.0
    launch_angle = 70.0
    max_bounces = 10

    # Simulation settings
    fps = 60
    dt = 1 / fps
    max_duration = 10.0

    positions_x, positions_y = simulate(
        initial_speed,
        launch_angle,
        gravity,
        drag,
        restitution,
        max_bounces,
        dt,
        max_duration,
    )

    figure, ball_x, ball_y, trajectory_x, trajectory_y =
        create_figure(positions_x, positions_y)

    output_dir = joinpath(@__DIR__, "..", "..", "output")
    mkpath(output_dir)

    output_path = joinpath(output_dir, "projectile-motion.mp4")

    save_video(
        figure,
        ball_x,
        ball_y,
        trajectory_x,
        trajectory_y,
        positions_x,
        positions_y,
        output_path,
        fps,
    )

    screen = show_animation(
        figure,
        ball_x,
        ball_y,
        trajectory_x,
        trajectory_y,
        positions_x,
        positions_y,
        fps,
    )

    println("Saved: $output_path")

    return screen, figure
end

app = run()