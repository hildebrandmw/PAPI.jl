using Documenter, PAPI

makedocs(
    modules = [PAPI],
    format = :html,
    sitename = "PAPI.jl",
    html_prettyurls = get(ENV, "CI", nothing) == "true",
    pages = Any[
        "index.md",
        "highlevel.md",
        "lowlevel.md",
    ]
)

deploydocs(
    repo = "github.com/hildebrandmw/PAPI.jl.git",
    target = "build",
    julia = "1.0",
    deps = nothing,
    make = nothing,
)
