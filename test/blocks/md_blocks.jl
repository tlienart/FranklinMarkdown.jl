include("../testutils.jl")

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
    @test isempty(FP.content_tokens(blocks[1]))
    s = """
        <!--A<!--B-->
        """
    blocks = s |> md_blockifier
    @test FP.name(blocks[1].tokens[1]) == :COMMENT_OPEN
    @test FP.content(blocks[1]) == "A<!--B"
    s = """
        <!--A<!--B-->C-->
        """
    blocks = s |> md_blockifier
    @test FP.content(blocks[1]) == "A<!--B"
    @test len1(blocks)
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
    @test FP.content(blocks[1]) // "julia ABC"
    @test FP.content(blocks[2]) // "julia ABC"
    @test FP.content(blocks[3]) // "julia ABC"

    blocks = "`A` ``A`` ``` A```" |> md_blockifier
    @test FP.content(blocks[1]) == "A"
    @test FP.content(blocks[2]) == "A"
    @test FP.content(blocks[3]) // "A"
    blocks = "```! ABC```" |> md_blockifier
    @test FP.content(blocks[1]) // "! ABC"

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
    @test FP.content(b[1]) // "foo\n`A` ``B``"

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
    @test FP.name(b[1]) == :MATH_INLINE
    @test FP.content(b[1]) == "B"
    b = raw"""
        A $$B$$ C
        """ |> md_blockifier
    @test FP.name(b[1]) == :MATH_DISPL_A
    @test FP.content(b[1]) == "B"
    b = raw"""
        A \[B\] C
        """ |> md_blockifier
    @test FP.name(b[1]) == :MATH_DISPL_B
    @test FP.content(b[1]) == "B"
    # b = raw"""
    #     A _$>_B_$<_ C
    #     """ |> md_blockifier
    # @test FP.name(b[1]) == :MATH_I
    b = raw"""
        A $$B$$ C $D$
        """ |> md_blockifier
    @test FP.name(b[1]) == :MATH_DISPL_A
    @test FP.name(b[2]) == :MATH_INLINE
end

# -----------------------------
# Added to take over commonmark

@testset "emphasis" begin
    # no nest
    b = """
        a *b* c _d_ e _ f g * h
        """ |> md_blockifier
    @test FP.name(b[1]) == :EMPH_EM
    @test FP.content(b[1]) == "b"
    @test FP.name(b[2]) == :EMPH_EM
    @test FP.content(b[2]) == "d"
    @test length(b) == 2

    # nest (we only recover the outer block of course)
    b = """
        **abc_def_ghi**
        """ |> md_blockifier
    @test FP.name(b[1]) == :EMPH_STRONG
    @test FP.content(b[1]) == "abc_def_ghi"
    @test len1(b)
end

@testset "cov" begin
    t = "a *bc* d _ef_ g" |> toks
    b = FP.find_blocks(t)
    @test b[1] // "*bc*"
    @test b[2] // "_ef_"
end

@testset "env" begin
    s = raw"""
        \begin{abc}
        foo
        \end{abc}
        """
    t = s |> toks
    b = FP.find_blocks(t)
    @test b[1].ss // s

    s = raw"""
        \begin{abc}
        \begin{def}
        1
        \end{def}
        2
        \end{abc}
        """
    t = s |> toks
    b = FP.find_blocks(t)
    @test b[1].ss // s

    s = raw"""
        \begin{abc}
        foo
        \end{abc}
        def
        """
    t = s |> toks
    b = FP.find_blocks(t)
    @test b[1].ss // replace(s, "def"=>"")

    s = raw"""
        \newenvironment{foo}{bar:}{:baz}
        \begin{foo}
        abc
        \end{foo}
        ABC
        """
    t = s |> toks
    b = FP.find_blocks(t)
    @test b[5].ss // "\\begin{foo}\nabc\n\\end{foo}"
end

@testset "env issue" begin
    s = raw"""
        \begin{abc}
        foo
        """
    t = s |> toks
    @test_throws FP.FranklinParserException FP.find_blocks(t)
end
