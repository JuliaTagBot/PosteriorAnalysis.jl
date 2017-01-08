"""
Variables are stored internally in a standardized format which allows
a compact representation. This function tests whether the argument is
a valid internap representation format.

See `standardize`, `vartype`, and `vectorview` below.
"""
isstandardized(v) = false       # default

"""
`standardize` converts to one of the internal representation
formats. The default is `Vector`.
"""
standardize(v::AbstractVector) = collect(v)

isstandardized(v::Vector) = true

standardize(v::Vector) = v

"Type of draws for a variable."
vartype{T}(var::Vector{T}) = T

"Size of draws for a variable."
varsize(var::Vector) = ()

"""
Return the draws in a `var` as an `AbstractVector`. This may share
structure with `var`, and is not supposed to be modified.
"""
vectorview(var::Vector) = var
