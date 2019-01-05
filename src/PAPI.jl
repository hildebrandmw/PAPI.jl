module PAPI

export EventSet

#####
##### File Includes
#####

include("base.jl")
include("lowlevel.jl")
include("highlevel.jl")

using .PAPIBase, .LowLevel, .HighLevel

include("events.jl")

#####
##### Initialization Routines
#####

# Taken from papi.h - lines 220
papi_version(maj,min,rev,inc) = UInt32(0xffff0000 & ((maj << 24) | (min << 16) | (rev << 8) | inc))
const PAPI_VER_CURRENT = papi_version(5,6,1,0)

# Keep track of how many EventSets have been instantiated.
const EVENTSET_COUNT = Ref(zero(UInt))

function __init__()
    LowLevel.library_init(PAPI_VER_CURRENT)
    EVENTSET_COUNT[] = 1

    atexit() do
        # Since "atexit()" is called BEFORE finalizers are run, it's possible that
        # there are still events around that need to be cleaned up.
        #
        # See: https://github.com/JuliaLang/julia/pull/20124
        EVENTSET_COUNT[] -= 1
        if EVENTSET_COUNT[] == 0
            LowLevel.shutdown()
        end
    end
end

#####
##### Fun Stuff
#####

function getevents()
    println("Listing available events...")
    for event in instances(PAPI.Event) 
        code = LowLevel.query_event(event)
        if code == PAPIBase.OK
            println(event)
        end
    end
end

"""
    showevents([io::IO])

Print the performance events to `io`.
"""
showevents(io::IO = stdout) = (run(pipeline(`$(PAPIBase.showevtinfo)`, stdout=io)); nothing)

"""
    checkevent(name, [umask], [modifiers...])

Check for event by name. Name, umask, and modifiers can be found by searching the output
of [`showevents`](@ref).
"""
function checkevent(name::String, modifiers...) 
    # Build the query string
    query = join((name, modifiers...), ":")
    @show query
    run(pipeline(`$(PAPIBase.check_events) $query`, stdout = stdout))
    return nothing
end

#####
##### EventSet
#####

mutable struct EventSet
    events :: Vector{Union{Event, Int32}}
    values :: Vector{Int64}
    handle :: Int32
    destroyed :: Bool
    # Constructor
    function EventSet() 
        # Create a new eventset and return its handle
        handle = LowLevel.create_eventset()
        eventset = new(Union{Event,Int32}[], Int64[], handle, false)

        EVENTSET_COUNT[] += 1
        # Register a finalizer that removes this from the underlying library when this
        # object goes out of scope.
        finalizer(_destroy!, eventset)
        return eventset
    end
end

Base.values(E::EventSet) = copy(E.values)

function addevent!(E::EventSet, event)
    LowLevel.add_event(E.handle, event)

    push!(E.events, event)
    push!(E.values, zero(eltype(E.values)))

    return nothing
end

component!(E::EventSet, cidx = Int32(0)) = LowLevel.assign_eventset_component(E.handle, cidx)

start(E::EventSet) = LowLevel.start(E.handle)
read(E::EventSet) = LowLevel.read(E.handle, E.values)
stop(E::EventSet) = LowLevel.stop(E.handle, E.values)
reset(E::EventSet) = LowLevel.reset(E.handle)

function attach(E::EventSet, pid) 
    LowLevel.inherit(E.handle)
    LowLevel.attach(E.handle, pid)
end
detach(E::EventSet, pid) = LowLevel.detach(E.handle, pid)


function cleanup!(E::EventSet)
    # Make sure the event is stopped
    eventstate = LowLevel.state(E.handle)
    if !LowLevel.stopped(eventstate) || LowLevel.running(eventstate)
        stop(E)
    end

    LowLevel.cleanup_eventset(E.handle)
    empty!(E.events)
    empty!(E.values)
end

function _destroy!(E::EventSet)
    # Check if this event is already destroyed. If so, do nothing
    E.destroyed && return nothing 

    # This is mostly to ensure that the top level EventSet type is emptied since it's been
    # destroyed
    cleanup!(E)
    LowLevel.destroy_eventset(E.handle)

    # The last item to get finalized shuts down the PAPI library
    EVENTSET_COUNT[] -= 1
    if EVENTSET_COUNT[] == 0
        LowLevel.shutdown()
    end
    E.destroyed = true
    return nothing
end

end # module

