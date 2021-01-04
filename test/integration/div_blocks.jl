@testset "simple" begin
    s = "A *B* C" |> process
    @test s // "<p>A <em>B</em> C</p>"
    s = """
        ABC
        @@hello,bye DEF@@
        GHI
        """ |> process
    @test isapproxstr(s, """
        <p>ABC</p>
        <div class="hello bye">
          <p>DEF</p>
        </div>
        <p>GHI</p>
        """)
end
