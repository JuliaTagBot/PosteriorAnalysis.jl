using PosteriorAnalysis
using Base.Test
using MacroTools

import PosteriorAnalysis: _transform_expr

######################################################################
# test transformations (internal)
######################################################################

@test_throws ErrorException _transform_expr(:(@v())) # no arguments
@test_throws ErrorException _transform_expr(:(@v a b)) # too many arguments

"Test that expression is passed through."
macro test_passthrough(expr)
    (expr2, captured_names) = _transform_expr(expr)
    @test isequal(expr, expr2)
    @test isempty(captured_names)
end

@test_passthrough(:(a+b))
@test_passthrough(:(a.b))
@test_passthrough(:(quote a+@v(b)+c end))

test_template(f, expr) = f(_transform_expr(expr)...)
    
macro test_template(expr, template, variables...)
    evar = gensym(:expr)
    cvar = gensym(:captured_names)
    quote
        test_template($(Meta.quot(expr))) do $(evar), $(cvar)
            @match $(evar) begin
                $template => begin
                    $([:(@test get($cvar, $(Meta.quot(v)), nothing) == $v)
                       for v in variables]...)
                end
                _ => throw(error("Result $($evar) does not match template"))
            end
        end
    end
end

@test_template @v(a) a_ a
@test_template @v(a)+b a_+b a
@test_template @v(a).b a_.b a
@test_template a+@v(b)+@v(c) a+b_+c_ b c

######################################################################
# test operations
######################################################################

a = 1:3
b = 4:6
pd_z = PosteriorDraws(length(a))
pd_a = PosteriorDraws(:a => 1:3)
pd_ab = PosteriorDraws([:b,:a], [b,a]) # constructor will enforce sorting

@test size(pd_ab) == (2, length(a))
@test keys(pd_ab) == [:a,:b]

@test addvars(pd_a, :b => b) == pd_ab
@test addvars(pd_z, :a => a, :b => b) == pd_ab
@test vcat(pd_z, pd_ab) == pd_ab
@test dropvars(pd_ab, :b) == pd_a

@test all(pd_ab[:a] .== a)
@test all(pd_ab[:a,2:3] .== a[2:3])

pd_abc0 = addvars(pd_ab, :c => a+b)
pd_abc1 = map(pd_ab, :c, +, :a, :b)
pd_abc2 = @pdmap pd_ab c => @v(a) + @v(b)

@test pd_abc0 == pd_abc1
@test pd_abc0 == pd_abc2

