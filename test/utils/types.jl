@testset "Token" begin
    s = "abcd"
    t = FP.Token(:ab, FP.subs(s, 2:3))
    @test typeof(t) <: FP.AbstractSpan
    @test FP.from(t) == 2
    @test FP.to(t) == 3
    @test FP.parent_string(s) === s
    @test t.name == :ab
    @test t.ss == "bc"
    @test t.lno == 0
end

@testset "SpecialChar" begin
    s = "ab * c"
    sch = FP.SpecialChar(FP.subs(s, 4), "&#42;")
    @test typeof(sch) <: FP.AbstractSpan
    @test FP.from(sch) == 4
    @test FP.to(sch) == 4
    @test sch.html == "&#42;"
    sch = FP.SpecialChar("foo")
    @test sch.html == ""
end

@testset "Block" begin
    s = "abcd"
    t1 = FP.Token(:ab, FP.subs(s, 1))
    t2 = FP.Token(:cd, FP.subs(s, 4))
    b = FP.Block(:foo, t1 => t2)
    @test b.name == :foo
    @test b.ss == "abcd"
    @test b.open === t1
    @test b.close === t2
    @test FP.content(b) == "bc"
end
