@testset "Token" begin
    s = "abcd"
    t = FP.Token(:ab, FP.subs(s, 2:3))
    @test typeof(t) <: FP.AbstractSpan
    @test t.name == :ab
    @test FP.from(t) == 2
    @test FP.to(t) == 3
    @test FP.parent_string(s) === s
    @test t.ss == "bc"
    t = FP.Token(:EOS, FP.subs(s, lastindex(s)))
    @test FP.is_eos(t)
end

@testset "Block" begin
    s = "abcd"
    t1 = FP.Token(:ab, FP.subs(s, 1))
    t2 = FP.Token(:cd, FP.subs(s, 4))
    b = FP.Block(:foo, t1 => t2)
    @test typeof(b) == FP.Block
    @test b.ss == "abcd"
    @test b.open === t1
    @test b.close === t2
    @test FP.content(b) == "bc"
    @test isa(b, FP.AbstractSpan)

    s = "abc def ghi"
    t = FP.TextBlock(FP.subs(s, 5:7))
    @test isa(t, FP.AbstractSpan)
    @test t.ss == "def"
end

@testset "concrete" begin
    @test isconcretetype(FP.SS)
    @test isconcretetype(FP.SubVector{FP.Token})
    @test isconcretetype(typeof(FP.EMPTY_TOKEN_SVEC))
    @test isconcretetype(FP.Token)
    @test isconcretetype(FP.Block)
    @test isconcretetype(Vector{FP.Block})
end

@testset "subv" begin
    a = [1,2,3,4]
    va = FP.subv(a)
    @test length(va) == length(a)
    @test va isa SubArray
    @test va === FP.subv(va)
end
