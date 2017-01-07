"Insert variables into `pd`, names by the given keys in `key => var` pairs."
function addvars!{T}(pd::PosteriorDraws, key_var_pairs::Pair{Symbol, T}...)
    newkeys = [pd.keys; first.(key_var_pairs)]
    @assert allunique(newkeys) "Duplicate keys."
    pd.keys = newkeys
    pd.vars = [pd.vars; last.(key_var_pairs)]
    pd
end

"Add variables to `pd`, names by the given keys in `key => var` pairs."
addvars(pd::PosteriorDraws, key_var_pairs) = addvars!(copy(pd), key_var_pairs...)

"Delete the variables named by `keys` from `pd`."
function dropvars!(pd::PosteriorDraws, keys...)
    keep = setdiff(1:length(pd, vars), key2index(keys))
    pd.keys = pd.keys[keep]
    pd.vars = pd.vars[keep]
    pd
end

"Return `pd` without the variables names by `keys`."
dropvars(pd::PosteriorDraws, keys...) = dropvars!(copy(pd), keys...)

""
function map!(pd::PosteriorDraws, result_key::Symbol, f, keys::Symbol...)
    result_key ∈ pd.keys ||
        error(ArgumentError("Can't overwrite an existing variable."))
    addvars!(pd, result_key =>
             map(f, vectorview.(pd.vars[key2indexes(pd, keys)])))
end

map(pd::PosteriorDraws, result_key::Symbol, f, keys::Symbol...) =
    map!(copy(pd), result_key, f, keys)

"""
Transform expression by replacing each `@v(symbol)` with a gensym, and
collecting `symbol => gensym` in `captured_names` as a side effect.
"""
_transform_expr(expr, captured_names::Dict{Symbol, Symbol}) = expr

function _transform_expr(expr::Expr, captured_names::Dict{Symbol, Symbol})
    @match expr begin
        @v(var_) => get!(()->gensym(var), captured_names, var)
        @v(var__) => error("@v takes only a single variable name.")
        :e_ => expr             # pass through quoted
        e_ => Expr(e.head, [_transform_expr(arg, captured_names)
                            for arg in e.args]...)
    end
end

"""
When called without the second argument, return a tuple with the
captured names as the second element.
"""
function _transform_expr(expr)
    captured_names = Dict{Symbol,Symbol}()
    (_transform_expr(expr, captured_names), captured_names)
end

function _map_helper(key_and_form_pair)
    (result_key, form) = @match key_and_form_pair begin
        (key_ => form_) => (key, form)
        _ => error("expecting key => form")
    end
    (transformed_form, captured_names) = _transform_expr(form)
    arguments = :($([gensym_ for (_, gensym_) in captured_names]...),)
    closure = :($arguments -> $(transformed_form))
    keys = [Meta.quot(varname) for (varname, _) in captured_names]
    (Meta.quot(result_key), closure, keys...)
end

"""
Wrapper macro for `map(pd::PosteriorDraws, ...)`. Uses the syntax
```julia
@pdmap posteriordraws newvar => form(@v(somevar), @v(someothervar), ...)
```
where `newvar` will contain the result, while the `@v` forms are
parsed by a codewalker which generates the appropriate syntax for map.
"""
macro pdmap(pd, key_and_form_pair)
    :(map($pd, $(_map_helper(key_and_form_pair)...)))
end

"""
Similar to `@pdmap` (see documentation for that), but calls `map!`.
"""
macro pdmap!(pd, key_and_form_pair)
    :(map!($pd, $(_map_helper(key_and_form_pair)...)))
end
