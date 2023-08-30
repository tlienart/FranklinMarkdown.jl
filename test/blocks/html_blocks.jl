@testset "html blocks" begin
    b = """
        {{ A }} <!-- B --> <script> C </script>
        """ |> FP.default_html_tokenizer |> FP.default_html_blockifier
    @test FP.name(b[1]) == :DBB
    @test FP.name(b[2]) == :COMMENT
    @test FP.name(b[3]) == :SCRIPT

    @test FP.content(b[1]) == " A "
end
