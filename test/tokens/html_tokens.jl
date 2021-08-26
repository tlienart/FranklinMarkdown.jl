@testset "html tokens" begin
    t = """
        {{ A }} <script abc></script><script> <!-- -->
        """ |> FP.default_html_tokenizer
    deleteat!(t, 1)
    @test t[1].name == :DBB_OPEN
    @test t[2].name == :DBB_CLOSE
    @test t[3].name == :SCRIPT_OPEN
    @test t[4].name == :SCRIPT_CLOSE
    @test t[5].name == :SCRIPT_OPEN
    @test t[6].name == :COMMENT_OPEN
    @test t[7].name == :COMMENT_CLOSE
end
