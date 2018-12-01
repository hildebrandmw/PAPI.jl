module HighLevel

using ..PAPIBase

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

## TODO: Not completed yet.
_zref(::Type{T}) where {T}  = Ref{T}(zero(T))
function flops()
    rtime = _zref(Float32)
    ptime = _zref(Float32)
    flpops = _zref(Int64)
    mflops = _zref(Float32)

    code = ccall(
        (:PAPI_flops, libpapi),
        Cint,
        (Ref{Cfloat}, Ref{Cfloat}, Ref{Clonglong}, Ref{Cfloat}),
        rtime, ptime, flpops, mflops
    )

    ret = RetCode(code)
    ret != PAPIBase.OK &&  throw(PAPIError(ret))

    return rtime[], ptime[], flpops[], mflops[]
end

end
