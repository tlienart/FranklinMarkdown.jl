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
