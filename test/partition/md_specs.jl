# These are extra tests + some tyre kicking with the ordering
# following CommonMark.jl's blocks and some extras
#   ✅ means there's some tests,
#   🚫 means it's not supported because ambiguous with something else
#
# 0 paragraphs ✅
# 1 atxheading ✅
# 2 blockquote ✅
# 3 fencedcodeblock ✅
# x htmlblock 🚫
# x indentedcodeblock 🚫
# 4 list ✅
# x setextheading 🚫
# 5 hrule
# 6 paragraphs
# 7 emphasis *, **, ***, _, __, ___
# 8 autolink <..>
# 9 htmlentity
# x htmlinline 🚫
# 10 image
# 11 inlinecode
# 12 links and footnotes
#
# x hard line breaks 🚫
# 13 comments
# 14 backslash escapes ✅
#
# table blocks
#
# -- Franklin
#
# f1 inline math
# f2 block math
# f3 code block  ✅
# f4 code block with lang ✅
# f5 code block eval ✅
# f6 newenv
# f7 newcom
# f8 com
# f9 env
# f10 lxb
# f11 dbb
# f12 emojis
# f13 def line   @def ...
# f14 def block  +++...+++
# f15 div block
# f16 html block

@testset "0>paragraphs" begin
    # XXX: need to think a bit, when are paragraphs "constructed"?
    # if we construct them early on we might add a level of recursion
    # a bit needlessly also this can only be done a posteriori once all
    # blocks have been figured out. So maybe a good way is to construct
    # a specific AbstractSpan "paragraph" that groups inline blocks into
    # paragraphs
    # ==> this is the distinction between "container" blocks and inline btw
    # --> [ParagraphBlock, Block, Block, ParagraphBlock, ...]
    # ParagraphBlock is an AbstractSpan and contains a bunch of subblocks (text/inline)
    # Block is everything else that's not inline (e.g. code)

    p = """
        abc

        def

        ghi
        """ |> grouper
    @test ct(p[1]) // "abc"
    @test ct(p[2]) // "def"
    @test ct(p[3]) // "ghi"
    @test all(p_i.role == :paragraph for p_i in p)

    p = """
        abc
        ```
        def
        ```
        ghi
        """ |> grouper
    @test ct(p[1]) // "abc"
    @test p[2].role == :none
    @test ctf(p[2]) // "def"
    @test p[3].role == :paragraph
    @test ct(p[3]) // "ghi"

    p = raw"""
        abc `def` ghi $jkl$ &amp; 123 @@c foo@@ end
        """ |> grouper
    @test ct(p[1]) // raw"abc `def` ghi $jkl$ &amp; 123"
    @test ctf(p[2]) // "foo"
    @test ct(p[3]) // "end"

    # nesting should not matter as inner blocks are disabled
    p = raw"""
        abc @@A aa @@B bb @@ @@ def
        """ |> grouper
    @test ct(p[1]) // "abc"
    @test ctf(p[2]) // "aa @@B bb @@"
    @test ct(p[3]) // "def"
end


# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX


@testset "1>atxheading" begin
    p = """
        # a
        ## b
        ### c
        #### d
        ##### e
        ###### f
        """ |> grouper
    @test length(p) == 6
    @test ct(p[1]) // "# a"
    @test ct(p[2]) // "## b"
    @test ct(p[3]) // "### c"
    @test ct(p[4]) // "#### d"
    @test ct(p[5]) // "##### e"
    @test ct(p[6]) // "###### f"
    @test ctf(p[1]) // "a"
    @test ctf(p[2]) // "b"
    # spaces don't matter
    p = """
        # a
            ## b
        """ |> grouper
    @test ctf(p[1]) // "a"
    @test ctf(p[2]) // "b"
end


# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX


@testset "2>blockquotes" begin
    p = """
        > abc
        """ |> grouper
    @test p[1].ss // "> abc"
    p = """
        > abc
        > def
        > ghi
        """ |> grouper
    @test p[1].ss // "> abc\n> def\n> ghi"
    p = """
        > abc
        def

        ghi
        """ |> grouper
    @test p[1].ss // "> abc\ndef"
    @test p[2].ss // "ghi"
    p = """
        > abc
        > def

        >ghi
        > jkl
        """ |> grouper
    @test p[1].ss // "> abc\n> def"
    @test p[2].ss // ">ghi\n> jkl"

    p = """
        > abc
        > > def
        > > ghi
        """ |> grouper
    @test p[1].ss // "> abc\n> > def\n> > ghi"
end


# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX


@testset "3+f3+f4+f5>codeblock" begin
    p = """
        abc
        ```
        def
        ```
        ghi
        """ |> grouper
    @test p[1].role == :paragraph
    @test ctf(p[2]) // "def"
    @test p[3].role == :paragraph

    p = """
        abc
        ````
        def
        ```
        ghi
        ```
        jkl
        ````
        mno
        """ |> grouper
    @test p[1].ss // "abc"
    @test ctf(p[2]) // "def\n```\nghi\n```\njkl"
    @test p[3].ss // "mno"

    p = """
        abc
        ```def
        ghi
        ```
        jkl
        """ |> grouper
    @test ctf(p[2]) // "ghi"

    p = """
        abc
        ```!
        def
        ```
        ghi
        """ |> grouper
    @test ctf(p[2]) // "def"
end


# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX


@testset "4>list" begin
    p = """
        abc
        * i
        * j
            * k
        """ |> grouper
    @test p[1].ss // "abc"
    @test p[2].ss // "* i\n* j\n    * k"

    p = """
        abc
        * i
          * j
        still part of j
          * k
        """ |> grouper
    @test p[1].ss // "abc"
    @test p[2].ss // "* i\n  * j\nstill part of j\n  * k"

    p = """
        abc
        1. i
        1) j
        1 k
        """ |> grouper
    @test p[2].ss // "1. i\n1) j\n1 k"
end


# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX


@testset "5>hrule" begin
    p = """
        abc
        ---
        def
        """ |> grouper
    @test isp(p[1])
    @test p[2].ss // "---"
    @test isp(p[3])

    p = """
        > abc
        ***
        > def
        """ |> grouper
    @test p[1].ss // "> abc"
    @test p[2].ss // "***"
    @test p[3].ss // "> def"

    p = """
        > abc
        xxx
        ___
        > def
        """ |> grouper
    @test p[1].ss // "> abc\nxxx"
    @test p[2].ss // "___"
    @test p[3].ss // "> def"
end


# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX


@testset "14>escapes" begin
    p = raw"abc \_ foo" |> slice
    @test Int('_') == 95
    @test text(p[1]) // "abc &#95; foo"
    for c in raw"""*_`@#{}$~!"%&'+,-./:;<=>?^|"""
        p = "a \\" * c * " b" |> slice
        ic = Int(c)
        @test text(p[1]) // "a &#$(ic); b"
    end
    p = "a \\ b" |> slice
    @test text(p[1]) // "a &#92; b"
end#
