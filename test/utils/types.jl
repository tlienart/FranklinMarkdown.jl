include("../testutils.jl")

@testset "Token" begin
    s = "abcd"
    t = FP.Token(:ab, FP.subs(s, 2:3))
    @test typeof(t) <: FP.AbstractSpan
    @test t isa FP.Token{:ab}
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
    ts = [t1, t2]
    b = FP.Block(:foo, @view ts[1:end])
    @test typeof(b) == FP.Block{:foo}
    @test b.ss == "abcd"
    @test b.tokens[1] === t1
    @test b.tokens[2] === t2
    @test isa(b, FP.AbstractSpan)
end

@testset "concrete" begin
    @test isconcretetype(FP.SS)
    @test isconcretetype(FP.SubVector{FP.Token})
    @test isconcretetype(typeof(FP.EMPTY_TOKEN_SVEC))
    @test isconcretetype(FP.Token{:abc})
    @test isconcretetype(FP.Block{:abc})
    @test isconcretetype(Vector{FP.Block})
end

@testset "subv" begin
    a = [1,2,3,4]
    va = FP.subv(a)
    @test length(va) == length(a)
    @test va isa SubArray
    @test va === FP.subv(va)
end
