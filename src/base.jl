module PAPIBase

export PAPIError, InitCode, RetCode, libpapi, PAPI_NULL, isbitset

#####
##### Global Constants
#####

# a nonexistent hardware event used as a placeholder
const PAPI_NULL = Int32(-1)
const depsjl_path = joinpath(@__DIR__, "..", "deps", "deps.jl")
if !isfile(depsjl_path)
    error("LibFoo not installed properly, run Pkg.build(\"LibFoo\"), restart Julia and try again")
end
include(depsjl_path)

function __init__()
    # Check dependencies
    check_deps() 
end

#####
##### Error Handling
#####

include("retcodes.jl")
struct PAPIError <: Exception
    msg::String
end
PAPIError(R::RetCode) = PAPIError(errmsg(R))

#####
##### Auxiliary Functions
#####

isbitset(x, n) = (x & (1 << n)) != 0

end

