include("../testutils.jl")

@testset "inner tokens textblock" begin
    p = """
        abc &amp; def \\@ 000
        ```
        code
        ```
        and \\# 111 &amp; 000
        """ |> FP.md_partition

    t1 = signames(FP.content_tokens(p[1]))
    @test t1 == [:CHAR_HTML_ENTITY, :CHAR_64]
    @test t1 == signames(FP.default_md_tokenizer(p[1].ss))

    t2 = signames(FP.content_tokens(p[2]))
    @test isempty(t2)

    t3 = signames(FP.content_tokens(p[3]))
    @test t3 == [:CHAR_35, :CHAR_HTML_ENTITY]
    @test t3 == signames(FP.default_md_tokenizer(p[3].ss))
end


@testset "inner tokens textblock 2" begin
    p = raw"""abc \newenvironment{foo}{`bar`}{&amp;baz} def""" |> FP.md_partition

    @test signames(FP.content_tokens(p[4])) == [:CODE_SINGLE, :CODE_SINGLE]
    @test signames(FP.content_tokens(p[5])) == [:CHAR_HTML_ENTITY]
end
