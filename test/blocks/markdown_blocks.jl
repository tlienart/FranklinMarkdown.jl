@testset "Comments" begin
    s = """
        <!--ABC-->
        """
    blocks = s |> FP.md_blockifier
    @test FP.content(blocks[1]) == "ABC"
    s = """
        <!--A<!--B-->
        """
    blocks = s |> FP.md_blockifier
    @test FP.content(blocks[1]) == "A<!--B"
    s = """
        <!--A<!--B-->C-->
        """
    blocks = s |> FP.md_blockifier
    @test length(blocks) == 1
    @test FP.content(blocks[1]) == "A<!--B"
end

@testset "Raw" begin
    s = """
        ~~~ABC~~~
        """
    blocks = s |> FP.md_blockifier
    @test FP.content(blocks[1]) == "ABC"
end


@testset "Mix" begin
    s = """
        <!--~~~ABC~~~-->
        ~~~<!--ABC-->~~~
        """
    blocks = s |> FP.md_blockifier
    @test length(blocks) == 2
    @test FP.content(blocks[1]) == "~~~ABC~~~"
    @test FP.content(blocks[2]) == "<!--ABC-->"
end
