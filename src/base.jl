module PAPIBase

export PAPIError, InitCode, RetCode, libpapi, PAPI_NULL, isbitset

#####
##### Global Constants
#####

# a nonexistent hardware event used as a placeholder
const PAPI_NULL = Int32(-1)
const libpapi = joinpath(@__DIR__, "..", "deps", "libpapi.so.5.6.0.0")

#####
##### Error Handling
#####

include("retcodes.jl")
struct PAPIError{R} <: Exception
    msg::String
end
PAPIError(R::RetCode) = PAPIError{R}(errmsg(R))

#####
##### Auxiliary Functions
#####

isbitset(x, n) = (x & (1 << n)) != 0

end

