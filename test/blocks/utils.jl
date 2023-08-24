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
        """ |> FP.md_partition
    s = FP.prepare_md_text(p[1])
    @test s isa String
    @test isapproxstr(s, """
        &#92; &#35; &#64; &#96; &#123; &#125; &#42; &#95;
        Hello
        """)

    s = raw"""
        &#42;
         ----
        \\
        """
    p = s |> FP.md_partition

    @test eltype(p) == FP.Block
    @test p[1].name == :TEXT
    @test p[2].name == :HRULE
    @test p[3].name == :LINEBREAK
    @test isapproxstr(s, prod(pp.ss for pp in p))

    # # no clash with tables
    # p = raw"""
    # | x   | y   |
    # | --- | --- |
    # | 0 | 1 |
    # """ |> FP.md_partition
    # @test p[1].name == :TEXT
    # @test length(p) == 1

    s = raw"""
        abc \\
          --------
        &#60;
        """
    p = s |> FP.md_partition
    @test p[1].name == :TEXT
    @test p[2].name == :LINEBREAK
    @test p[3].name == :HRULE
    @test p[4].name == :TEXT
    @test FP.prepare_md_text(p[4]) == "&#60;"
    @test isapproxstr(s, prod(pp.ss for pp in p))

    # emoji
    p = raw"""
        A :ghost: and :smile: but :foo:
        """ |> FP.md_partition
    @test FP.prepare_md_text(p[1]) // "A 👻 and 😄 but :foo:"
end

@testset "preptext2" begin
    s = raw"abc \{ &#42;"
    b = s |> FP.md_partition |> first
    r = FP.prepare_md_text(b)
    @test r // "abc &#123; &#42;"
    r = FP.prepare_md_text(b; tohtml=false)
    @test r // "abc \\{ \\&#42;"
end
