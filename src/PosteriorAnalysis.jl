module PosteriorAnalysis

using MacroTools
using Iterators
using AutoHashEquals
using Requires
    
import Base: getindex, keys, size, map, vcat, show

export
    # vars
    vartype,
    varsize,
    vectorview,
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
@require Mamba include("mamba.jl")

end # module
