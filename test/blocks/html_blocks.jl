@testset "html blocks" begin
    b = """
        {{ A }} <!-- B --> <script> C </script>
        """ |> FP.default_html_tokenizer |> FP.default_html_blockifier
    @test b[1].name == :DBB
    @test b[2].name == :COMMENT
    @test b[3].name == :SCRIPT

    @test FP.content(b[1]) == " A "
end
