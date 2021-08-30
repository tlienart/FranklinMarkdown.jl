@testset "html partition" begin
    parts = """
        ABC1 <!-- DEF --> ABC2 <script> GHI </script> ABC3 {{ JKL }} ABC4
        """ |> FP.html_partition
    for (i, c) in enumerate(("ABC1", "DEF", "ABC2", "> GHI", "ABC3", "JKL", "ABC4"))
        @test isapproxstr(FP.content(parts[i]), c)
    end
end
