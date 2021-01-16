@testset "block utils" begin
    blocks = """
        ABC
        @@c1,c2 DEF@@
        GHI
        """ |> md_blockifier
    div = blocks[1]
    @test typeof(div) <: FP.Block{:DIV}
    @test FP.name(div) == :DIV
    @test FP.get_classes(div) == "c1 c2"
end
