module PAPI

@osx_only error("PAPI.jl currently only works on Linux")
@windows_only error("PAPI.jl currently only works on Linux")

function __init__()
end

#### High Level Interface ####

@doc """
""" -> 
is_initialized() = Bool(ccall((:PAPI_is_initialized, :libpapi), Cint, ()))

@doc """
Get the number of hardware counters available on the system

`PAPI.num_counters()` returns the optimal length of the values array for high-level functions.
This value corresponds to the number of hardware counters supported by the current substrate. 
`PAPI.num_counters()` initializes the PAPI library using `PAPI.library_init()` if necessary. 
""" ->
num_counters() = Int(ccall((:PAPI_num_counters, :libpapi), Cint, ()))

@doc """
Add current counts to array and reset counters
""" ->
function accum_counters(values)
    return ccall((:PAPI_accum_counters, :libpapi), Cint, 
                 (Ptr{Clonglong}, Cint), values, length(values))
end

@doc """
Get the number of components available on the system
""" ->
num_components() = Int(ccall((:PAPI_num_components, :libpapi), Cint, ()))

@doc """
""" ->
function read_counters(values)
    ccall((:PAPI_read_counters, :libpapi), Cint,
          (Ptr{Clonglong}, Cint), values, length(values))
end

@doc """
Start counting hardware events

`PAPI.start_counters()` initializes the PAPI library (if necessary) and starts counting the events named in the events array. 
This function implicitly stops and initializes any counters running as a result of a previous call to `PAPI.start_counters()`. 
It is the user's responsibility to choose events that can be counted simultaneously by reading the vendor's documentation.
The number of events should be no larger than the value returned by `PAPI.num_counters()`. 
""" ->
function start_counters(events) 
    return ccall((:PAPI_start_counters, :libpapi), Cint, 
                 (Ptr{Cint}, Cint), events, length(events))
end

@doc """
Stop counters and return current counts
""" ->
function stop_counters(events) 
    return ccall((:PAPI_stop_counters, :libpapi), Cint, 
                 (Ptr{Cint}, Cint), events, length(events))
end

@doc """
Get Mflips/s (floating point instruction rate), real time and processor time
""" ->
function flips(rtime, flatptime, flpins, mflips)
    return ccall((:PAPI_flips, :libpapi), Cint,
                 (Ptr{Cfloat}, Ptr{Cfloat}, Ptr{Clonglong}, Ptr{Cfloat}),
                 rtime, floatptime, flpins, mflips)
end

@doc """
Get Mflop/s (floating point operand rate), real time and processor time
""" ->
function flops(rtimee, ptime, flpops, mflops)
    return ccall((:PAPI_flops, :libpapi), Cint,
                 (Ptr{Cfloat}, Ptr{Cfloat}, Ptr{Clonglong}, Ptr{Cfloat}),
                 rtimee, ptime, flpops, mflops)
end

@doc """
Get instructions per cycle, real time and processor time
""" ->
function ipc(rtime, ptime, ins, ipc)
    return ccall((:PAPI_ipc, :libpapi), Cint,
                 (Ptr{Void}, Ptr{Cfloat}, Ptr{Clonglong}, Ptr{Cfloat}),
                 rtime, ptime, ins, ipc)
end

@doc """
Get events per cycle, real time and processor time
""" ->
function epc(event, rtime, ptime, ref, core, evt, epc)
    return ccall((:PAPI_epc, :libpapi), Cint,
                 (Cint, Ptr{Cfloat}, Ptr{Cfloat}, Ptr{Clonglong}, 
                  Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Cfloat}),
                 event, rtime, ptime, ref, core, evt, epc)
end  

end # module