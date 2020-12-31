@testset "basic" begin
    s = "ABC"
    parts = FP.partition_md(s)
    @test length(parts) == 1
    @test isa(parts[1], FP.Text)
    @test FP.content(parts[1]) == s
    s = "ABC<!--DEF-->"
    parts = FP.partition_md(s)
    @test length(parts) == 2
    @test isa(parts[1], FP.Text)
    @test isa(parts[2], FP.Block)
    @test parts[2].name == :COMMENT
    s = "ABC<!--DEF-->GHI"
    parts = FP.partition_md(s)
    @test length(parts) == 3
    @test all(isa(parts[i], FP.Text) for i in (1, 3))
    @test isa(parts[2], FP.Block)
    s = "ABC<!--DEF-->GHI<!--JKL-->MNO"
    parts = FP.partition_md(s)
    @test all(parts[i].name == :COMMENT for i in (2, 4))
end
