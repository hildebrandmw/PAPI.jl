module LowLevel

using ..PAPIBase

#####
##### Low Level API
#####

# Functions in the Low Level API as defined by the Doxygen manual for PAPI.

##### Convenience Macro
macro lowlevel(fn, argtypes, args...)
    # Build up an escaped argument list
    escaped_args = [:($(esc(arg))) for arg in args] 

    return quote
        retval = ccall(($fn, libpapi), Cint, $argtypes, $(escaped_args...))
        ret = RetCode(retval)
        ret != PAPIBase.OK && throw(PAPIError(ret))
        ret
    end
end

"""
    add_event(eventset, eventcode) -> RetCode
"""
function add_event(eventset::Int32, eventcode)
    # This call can possibly return a positive integer - need to check that before 
    # converting to a RetCode
    ret = ccall((:PAPI_add_event, libpapi), Cint, (Cint, Cint), eventset, eventcode) 
    ret >= 0 || throw(PAPIError(RetCode(ret)))

    return ret
end

"""
    assign_eventset_component(eventset, [cidx]) -> RetCode
"""
function assign_eventset_component(eventset::Int32, cidx = Int32(0))
    # Default component index to 0, which should be the CPU
    @lowlevel(:PAPI_assign_eventset_component, (Cint, Cint), eventset, cidx)
end

"""
    attach(eventset, pid) -> RetCode
"""
attach(eventset::Int32, pid) = @lowlevel(:PAPI_attach, (Cint, Culong), eventset, pid)

"""
    cleanup_eventset(eventset) -> RetCode
"""
cleanup_eventset(eventset::Int32) = @lowlevel(:PAPI_cleanup_eventset, (Cint,), eventset)

"""
    create_eventset() -> Int32
"""
function create_eventset()
    es = Ref(PAPI_NULL)
    #ret = @papi ccall((:PAPI_create_eventset, libpapi), Cint, (Ref{Int32},), es)
    ret = @lowlevel(:PAPI_create_eventset, (Ref{Int32},), es)
    return es[]
end

"""
    detach(eventset, pid) -> RetCode
"""
detach(eventset::Int32, pid) = @lowlevel(:PAPI_detach, (Cint, Culong), eventset, pid)

"""
    destroy_eventset(eventset) -> RetCode
"""
destroy_eventset(eventset::Int32) = @lowlevel(:PAPI_destroy_eventset, (Ref{Cint},), Ref(eventset))

"""
    event_name_to_code(name::String) -> Int32
"""
function event_name_to_code(name::String)
    eventcode = Ref(PAPI_NULL)
    @lowlevel(:PAPI_event_name_to_code, (Cstring, Ref{Cint}), name, eventcode)

    return eventcode[]
end

"""
    is_initialized() -> InitCode
"""
is_initialized() = InitCode(ccall((:PAPI_is_initialized, libpapi), Cint, ()))

"""
    library_init(version)
"""
function library_init(version::Union{Int32, UInt32})
    # init the library - if it passes, the return value should be equal to the version
    # we gave it
    ret = ccall((:PAPI_library_init, libpapi), Cuint, (Cint,), version)
    ret != version && error("""
    Could not initialize PAPI library. Return "PAPI_library_init" return code: $ret
    """)

    return nothing
end

"""
    query_event(code::Int32) -> RetCode
"""
query_event(code) = RetCode(ccall((:PAPI_query_event, libpapi), Cint, (Cint,), code))

"""
    read(eventset::Int32, values::Vector{Int64}) -> RetCode
"""
function read(eventset::Int32, values::Vector{Int64})
    @lowlevel(:PAPI_read, (Cint, Ref{Clonglong}), eventset, values)
end

"""
    reset(eventset::Int32) -> RetCode
"""
reset(eventset::Int32) = @lowlevel(:PAPI_start, (Cint,), eventset)

"""
    shutdown()
"""
shutdown() = ccall((:PAPI_shutdown, libpapi), Nothing, ())

"""
    start(eventset)
"""
start(eventset::Int32) = @lowlevel(:PAPI_start, (Cint,), eventset)

struct EventState
    state::Int32
end

"""
    state(eventset) -> Int32
"""
function state(eventset::Int32)
    status = Ref{Int32}(zero(Int32))
    @lowlevel(:PAPI_state, (Cint, Ref{Cint}), eventset, status)

    return EventState(status[])
end

# Queries for event state
stopped(x::EventState) = isbitset(x.state, 0)
running(x::EventState) = isbitset(x.state, 1)
paused(x::EventState) = isbitset(x.state, 2)
not_init(x::EventState) = isbitset(x.state, 3)
overflowing(x::EventState) = isbitset(x.state, 4)
profiling(x::EventState) = isbitset(x.state, 5)
multiplexing(x::EventState) = isbitset(x.state, 6)
attached(x::EventState) = isbitset(x.state, 7)
cpu_attached(x::EventState) = isbitset(x.state, 8)

"""
    stop(eventset::Int32, values::Vector{Int64}) -> RetCode
"""
function stop(eventset::Int32, values::Vector{Int64}) 
    @lowlevel(:PAPI_stop, (Cint, Ref{Clonglong}), eventset, values)
end


end
