module PAPIBase

export PAPIError, InitCode, RetCode, libpapi, PAPI_NULL

# a nonexistent hardware event used as a placeholder
const PAPI_NULL = Int32(-1)

include("retcodes.jl")

struct PAPIError{R} <: Exception
    msg::String
end

PAPIError(R::RetCode) = PAPIError{R}(errmsg(R))
const libpapi = joinpath(@__DIR__, "..", "deps", "libpapi.so.5.6.0.0")

end

