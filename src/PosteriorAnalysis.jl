module PosteriorAnalysis

using MacroTools
using Iterators
using AutoHashEquals
    
import Base: getindex, keys, size, map, vcat

export
    # types
    PosteriorDraws,
    drawtype,
    vectorview,
    # operations
    addvars,
    dropvars,
    @pdmap

include("vars.jl")
include("types.jl")
include("operations.jl")

end # module
