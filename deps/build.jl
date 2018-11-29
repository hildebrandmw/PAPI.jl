# Untar the "gz" file
papi_version = "papi-5.6.0"
tarball = joinpath(@__DIR__, "$papi_version.tar.gz")
run(`tar xf $tarball`)

# Configure the installation
config_path = joinpath(@__DIR__, papi_version, "src")
options = ["--with-shared-lib=true"]

run(`$config_path $options`)
