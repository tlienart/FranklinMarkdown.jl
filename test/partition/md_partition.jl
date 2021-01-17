@testset "basic" begin
    s = "ABC"
    parts = FP.default_md_partition(s)
    @test length(parts) == 1
    @test isa(parts[1], FP.Block{:TEXT})
    @test FP.content(parts[1]) == s
    s = "ABC<!--DEF-->"
    parts = FP.default_md_partition(s)
    @test length(parts) == 2
    @test isa(parts[1], FP.Block{:TEXT})
    @test isa(parts[2], FP.Block)
    @test typeof(parts[2]) <: FP.Block{:COMMENT}
    s = "ABC<!--DEF-->GHI"
    parts = FP.default_md_partition(s)
    @test length(parts) == 3
    @test all(isa(parts[i], FP.Block{:TEXT}) for i in (1, 3))
    @test isa(parts[2], FP.Block)
    s = "ABC<!--DEF-->GHI<!--JKL-->MNO"
    parts = FP.default_md_partition(s)
    @test all(typeof(parts[i]) <: FP.Block{:COMMENT} for i in (2, 4))
end

@testset "text tokens" begin
    s = """
        ABC &#x02316; DEF
        @@dname
        GHI
        @@
        KLM &Tab;
        """
    parts = FP.default_md_partition(s)
    @test FP.name(parts[1].inner_tokens[1]) == :CHAR_HTML_ENTITY
    @test FP.name(parts[1].inner_tokens[2]) == :LINE_RETURN
    @test length(parts[1].inner_tokens) == 2
    @test typeof(parts[2]) <: FP.Block{:DIV}
    # EOS is stripped
    @test FP.name(parts[3].inner_tokens[1]) == :LINE_RETURN
    @test FP.name(parts[3].inner_tokens[2]) == :CHAR_HTML_ENTITY
    @test FP.name(parts[3].inner_tokens[3]) == :LINE_RETURN
    @test length(parts[3].inner_tokens) == 3
end
