@testset "lx_command_pat" begin
    v = FP.validator(FP.LX_COMMAND_PAT)
    @test v(raw"\abc")
    @test v(raw"\abc_def")
    @test v(raw"\abc1_def*")
    @test !v(raw"\abc ")
    @test !v(raw"\abc**")
    @test !v(raw"\a*bc")
end

@testset "html_entity_pat" begin
    v = FP.validator(FP.HTML_ENTITY_PAT)
    for e in ("&sqcap;", "&SquareIntersection;", "&#x02293;", "&#8851;",
              "&Succeeds;", "&frac78;", "&gEl;", "&gnapprox;")
        @test v(e)
    end
    @test !v("&42;")
end

@testset "code lang pat" begin
    v = FP.validator(FP.CODE_LANG3_PAT)
    @test v("```jμliα")
    v = FP.validator(FP.CODE_LANG4_PAT)
    @test v("````jμliα")
    v = FP.validator(FP.CODE_LANG5_PAT)
    @test v("`````jμliα")
end

@testset "HR*" begin
    @test match(FP.HR1_PAT, "---") !== nothing
    @test match(FP.HR1_PAT, "--") === nothing
    @test match(FP.HR1_PAT, "-------") !== nothing
    @test match(FP.HR2_PAT, "___") !== nothing
    @test match(FP.HR3_PAT, "***") !== nothing
end
