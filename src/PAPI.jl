module PAPI

#####
##### File Includes
#####

include("base.jl")
include("lowlevel.jl")

using .PAPIBase
using .LowLevel

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

function addevent!(E::EventSet, event)
    LowLevel.add_event(E.handle, event)

    push!(E.events, event)
    push!(E.values, zero(eltype(E.values)))

    return nothing
end

start(E::EventSet) = LowLevel.start(E.handle)
Base.read(E::EventSet) = LowLevel.read(E.handle, E.values)
stop(E::EventSet) = LowLevel.stop(E.handle, E.values)
reset(E::EventSet) = LowLevel.reset(E.handle)

attach(E::EventSet, pid) = LowLevel.attach(E.handle, pid)
detach(E::EventSet, pid) = LowLevel.detach(E.handle, pid)

function cleanup!(E::EventSet)
    LowLevel.cleanup_eventset(E.handle)
    empty!(E.events)
    empty!(E.values)
end


# WARNING: Don't call this function directly. BAD things happen :D
function _destroy!(E::EventSet)
    # Check if this event is already destroyed. If so, do nothing
    E.destroyed && return nothing 

    cleanup!(E)
    LowLevel.destroy_eventset(E.handle)
    EVENTSET_COUNT[] -= 1

    # Check if we're the last thing around, turn off the lights
    if EVENTSET_COUNT[] == 0
        LowLevel.shutdown()
    end
    E.destroyed = true
    return nothing
end

#####
##### Random functions I don't quite know what to do with yet.
#####

"""
    PAPI.num_counters()
    
Get the number of hardware counters available on the system. 
"""
num_counters() = Int(ccall((:PAPI_num_counters, libpapi), Cint, ()))

"""
    PAPI.num_components()

Get the number of components available on the system
""" 
num_components() = Int(ccall((:PAPI_num_components, libpapi), Cint, ()))


end # module
