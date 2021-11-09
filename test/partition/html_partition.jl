@testset "html partition" begin
    parts = """
        ABC1 <!-- DEF --> ABC2 <script> GHI </script> ABC3 {{ JKL }} ABC4
        """ |> FP.html_partition
    for (i, c) in enumerate(("ABC1", "DEF", "ABC2", "> GHI", "ABC3", "JKL", "ABC4"))
        @test isapproxstr(FP.content(parts[i]), c)
    end
end

@testset "script content" begin
    parts = """
        ABC <script> GHI </script> DEF
        """ |> FP.html_partition
    c = FP.content(parts[2])
    i = findfirst('>', c)
    @test strip(c[nextind(c, i):end]) == "GHI"
end
