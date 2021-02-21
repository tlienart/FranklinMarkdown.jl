@testset "tokenize" begin
    s = """
        A { B } C
        D } E { F
        """
    tokens = FP.find_tokens(s, FP.MD_TOKENS)
    names = [t.name for t in tokens]
    @test count(e -> e == :LXB_OPEN, names) == 2
    @test count(e -> e == :LXB_CLOSE, names) == 2
    @test count(e -> e == :LINE_RETURN, names) == 2
    @test names[end] == :EOS
    @test length(tokens) == 2 + 2 + 2 + 1

    s = """
        A <!-- B --> C
        ---
        and +++
        """
    tokens = FP.find_tokens(s, FP.MD_TOKENS)
    names = [t.name for t in tokens]
    @test :COMMENT_OPEN in names
    @test :COMMENT_CLOSE in names
    @test :HRULE in names
    @test :MD_DEF_BLOCK in names
end

@testset "md-1" begin
    s = """
        { { } { } {{ }} }
        <!--
            hello
          bye
        -->"""
    tokens = FP.find_tokens(s, FP.MD_TOKENS)

    check_tokens(tokens, [1, 2, 4], :LXB_OPEN)
    check_tokens(tokens, [3, 5, 8], :LXB_CLOSE)

    check_tokens(tokens, [6], :DBB_OPEN)
    check_tokens(tokens, [7], :DBB_CLOSE)

    check_tokens(tokens, [9, 13], :LINE_RETURN)
    check_tokens(tokens, [11], :LINE_RETURN_INDENT_4)
    check_tokens(tokens, [12], :LINE_RETURN_INDENT_2)

    check_tokens(tokens, [10], :COMMENT_OPEN)
    check_tokens(tokens, [14], :COMMENT_CLOSE)

    check_tokens(tokens, [15], :EOS)

    @test length(tokens) == 15

    t = """
        abc
            def
        {{abc}}
        """ |> FP.default_md_tokenizer
    @test t[1].name == :LINE_RETURN_INDENT_4
    @test t[2].name == :LINE_RETURN
    @test t[3].name == :DBB_OPEN
    @test t[4].name == :DBB_CLOSE
end

@testset "md-base" begin
    s = """--> ----"""
    tokens = FP.find_tokens(s, FP.MD_TOKENS)
    @test tokens[1].name == :COMMENT_CLOSE
    @test tokens[2].name == :HRULE
    @test tokens[3].name == :EOS
    s = """+++ +++
    """
    tokens = FP.find_tokens(s, FP.MD_TOKENS)
    @test length(tokens) == 3 # 1 +++ 2 \n 3 EOS
    @test tokens[1].name == :MD_DEF_BLOCK
    tokens = """~~~ a""" |> FP.default_md_tokenizer
    @test tokens[1].name == :RAW_HTML

    tokens = """[^1]: [^ab]""" |> FP.default_md_tokenizer
    @test tokens[1].name == :FOOTNOTE_REF
    @test tokens[2].name == :FOOTNOTE_REF

    tokens = """]: [^ab]:""" |> FP.default_md_tokenizer
    @test tokens[1].name == :LINK_DEF
    @test tokens[2].name == :FOOTNOTE_REF

    tokens = """:foobar: and: this: bar""" |> FP.default_md_tokenizer
    @test length(tokens) == 2
    @test tokens[1].name == :CAND_EMOJI

    # \\
    tokens = raw"\\, \ , \*" |> FP.default_md_tokenizer
    @test length(tokens) == 3 + 1
    @test tokens[1].name == :LINEBREAK
    @test tokens[2].name == :CHAR_92
    @test tokens[3].name == :CHAR_42
    tokens = raw"\_, \`, \@, \{, \}, \$, \#" |> FP.default_md_tokenizer
    @test tokens[1].name == :CHAR_95
    @test tokens[2].name == :CHAR_96
    @test tokens[3].name == :CHAR_64
    @test tokens[4].name == :CHAR_123
    @test tokens[5].name == :CHAR_125
    @test tokens[6].name == :CHAR_36
    @test tokens[7].name == :CHAR_35
    tokens = raw"\[ \] \newenvironment{foo}{a}{b}" |> FP.default_md_tokenizer
    @test tokens[1].name == :MATH_C_OPEN
    @test tokens[2].name == :MATH_C_CLOSE
    @test tokens[3].name == :LX_NEWENVIRONMENT
    @test tokens[4].name == :LXB_OPEN
    tokens = raw"\newcommand{a}{b}\begin{a}\end{a}" |> FP.default_md_tokenizer
    @test tokens[1].name == :LX_NEWCOMMAND
    @test tokens[2].name == :LXB_OPEN
    @test tokens[4].name == :LXB_OPEN
    @test tokens[6].name == :LX_BEGIN
    @test tokens[9].name == :LX_END
    tokens = raw"\foo\bar{a}" |> FP.default_md_tokenizer
    @test tokens[1].name == :LX_COMMAND
    @test tokens[2].name == :LX_COMMAND
    @test tokens[1].ss == raw"\foo"
    @test tokens[2].ss == raw"\bar"
    @test tokens[4].name == :LXB_CLOSE

    tokens = raw"@def @@d0 @@d1,d-2 @@" |> FP.default_md_tokenizer
    @test tokens[1].name == :MD_DEF_OPEN
    @test tokens[2].name == :DIV_OPEN
    @test tokens[3].name == :DIV_OPEN
    @test tokens[3].ss == "@@d1,d-2"
    @test tokens[4].name == :DIV_CLOSE

    tokens = raw"# ### ####### " |> FP.default_md_tokenizer
    @test tokens[1].name == :H1_OPEN
    @test tokens[2].name == :H3_OPEN
    @test tokens[3].name == :H6_OPEN

    tokens = raw"&amp; & foo" |> FP.default_md_tokenizer
    @test tokens[1].name == :CHAR_HTML_ENTITY
    @test length(tokens) == 2

    tokens = raw"$ $$ $a$" |> FP.default_md_tokenizer
    @test tokens[1].name == :MATH_A
    @test tokens[2].name == :MATH_B
    @test tokens[3].name == :MATH_A
    @test tokens[4].name == :MATH_A

    tokens = raw"_$>_ _$<_ ___ **** ---" |> FP.default_md_tokenizer
    @test tokens[1].name == :MATH_I_OPEN
    @test tokens[2].name == :MATH_I_CLOSE
    @test tokens[3].name == :HRULE
    @test tokens[4].name == :HRULE
    @test tokens[5].name == :HRULE
end

@testset "MD-code" begin
    tokens = raw"` `` ``` ```` `````" |> FP.default_md_tokenizer
    @test tokens[1].name == :CODE_SINGLE
    @test tokens[2].name == :CODE_DOUBLE
    @test tokens[3].name == :CODE_TRIPLE
    @test tokens[4].name == :CODE_QUAD
    @test tokens[5].name == :CODE_PENTA

    tokens = raw"``` ```! ```julia" |> FP.default_md_tokenizer
    @test tokens[1].name == :CODE_TRIPLE
    @test tokens[2].name == :CODE_TRIPLE!
    @test tokens[3].name == :CODE_LANG3

    tokens = raw"````hello `````foo" |> FP.default_md_tokenizer
    @test tokens[1].name == :CODE_LANG4
    @test tokens[2].name == :CODE_LANG5
end

@testset "HR" begin
    s = """---+ ** **** _____""" |> FP.default_md_tokenizer
    @test length(s) == 3 + 1
    @test s[1].name == :HRULE
    @test s[1].ss == "---"
    @test s[2].name == :HRULE
    @test s[2].ss == "****"
    @test s[3].name == :HRULE
    @test s[3].ss == "_____"
end
