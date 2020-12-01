@testset "lx_command_pat" begin
    v = FP.validator(FP.LX_COMMAND_PAT)
    @test v("abc")
    @test v("abc_def")
    @test v("abc1_def*")
    @test !v("abc ")
    @test !v("abc**")
    @test !v("a*bc")
end

@testset "html_entity_pat" begin
    v = FP.validator(FP.HTML_ENTITY_PAT)
    for e in ("&sqcap;", "&SquareIntersection;", "&#x02293;", "&#8851;",
              "&Succeeds;", "&frac78;", "&gEl;", "&gnapprox;")
        @test v(e)
    end
    @test !v("&42;")
end
