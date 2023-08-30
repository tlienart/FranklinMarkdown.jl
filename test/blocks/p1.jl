include("../testutils.jl")

@testset "basic" begin
    s = "~~~c~~~"
    b = pass1blocks(s)
    @test FP.name(b[1]) == :RAW_HTML
    @test b[1].ss // s
    @test length(b[1].tokens) == 2

    s = "`abc`"
    b = pass1blocks(s)
    @test FP.name(b[1]) == :CODE_INLINE
    @test b[1].ss // s
    @test length(b[1].tokens) == 2
end

@testset "links" begin
    s = "[a]"
    b = pass2blocks(s)
    @test FP.name(b[1]) == :LINK_A
    @test [FP.name(t) for t in b[1].tokens] == [
        :SQ_BRACKET_OPEN,
        :SQ_BRACKET_CLOSE
    ]

    s = "[a](b)"
    b = pass2blocks(s)
    @test FP.name(b[1]) == :LINK_AB
    @test [FP.name(t) for t in b[1].tokens] == [
        :SQ_BRACKET_OPEN,
        :SQ_BRACKET_CLOSE,
        :BRACKET_OPEN,
        :BRACKET_CLOSE
    ]

    s = "[a][b]"
    b = pass2blocks(s)
    @test FP.name(b[1]) == :LINK_AR
    @test [FP.name(t) for t in b[1].tokens] == [
        :SQ_BRACKET_OPEN,
        :SQ_BRACKET_CLOSE,
        :SQ_BRACKET_OPEN,
        :SQ_BRACKET_CLOSE
    ]

    s = "![a]"
    b = pass2blocks(s)
    @test FP.name(b[1]) == :IMG_A
    @test [FP.name(t) for t in b[1].tokens] == [
        :SQ_BRACKET_OPEN,
        :SQ_BRACKET_CLOSE,
    ]

    s = "![a](b)"
    b = pass2blocks(s)
    @test FP.name(b[1]) == :IMG_AB
    @test [FP.name(t) for t in b[1].tokens] == [
        :SQ_BRACKET_OPEN,
        :SQ_BRACKET_CLOSE,
        :BRACKET_OPEN,
        :BRACKET_CLOSE
    ]

    s = "![a][b]"
    b = pass2blocks(s)
    @test FP.name(b[1]) == :IMG_AR
    @test [FP.name(t) for t in b[1].tokens] == [
        :SQ_BRACKET_OPEN,
        :SQ_BRACKET_CLOSE,
        :SQ_BRACKET_OPEN,
        :SQ_BRACKET_CLOSE
    ]

    s = "[a]: foo"
    b = pass2blocks(s)
    @test FP.name(b[1]) == :REF
    @test b[1].ss // "[a]:"
    @test [FP.name(t) for t in b[1].tokens] == [
        :SQ_BRACKET_OPEN,
        :SQ_BRACKET_CLOSE,
    ]
end
