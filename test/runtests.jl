using PAPI
using Test

#####
##### Functions
#####

# Launch a command and return the PID for the launched process.
# NOTE: once julia 1.1 comes out - can directly get the PID of a launched process
function launch(command::String)
    pidlauncher = joinpath(@__DIR__, "deps", "pidlauncher.sh")
    # Resolve the path to the test. 
    pipe = Pipe()
    setup = pipeline(`$pidlauncher $command`; stdout = pipe)
    process = run(setup; wait = false)

    # Parse the first thing returned and let this process do its thing with reckless abandon
    pid = parse(Int, readline(pipe)) 
    return pid, process, pipe
end

#####
##### Test Suites
#####

include("lowlevel.jl")
include("highlevel.jl")

