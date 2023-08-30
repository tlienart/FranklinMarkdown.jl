include("../testutils.jl")

@testset "basic" begin
    s = "ABC"
    parts = FP.md_partition(s)
    @test length(parts) == 1
    @test FP.name(parts[1]) == :TEXT
    @test parts[1].ss == s
    s = "ABC<!--DEF-->"
    parts = FP.md_partition(s)
    @test length(parts) == 2
    @test FP.name(parts[1]) == :TEXT
    @test FP.name(parts[2]) == :COMMENT
    s = "ABC<!--DEF-->GHI"
    parts = FP.md_partition(s)
    @test length(parts) == 3
    @test all(FP.name(parts[i]) == :TEXT for i in (1, 3))
    s = "ABC<!--DEF-->GHI<!--JKL-->MNO"
    parts = FP.md_partition(s)
    @test all(FP.name(parts[i]) == :COMMENT for i in (2, 4))
end

@testset "cov" begin
    s = "abc"
    p = FP.md_partition(s)
    @test length(p) == 1
    @test FP.name(p[1]) == :TEXT

    p = "abc @@d ef *AA* g @@ end" |> FP.md_partition
    @test p[2] isa FP.Block
    c = p[2] |> FP.md_partition
    @test c[1] // "ef"
    @test c[2] // "*AA*"
    @test c[3] // "g"
end

@testset "group" begin
    g = """
        abc *def* ghi
        | a | b | c |""" |> grouper
    @test FP.name(g[1]) == :PARAGRAPH
    @test FP.name(g[2]) == :TABLE
    g = """
        abc *def* ghi
        @@d klm @@""" |> grouper
    @test FP.name(g[1]) == :PARAGRAPH
    @test FP.name(g[2]) == :DIV
    g = """
        @@d klm @@
        abc *def* ghi""" |> grouper
    @test FP.name(g[2]) == :PARAGRAPH
    @test FP.name(g[1]) == :DIV
end

@testset "environment" begin
    g = raw"abc \begin{foo} bar @@d baz @@ and \end{foo} hello" |> grouper
    @test g[1] // "abc"
    @test g[2] // raw"\begin{foo} bar @@d baz @@ and \end{foo}"
    @test g[3] // "hello"

    g = raw"abc \begin{foo} bar @@d baz @@ \begin{foo} a \end{foo} and \end{foo} hello" |> grouper
    @test g[1] // "abc"
    @test g[3] // "hello"

    @test_throws FP.FranklinParserException raw"abc \begin{foo}" |> grouper
end

@testset "raw" begin
    s = """
        abc ~~~ def ~~~ ghi %%% klm %%% and ??? %%% foo ???.
        """
    g = s |> grouper
    @test g[1] // s
    b = g[1].blocks
    @test b[1] // "abc"
    @test b[2] // "~~~ def ~~~"
    @test b[3] // "ghi"
    @test b[4] // "%%% klm %%%"
    @test b[5] // "and"
    @test b[6] // "??? %%% foo ???"
    @test b[7] // "."
end

@testset "nop-par" begin
    s = """

        {{foo}}

        """
    pass1blocks(s)
    g = s |> grouper
    @test g[1] // s
    @test FP.name(g[1]) == :PARAGRAPH_NOP
    s = """
        ABC ~~~foo~~~

        ~~~foo~~~

        ABC <!--bar-->

        <!--bar-->
        """
    g = s |> grouper
    @test FP.name(g[1]) == :PARAGRAPH
    @test FP.name(g[2]) == :PARAGRAPH_NOP
    @test FP.name(g[3]) == :PARAGRAPH
    @test FP.name(g[4]) == :PARAGRAPH_NOP

    # from franklin docs

    s = raw"""
        +++
        a = 5
        +++

        \newcommand{\foo}{bar}

        ~~~
        baz
        ~~~

        ABC
        """
    g = s |> grouper
    @test FP.name(g[1]) == :MD_DEF_BLOCK
    @test FP.name(g[2]) == :PARAGRAPH_NOP
    @test FP.name(g[3]) == :PARAGRAPH_NOP
    @test FP.name(g[4]) == :PARAGRAPH
    @test g[4] // "ABC"

    s = raw"""
        +++
        a = 5
        +++

        \newcommand{\foo}{bar}
        ~~~
        baz
        ~~~

        ABC
        """
    g = s |> grouper
    @test FP.name(g[1]) == :MD_DEF_BLOCK
    @test FP.name(g[2]) == :PARAGRAPH_NOP
    @test FP.name(g[3]) == :PARAGRAPH
    @test g[3] // "ABC"
end
