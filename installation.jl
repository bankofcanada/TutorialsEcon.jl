
# activate the Julia environment in this directory and instantiate it.

mypath = dirname(@__FILE__)

using Pkg
Pkg.activate(mypath)
pkg"instantiate"

using StateSpaceEcon
using ModelBaseEcon
using TimeSeriesEcon
