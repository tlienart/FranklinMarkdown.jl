@testset "html tokens" begin
    t = """
        {{ A }} <script abc></script><script> <!-- -->
        """ |> FP.default_html_tokenizer
    @test FP.name(t[1]) == :DBB_OPEN
    @test FP.name(t[2]) == :DBB_CLOSE
    @test FP.name(t[3]) == :SCRIPT_OPEN
    @test FP.name(t[4]) == :SCRIPT_CLOSE
    @test FP.name(t[5]) == :SCRIPT_OPEN
    @test FP.name(t[6]) == :COMMENT_OPEN
    @test FP.name(t[7]) == :COMMENT_CLOSE
end
