md_blockifier = s -> FP.default_md_tokenizer(s) |> FP.default_md_blockifier

@testset "Not closed error"  begin
    s = "<!--"
    @test_throws FPE{FP.BlockNotClosed} md_blockifier(s)
end

@testset "Comment - no nesting" begin
    s = """
        <!--ABC-->
        """
    blocks = s |> md_blockifier
    @test FP.content(blocks[1]) == "ABC"
    @test isempty(blocks[1].inner_tokens)
    s = """
        <!--A<!--B-->
        """
    blocks = s |> md_blockifier
    @test blocks[1].inner_tokens[1].name == :COMMENT_OPEN
    @test FP.content(blocks[1]) == "A<!--B"
    s = """
        <!--A<!--B-->C-->
        """
    blocks = s |> md_blockifier
    @test length(blocks) == 1
    @test FP.content(blocks[1]) == "A<!--B"
end

@testset "Other - no nesting" begin
    blocks = "~~~ABC~~~" |> md_blockifier
    @test FP.content(blocks[1]) == "ABC"
    blocks = """
        +++
        ABC
        +++
        """ |> md_blockifier
    # code
    @test strip(FP.content(blocks[1])) == "ABC"
    blocks = "```julia ABC``` ````julia ABC```` `````julia ABC`````" |> md_blockifier
    @test strip(FP.content(blocks[1])) == "ABC"
    @test strip(FP.content(blocks[2])) == "ABC"
    @test strip(FP.content(blocks[3])) == "ABC"
    blocks = "`A` ``A`` ``` A```" |> md_blockifier
    @test FP.content(blocks[1]) == "A"
    @test FP.content(blocks[2]) == "A"
    @test strip(FP.content(blocks[3])) == "A"
    blocks = "```! ABC```" |> md_blockifier
    @test strip(FP.content(blocks[1])) == "ABC"
    # headers
    blocks = """
        # abc
        ## def
        ### ghi
        #### klm
        ##### nop
        ###### qrs
        """ |> md_blockifier
    @test strip(FP.content(blocks[1])) == "abc"
    @test strip(FP.content(blocks[2])) == "def"
    @test strip(FP.content(blocks[3])) == "ghi"
    @test strip(FP.content(blocks[4])) == "klm"
    @test strip(FP.content(blocks[5])) == "nop"
    @test strip(FP.content(blocks[6])) == "qrs"
    # footnotes
    blocks = """
        abc [^1] and [^ab] ef
        [1]:
        """
end

@testset "Braces - nesting" begin
    blocks = "{ABC}" |> md_blockifier
    @test FP.content(blocks[1]) == "ABC"
    blocks = "{ABC{DEF}H{IJ}K{L{M}O}P}" |> md_blockifier
    @test FP.content(blocks[1]) == "ABC{DEF}H{IJ}K{L{M}O}P"
end

@testset "Other - nesting" begin
    blocks = """
        @@abc DEF {GHI} KLM @@
        """ |> md_blockifier
    @test strip(FP.content(blocks[1])) == "DEF {GHI} KLM"
end

@testset "@def" begin
    blocks = """
        @def a = 5
        """ |> md_blockifier
    @test strip(FP.content(blocks[1])) == "a = 5"
    blocks = """
        @def a = [1,
            2]
        """ |> md_blockifier
    @test isapproxstr(FP.content(blocks[1]), "a=[1,2]")
end

@testset "Double brace" begin
    blocks = """
        {{abc {g} def}}
        """ |> md_blockifier
    @test FP.content(blocks[1]) == "abc {g} def"
end

@testset "Mix" begin
    s = """
        <!--~~~ABC~~~-->
        ~~~<!--ABC-->~~~
        """
    blocks = s |> md_blockifier
    @test length(blocks) == 2
    @test FP.content(blocks[1]) == "~~~ABC~~~"
    @test FP.content(blocks[2]) == "<!--ABC-->"

    b = """
        +++
        a = "~~~567"
        b = "-->"
        +++
        """ |> md_blockifier
    @test strip(FP.content(b[1])) == "a = \"~~~567\"\nb = \"-->\""

    b = """
        ```foo
        `A` ``B``
        ```
        """ |> md_blockifier
    @test strip(FP.content(b[1])) == "`A` ``B``"

    b = """
        @@abc
            @@def
                ```julia
                hello
                ```
            @@
            {ABC}
        @@
        """ |> md_blockifier
    @test length(b) == 1
    @test isapproxstr(FP.content(b[1]), "@@def ```julia hello```@@ {ABC}")
end
