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
    @test length(p) == 2
    s = FP.prepare_text(p[1])
    @test s isa String
    @test isapproxstr(s, """
        &#92; &#35; &#64; &#96; &#123; &#125; &#42; &#95;
        Hello
        """)
    p = raw"""
        &#42;
         ----
        \\
        """ |> FP.default_md_partition

    @test eltype(p) == FP.Block
    @test p[1].name == :TEXT
    @test p[2].name == :HRULE
    @test p[3].name == :TEXT
    @test p[4].name == :LINEBREAK
    @test p[5].name == :P_BREAK

    # # no clash with tables
    # p = raw"""
    # | x   | y   |
    # | --- | --- |
    # | 0 | 1 |
    # """ |> FP.default_md_partition
    # @test p[1].name == :TEXT
    # @test length(p) == 1

    t = raw"""
        abc \\
          --------
        &#60;
        """ |> FP.default_md_partition
    @test t[1].name == :TEXT
    @test t[2].name == :LINEBREAK
    @test t[3].name == :HRULE
    @test FP.prepare_text(t[4]) == "\n&#60;"

    # emoji
    p = raw"""
        A :ghost: and :smile: but :foo:
        """ |> FP.default_md_partition
    @test FP.prepare_text(p[1]) // "A 👻 and 😄 but :foo:"
end
