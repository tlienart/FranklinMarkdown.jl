@testset "basic" begin
    s = "ABC"
    parts = FP.md_partition(s)
    @test length(parts) == 1
    @test parts[1].name == :TEXT
    @test parts[1].ss == s
    s = "ABC<!--DEF-->"
    parts = FP.md_partition(s)
    @test length(parts) == 2
    @test parts[1].name == :TEXT
    @test parts[2].name == :COMMENT
    s = "ABC<!--DEF-->GHI"
    parts = FP.md_partition(s)
    @test length(parts) == 3
    @test all(parts[i].name == :TEXT for i in (1, 3))
    s = "ABC<!--DEF-->GHI<!--JKL-->MNO"
    parts = FP.md_partition(s)
    @test all(parts[i].name == :COMMENT for i in (2, 4))
end

@testset "cov" begin
    s = "abc"
    p = FP.md_partition(s)
    @test length(p) == 1
    @test p[1].name == :TEXT

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
    @test g[1].role == :PARAGRAPH
    @test g[2].role == :TABLE
    g = """
        abc *def* ghi
        @@d klm @@""" |> grouper
    @test g[1].role == :PARAGRAPH
    @test g[2].role == :DIV
    g = """
        @@d klm @@
        abc *def* ghi""" |> grouper
    @test g[2].role == :PARAGRAPH
    @test g[1].role == :DIV
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
    g = s |> grouper
    @test g[1] // s
    @test g[1].role == :PARAGRAPH_NOP
    s = """
        ABC ~~~foo~~~

        ~~~foo~~~

        ABC <!--bar-->

        <!--bar-->
        """
    g = s |> grouper
    @test g[1].role == :PARAGRAPH
    @test g[2].role == :PARAGRAPH_NOP
    @test g[3].role == :PARAGRAPH
    @test g[4].role == :PARAGRAPH_NOP

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
    @test g[1].role == :MD_DEF_BLOCK
    @test g[2].role == :PARAGRAPH_NOP
    @test g[3].role == :PARAGRAPH_NOP
    @test g[4].role == :PARAGRAPH
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
    @test g[1].role == :MD_DEF_BLOCK
    @test g[2].role == :PARAGRAPH_NOP
    @test g[3].role == :PARAGRAPH
    @test g[3] // "ABC"
end
