@testset "math partitioning" begin
    s = raw"A $B \com{C}$ D"
    parts = FP.md_partition(s)
    mathb = parts[2]
    @test FP.name(mathb) == :MATH_INLINE
    parts = FP.math_partition(FP.content(mathb))
    @test FP.name(parts[1]) == :TEXT
    @test FP.name(parts[2]) == :LX_COMMAND
    @test FP.name(parts[3]) == :CU_BRACKETS
    @test FP.content(parts[1]) == "B"
    @test FP.content(parts[3]) == "C"
end
