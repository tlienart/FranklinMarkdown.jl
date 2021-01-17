@testset "block utils" begin
    blocks = """
        ABC
        @@c1,c2 DEF@@
        GHI
        """ |> md_blockifier
    div = blocks[1]
    @test typeof(div) <: FP.Block{:DIV}
    @test FP.name(div) == :DIV
    @test FP.get_classes(div) == "c1 c2"
end

@testset "prepare text" begin
    p = raw"""
        \ \\ \# \@ \` \{ \} \* \_
        Hello
        """ |> FranklinParser.default_md_partition
    s = FranklinParser.prepare_text(p[1])
    @test s isa String
    @test isapproxstr(s, """
        &#92; <br> &#35; &#64; &#96; &#123; &#125; &#42; &#95;
        Hello
        """)
end
