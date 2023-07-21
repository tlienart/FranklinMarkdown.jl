using Test, FranklinParser, Pkg
FP = FranklinParser
FPE = FP.FranklinParserException

@testset "block left open" begin
    s = raw"""
        Foo bar baz
        abc $ def
        blah blah
        """
    try
        FP.md_partition(s)
    catch e
        @test e isa FP.FranklinParserException
        for c in (
            "[FranklinParser | Block not closed]",
            "A block starting with token \"\$\" (MATH_INLINE) was left open.",
            "abc \$ def"
        )
            @test occursin(c, e.msg)
        end
    end
end

@testset "bad environment" begin
    s = raw"""
        ABC
        \begin{foo}
        DEF **GHI**
        """
    try
        p = FP.md_partition(s)
        g = FP.md_grouper(p)
    catch e
        @test e isa FP.FranklinParserException
        for c in (
            "[FranklinParser | Environment not closed]",
            "An environment \"\\begin{foo}\" was left open.",
            "ABC \\begin{foo} DEF"
        )
            @test occursin(c, e.msg)
        end
    end
end
