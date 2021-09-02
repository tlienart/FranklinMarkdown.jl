@testset "Not closed error"  begin
    s = "<!--"
    @test_throws FP.FranklinParserException md_blockifier(s)
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
    @test FP.content(blocks[1]) == "A<!--B"
    @test blocks[2].name == :P_BREAK
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
    # XXX this is now two separate things and will error eventually
    blocks = """
        @def a = [1,
            2]
        """ |> md_blockifier
    @test isapproxstr(FP.content(blocks[1]), "a=[1,")
end

@testset "Double brace" begin
    blocks = """
        {{abc {g} def}}
        """ |> md_blockifier
    @test FP.content(blocks[1]) == "abc {g} def"
end

@testset "Ambiguous double braces" begin
    blocks = raw"""
        \a{\b{c}} \a{{b}\c{d}}
        """ |> md_blockifier
    @test blocks[1].ss == raw"\a"
    @test blocks[2].ss == raw"{\b{c}}"
    @test blocks[3].ss == raw"\a"
    @test blocks[4].ss == raw"{{b}\c{d}}"
end

@testset "Mix" begin
    s = """
        <!--~~~ABC~~~-->
        ~~~<!--ABC-->~~~
        """
    blocks = s |> md_blockifier
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
    @test isapproxstr(FP.content(b[1]), "@@def ```julia hello```@@ {ABC}")
end

@testset "maths" begin
    b = raw"""
        A $B$ C
        """ |> md_blockifier
    @test b[1].name == :MATH_INLINE
    @test FP.content(b[1]) == "B"
    b = raw"""
        A $$B$$ C
        """ |> md_blockifier
    @test b[1].name == :MATH_DISPL_A
    @test FP.content(b[1]) == "B"
    b = raw"""
        A \[B\] C
        """ |> md_blockifier
    @test b[1].name == :MATH_DISPL_B
    @test FP.content(b[1]) == "B"
    # b = raw"""
    #     A _$>_B_$<_ C
    #     """ |> md_blockifier
    # @test b[1].name == :MATH_I
    b = raw"""
        A $$B$$ C $D$
        """ |> md_blockifier
    @test b[1].name == :MATH_DISPL_A
    @test b[2].name == :MATH_INLINE
end

@testset "lx-obj" begin
    b = raw"""
        \begin{abc}\end{def}\newcommand{hello}\newenvironment{foo}\bar
        """ |> md_blockifier
    @test b[1].name == :LX_BEGIN
    @test b[2].name == :CU_BRACKETS
    @test b[3].name == :LX_END
    @test b[4].name == :CU_BRACKETS
    @test b[5].name == :LX_NEWCOMMAND
    @test b[6].name == :CU_BRACKETS
    @test b[7].name == :LX_NEWENVIRONMENT
    @test b[8].name == :CU_BRACKETS
    @test b[9].name == :LX_COMMAND
end

# -----------------------------
# Added to take over commonmark

@testset "emphasis" begin
    # no nest
    b = """
        a *b* c _d_ e _ f g * h
        """ |> md_blockifier
    @test b[1].name == :EMPH_EM
    @test FP.content(b[1]) == "b"
    @test b[2].name == :EMPH_EM
    @test FP.content(b[2]) == "d"
    @test b[3].name == :P_BREAK

    # nest (we only recover the outer block of course)
    b = """
        **abc_def_ghi**
        """ |> md_blockifier
    @test b[1].name == :EMPH_STRONG
    @test FP.content(b[1]) == "abc_def_ghi"
    @test b[2].name == :P_BREAK
end

@testset "cov" begin
    t = "a *bc* d _ef_ g" |> toks
    b = FP.find_blocks(t)
    @test b[1] // "*bc*"
    @test b[2] // "_ef_"
end
