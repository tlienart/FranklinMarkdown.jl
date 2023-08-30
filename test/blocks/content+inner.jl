include("../testutils.jl")

@testset "simple containers" begin
    inner = "\n`abc`\n"
    cases = Dict(
        :COMMENT => "<!--$inner-->",
        :RAW_HTML => "~~~$inner~~~",
        :RAW_LATEX => "%%%$inner%%%",
        :MD_DEF_BLOCK => "+++$inner+++",
    )
    for (k, v) in cases
        p = slice(v)
        @test len1(p)
        @test FP.name(p[1]) == k
        @test p[1].ss // v
        @test FP.content_tokens(p[1]) == p[1].tokens[2:end-1]
        for j in (2,5)
            @test FP.name(p[1].tokens[j]) == :LINE_RETURN
        end
        for j in 3:4
           @test FP.name(p[1].tokens[j]) == :CODE_SINGLE
        end
        @test FP.content(p[1]) // "`abc`"
    end
end


@testset "lx env" begin
    s = raw""" 
        \begin{foo}`abc`\end{foo}
        """
    p = slice(s)
    @test len1(p)
    @test FP.name(p[1]) == :ENV
    @test FP.env_name(p[1]) == "foo"
    @test FP.content(p[1]) == "`abc`"
    
    @test FP.name(p[1].tokens[1]) == :LX_BEGIN
    @test FP.name(p[1].tokens[end-2]) == :LX_END
 
    # CONTENT TOKENS
    _ct = FP.content_tokens(p[1])
    @test length(_ct) == 2
    @test FP.name(_ct[1]) == FP.name(_ct[2]) == :CODE_SINGLE
end


@testset "links" begin
    # links are empty blocks so the slicing is a bit tricky
    s = raw"[abc]: `foo`"
    p = slice(s)
    @test len1(p)
    @test p[1].ss // s
    @test [FP.name(t) for t in FP.content_tokens(p[1])] == [:CODE_SINGLE, :CODE_SINGLE]
end


@testset "prev_token_idx & slice" begin
    s = "a &amp; b ~~~c~~~"
    p = slice(s)
    @test [FP.name(t) for t in FP.content_tokens(p[1])] == [:CHAR_HTML_ENTITY]

    s = "a &amp; b\n* foo `x`"
    p = slice(s)
    @test [FP.name(t) for t in FP.content_tokens(p[1])] == [:CHAR_HTML_ENTITY, :LINE_RETURN]
    @test [
        FP.name(t) for t in FP.content_tokens(p[2])
    ] == [:CODE_SINGLE, :CODE_SINGLE, :EOS]

    s = "a &amp; b\n* foo\n* bar\nother"
    p = slice(s)
    @test [FP.name(t) for t in FP.content_tokens(p[1])] == [:CHAR_HTML_ENTITY, :LINE_RETURN]

    s = "a &amp; b\n* foo"
    p = slice(s)
    @test [FP.name(t) for t in FP.content_tokens(p[1])] == [:CHAR_HTML_ENTITY, :LINE_RETURN]

    s = "a b [abc]()"
    p = slice(s)
    @test isempty(FP.content_tokens(p[1]))

    # ============

    s = "ab ~~~c~~~ &amp; ~~~d~~~"
    p = slice(s)
    @test FP.name(p[3].tokens[1]) == :CHAR_HTML_ENTITY
    @test len1(p[3].tokens)

    s = "ab ~~~c~~~ &amp;"
    p = slice(s)
    @test FP.name(p[3].tokens[1]) == :CHAR_HTML_ENTITY
    @test len1(p[3].tokens)

    s = "ab [c]() &amp; [d]() `foo`"
    p = slice(s)
    @test [FP.name(t) for t in p[5].tokens] == [:CODE_SINGLE, :CODE_SINGLE]
end


@testset "utils" begin
    #
    # CONTENT
    #
    p = "abc ~~~d~~~ ef" |> slice
    @test FP.content(p[2]) == "d"

    p = raw"abc \begin{foo}ab`cd`&amp;\end{foo} def" |> slice
    @test FP.content(p[2]) == "ab`cd`&amp;"

    p = raw"abc {{def}} ghi" |> slice
    @test FP.content(p[2]) == "def"

    p = "abc\n[aaa]: foo\n\nbar" |> slice
    @test FP.content(p[2]) == "foo"

    p = "abc\n[aaa]: foo\nbar" |> slice
    @test FP.content(p[2]) == "foo\nbar"

    p = """
        abc
        > a1
        > a2 &amp;
        > a3 `bb`
        a4

        def
        """ |> slice
    @test FP.content(p[2]) == "a1\na2 &amp;\na3 `bb`\na4"
    @test filter(n -> n != :LINE_RETURN, tnames(FP.content_tokens(p[2]))) == [
        :CHAR_HTML_ENTITY, :CODE_SINGLE, :CODE_SINGLE
    ]

    #
    # CONTENT_TOKENS
    #

    p = raw"abc {{d`ef`g}} klm" |> slice
    @test tnames(FP.content_tokens(p[2])) == [:CODE_SINGLE, :CODE_SINGLE] 

    #
    # ENV_NAME
    #
    p = raw"""
        abc
        \begin{foobar}
        baz &amp; &copy;
        \end{foobar}
        def
        """ |> slice
    @test FP.env_name(p[2]) == "foobar"
    @test FP.content(p[2]) // "baz &amp; &copy;"

    #
    # LINK_A and LINK_B
    #
end
