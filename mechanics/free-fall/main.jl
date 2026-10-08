using GLMakie

function run()
    gravity = 9.81
    initial_height = 5.0
    drag = 0.15
    restitution = 0.75

    fps = 60
    duration = 5.0
    dt = 1 / fps

    heights = simulate(
        gravity,
        initial_height,
        drag,
        restitution,
        dt,
        duration,
    )

    figure, ball_height = create_figure(initial_height)

    output_dir = joinpath(@__DIR__, "..", "..", "output")
    mkpath(output_dir)

    output_path = joinpath(output_dir, "free-fall.mp4")

    save_video(figure, ball_height, heights, output_path, fps)

    screen = show_animation(figure, ball_height, heights, fps)

    println("Saved: $output_path")

    return screen, figure
end

function simulate(gravity, initial_height, drag, restitution, dt, duration)
    height = initial_height
    velocity = 0.0
    heights = Float64[]

    for _ in 0:dt:duration
        acceleration = -gravity - drag * velocity

        velocity += acceleration * dt
        height += velocity * dt

        if height <= 0.0
            height = 0.0
            velocity = -restitution * velocity
        end

        push!(heights, height)
    end

    return heights
end

function create_figure(initial_height)
    figure = Figure(size = (500, 500))

    axis = Axis(
        figure[1, 1],
        limits = (-1, 1, 0, initial_height * 1.05),
        title = "Free Fall",
    )

    hidedecorations!(axis)
    hlines!(axis, [0.0])

    ball_height = Observable([initial_height])
    scatter!(axis, [0.0], ball_height, markersize = 30)

    return figure, ball_height
end

function save_video(figure, ball_height, heights, output_path, fps)
    record(figure, output_path, heights; framerate = fps) do height
        ball_height[] = [height]
    end
end

function show_animation(figure, ball_height, heights, fps)
    GLMakie.closeall()

    screen = GLMakie.Screen()
    display(screen, figure)

    @async begin
        for height in heights
            ball_height[] = [height]
            sleep(1 / fps)
        end
    end

    return screen
end

app = run()