@testset "block utils" begin
    blocks = """
        ABC
        @@c1,c2 DEF@@
        GHI
        """ |> md_blockifier
    div = blocks[1]
    @test typeof(div) == FP.Block
    @test div.name == :DIV
    @test FP.get_classes(div) == "c1 c2"
end

@testset "prepare text" begin
    p = raw"""
        \ \# \@ \` \{ \} \* \_
        Hello
        """ |> FP.default_md_partition
    @test length(p) == 1
    s = FP.prepare_text(p[1])
    @test s isa String
    @test isapproxstr(s, """
        &#92; &#35; &#64; &#96; &#123; &#125; &#42; &#95;
        Hello
        """)
    p = raw"""
        &#42; --- \\
        """ |> FP.default_md_partition

    @test eltype(p) == FP.Block
    @test p[1].name == :TEXT
    @test p[2].name == :HRULE
    @test p[3].name == :TEXT
    @test p[4].name == :LINEBREAK
    @test p[5].name == :TEXT
end
