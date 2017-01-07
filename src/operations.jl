"Concatenate posterior draws for different variables."
function vcat(pds::PosteriorDraws...)
    isempty(pds) && error("Need at least one argument.")
    PosteriorDraws(pds[1].len,
                   vcat([pd.keys for pd in pds]...),
                   vcat([pd.vars for pd in pds]...))
end

"Add variables to `pd`, names by the given keys in `key => var` pairs."
function addvars{T}(pd::PosteriorDraws, key_var_pairs::Pair{Symbol, T}...)
    vcat(pd, PosteriorDraws(key_var_pairs...))
end

"Return `pd` without the variables names by `keys`."
function dropvars(pd::PosteriorDraws, keys...)
    keep = setdiff(1:size(pd, 1), _key2index(pd, [keys...]))
    PosteriorDraws(pd.len, pd.keys[keep], pd.vars[keep])
end

"""
Map variables for `keys` by `f`, add the result with `result_key` to `pd`.
"""
function map(pd::PosteriorDraws, result_key::Symbol, f, keys::Symbol...)
    result_key ∈ pd.keys &&
        error(ArgumentError("Can't overwrite an existing variable."))
    vars = pd.vars[_key2index(pd, [keys...])]
    vectors = map(vectorview, vars)
    addvars(pd, result_key => map(f, vars...))
end

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

"""
Helper function that creates the body of the @pdmap macro.
"""
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
    :(map($(esc(pd)), $(_map_helper(key_and_form_pair)...)))
end
