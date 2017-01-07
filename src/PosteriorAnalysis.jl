module PosteriorAnalysis

using MacroTools
using AutoHashEquals

import Base: getindex, keys, size, map, vcat

export
    # types
    PosteriorDraws,
    drawtype,
    vectorview,
    # operations
    addvars,
    addvars!,
    dropvars,
    dropvars!,
    @pdmap,
    @pdmap!

include("types.jl")
include("operations.jl")

end # module
