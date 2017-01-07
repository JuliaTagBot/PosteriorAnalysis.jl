@auto_hash_equals immutable PosteriorDraws{T}
    len::Int
    keys::Vector{Symbol}
    vars::Vector{T}
    function PosteriorDraws{T}(len::Int, keys::Vector{Symbol}, vars::Vector{T})
        allunique(keys) || error(ArgumentError("Duplicate keys."))
        length(keys) == length(vars) ||
            error(ArgumentError("Non-conforming keys and vars."))
        all(length(var) == len for var in vars) ||
            error("Non-conformable lengths")
        new{T}(len, keys, vars)
    end
end

function PosteriorDraws{T}(len::Int, keys::Vector{Symbol}, vars::Vector{T})
    PosteriorDraws{T}(len, keys, vars)
end

PosteriorDraws(len::Int) = PosteriorDraws(len, Symbol[], Any[])

function PosteriorDraws{T}(keys::Vector{Symbol}, vars::Vector{T})
    length(vars) ≥ 1 ||
        error(ArgumentError("Need at least one variable to determine length."))
    PosteriorDraws(length(vars[1]), keys, vars)
end

function PosteriorDraws{T}(key_var_pairs::Pair{Symbol, T}...)
    PosteriorDraws(first.([key_var_pairs...]), last.([key_var_pairs...]))
end

keys(pd::PosteriorDraws) = pd.keys

size(pd::PosteriorDraws) = (length(pd.keys), pd.len)
size(pd::PosteriorDraws, index) = size(pd)[index]

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
    index = findfirst(pd.keys, key)
    index == 0 && error(ArgumentError("Variable $(key) not found"))
    index
end

function getindex(pd::PosteriorDraws, keys)
    keyinds = _key2index(pd, keys)
    if isa(keyinds, Int)
        pd.vars[keyinds]
    else
        PosteriorDraws(pd.len, pd.keys[keyinds], pd.vars[keyinds])
    end
end

function getindex(pd::PosteriorDraws, keys, drawinds)
    keyinds = _key2index(pd, keys)
    if isa(keyinds, Int)
        pd.vars[keyinds][drawinds]
    else
        PosteriorDraws(pd.keys[keyinds],
                       [var[drawinds] for var in pd.vars[keyinds]])
    end
end
