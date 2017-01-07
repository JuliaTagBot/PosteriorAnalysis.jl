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

pd = PosteriorDraws(:a => [1:3], :b => [4:6])
