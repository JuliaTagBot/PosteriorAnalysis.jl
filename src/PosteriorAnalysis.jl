module PosteriorAnalysis

using MacroTools

import Base: getindex, keys, size, map, map!

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

include("utilities.jl")
include("types.jl")
include("operations.jl")

end # module
