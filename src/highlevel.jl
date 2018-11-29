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

end
