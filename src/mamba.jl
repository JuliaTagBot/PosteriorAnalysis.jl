## conversion from the output of Mamba
function PosteriorDraws(chain::Mamba.ModelChains)
    all(search(name, '[') == 0 for name in chain.names) ||
        error("This function can't handle vector and matrix values (yet).")
    keys = map(Symbol, chain.names)
    vars = [vec(chain.value[:, var_index, :])
            for var_index in indices(chain.value,2)]
    PosteriorDraws(keys, vars)
end
