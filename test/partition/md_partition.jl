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

# @testset "text tokens" begin
#     s = """
#         ABC &#x02316; DEF
#         @@dname
#         GHI
#         @@
#         KLM &Tab;
#         """
#     parts = FP.md_partition(s)
#     @test parts[1].inner_tokens[1].name == :CHAR_HTML_ENTITY
#     @test parts[1].inner_tokens[2].name == :LINE_RETURN
#     @test length(parts[1].inner_tokens) == 2
#     @test parts[2].name == :DIV
#     # EOS is stripped
#     @test parts[3].inner_tokens[1].name == :LINE_RETURN
#     @test parts[3].inner_tokens[2].name == :CHAR_HTML_ENTITY
#     @test parts[3].inner_tokens[3].name == :LINE_RETURN
#     @test length(parts[3].inner_tokens) == 3
#
#     # recursion
#     subparts = FP.md_partition(parts[2])
#     @test length(subparts) == 1
#     @test subparts[1].name == :TEXT
# end
