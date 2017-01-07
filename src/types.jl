immutable PosteriorDraws{T}
    len::Int
    keys::Vector{Symbol}
    vars::Vector{T}
    function PosteriorDraws(len, keys, vars)
        allunique(keys) || error(ArgumentError("Duplicate keys."))
        length(keys) == length(vars) ||
            error(ArgumentError("Non-conforming keys and vars."))
        all(length(var) == len for var in vars) ||
            error("Non-conformable lengths")
        new(keys, vars)
    end
end

PosteriorDraws(len::Int) = PosteriorDraws(len, Symbol[], Any[])

function PosteriorDraws(keys::AbstractVector{Symbol}, vars)
    length(vars) ≥ 1 ||
        error(ArgumentError("Need at least one variable to determine length."))
    PosteriorDraws(length(vars[1]), keys, vars)
end

function PosteriorDraws{T}(key_var_pairs::Pair{Symbol, T}...)
    PosteriorDraws(first.(key_var_pairs), last.(key_var_pairs))
end

keys(pd::PosteriorDraws) = pd.keys

size(pd::PosteriorDraws) = (length(pd.keys), len)

"Return the type of draws in a chain."
drawtype{T}(chain::AbstractVector{T}) = T

"""
Return the draws in a `chain` as an `AbstractVector`. This may share
structure with `chain`, and is not supposed to be modified.
"""
vectorview{T}(chain::AbstractVector{T}) = chain

"Lookup `keys` in `pd`, returning the corresponding indexes."
function _key2index(pd::PosteriorDraws, keys::Vector{Symbol})
    index = findin(pd.keys, keys)
    any(index .== 0) &&
        error(ArgumentError("Variables $(keys[find(index)]) not found"))
    index
end

function _key2index(pd::PosteriorDraws, key::Symbol)
    index = findfirst(pd.keys, name)
    index == 0 && error(ArgumentError("Variable $(key) not found"))
end

function getindex(pd::PosteriorDraws, keys)
    keyinds = key2index(keys)
    if isa(keyinds, Int)
        pd.vars[keyinds]
    else
        PosteriorDraws(pd.len, pd.keys[keyinds], pd.vars[keyinds])
    end
end

function getindex(pd::PosteriorDraws, keys, drawinds)
    keyinds = key2index(keys)
    if isa(keyinds, Int)
        pd.vars[keyinds][drawinds]
    else
        PosteriorDraws(pd.keys[keyinds],
                       [var[drawinds] for var in pd.vars[keyinds]])
    end
end
    
