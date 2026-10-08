# Physics with Julia

Physics modeling and numerical simulations implemented in Julia.

## Simulations

### Mechanics

- [Free Fall](mechanics/free-fall) — Free fall with air resistance and bouncing
- [Projectile Motion](mechanics/projectile-motion) — Projectile motion with air resistance and ground bounces

## Run

Start Julia with the project environment:

```bash
julia --project=.
```

Then run a simulation from the Julia REPL:

```julia
include("mechanics/free-fall/main.jl")
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.