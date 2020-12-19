@testset "Not closed error"  begin
    s = "<!--"
    @test_throws FP.BlockNotClosed FP.md_blockifier(s)
end

@testset "Comment - no nesting" begin
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

@testset "Other - no nesting" begin
    blocks = "~~~ABC~~~" |> FP.md_blockifier
    @test FP.content(blocks[1]) == "ABC"
    blocks = """
        +++
        ABC
        +++
        """ |> FP.md_blockifier
    # code
    @test strip(FP.content(blocks[1])) == "ABC"
    blocks = "```julia ABC``` ````julia ABC```` `````julia ABC`````" |> FP.md_blockifier
    @test strip(FP.content(blocks[1])) == "ABC"
    @test strip(FP.content(blocks[2])) == "ABC"
    @test strip(FP.content(blocks[3])) == "ABC"
    blocks = "`A` ``A`` ``` A```" |> FP.md_blockifier
    @test FP.content(blocks[1]) == "A"
    @test FP.content(blocks[2]) == "A"
    @test strip(FP.content(blocks[3])) == "A"
    blocks = "```! ABC```" |> FP.md_blockifier
    @test strip(FP.content(blocks[1])) == "ABC"
    # headers
    blocks = """
        # abc
        ## def
        ### ghi
        #### klm
        ##### nop
        ###### qrs
        """ |> FP.md_blockifier
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
    blocks = "{ABC}" |> FP.md_blockifier
    @test FP.content(blocks[1]) == "ABC"
    blocks = "{ABC{DEF}H{IJ}K{L{M}O}P}" |> FP.md_blockifier
    @test FP.content(blocks[1]) == "ABC{DEF}H{IJ}K{L{M}O}P"
end

@testset "Other - nesting" begin
    blocks = """
        @@abc DEF {GHI} KLM @@
        """ |> FP.md_blockifier
    @test strip(FP.content(blocks[1])) == "DEF {GHI} KLM"
end

@testset "@def" begin
    blocks = """
        @def a = 5
        """ |> FP.md_blockifier
    @test strip(FP.content(blocks[1])) == "a = 5"
    blocks = """
        @def a = [1,
            2]
        """ |> FP.md_blockifier
    @test isapproxstr(FP.content(blocks[1]), "a=[1,2]")
end

@testset "Double brace" begin
    blocks = """
        {{abc {g} def}}
        """ |> FP.md_blockifier
    @test FP.content(blocks[1]) == "abc {g} def"
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

    b = """
        +++
        a = "~~~567"
        b = "-->"
        +++
        """ |> FP.md_blockifier
    @test strip(FP.content(b[1])) == "a = \"~~~567\"\nb = \"-->\""

    b = """
        ```foo
        `A` ``B``
        ```
        """ |> FP.md_blockifier
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
        """ |> FP.md_blockifier
    @test length(b) == 1
    @test isapproxstr(FP.content(b[1]), "@@def ```julia hello```@@ {ABC}")
end
