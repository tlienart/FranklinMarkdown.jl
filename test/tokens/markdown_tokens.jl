@testset "tokenize" begin
    s = """
        A { B } C
        D } E { F
        """
    tokens = FP.find_tokens(s, FP.MD_TOKENS)
    names = FP.name.(tokens)
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
    names = FP.name.(tokens)
    @test :COMMENT_OPEN in names
    @test :COMMENT_CLOSE in names
    @test :HORIZONTAL_RULE in names
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
    @test FP.name(t[1]) == :LINE_RETURN_INDENT_4
    @test FP.name(t[2]) == :LINE_RETURN
    @test FP.name(t[3]) == :DBB_OPEN
    @test FP.name(t[4]) == :DBB_CLOSE
end

@testset "md-base" begin
    s = """--> ----"""
    tokens = FP.find_tokens(s, FP.MD_TOKENS)
    @test FP.name(tokens[1]) == :COMMENT_CLOSE
    @test FP.name(tokens[2]) == :HORIZONTAL_RULE
    @test FP.name(tokens[3]) == :EOS
    s = """+++ +++
    """
    tokens = FP.find_tokens(s, FP.MD_TOKENS)
    @test length(tokens) == 3 # 1 +++ 2 \n 3 EOS
    @test FP.name(tokens[1]) == :MD_DEF_BLOCK
    tokens = """~~~ a""" |> FP.default_md_tokenizer
    @test FP.name(tokens[1]) == :RAW_HTML

    tokens = """[^1]: [^ab]""" |> FP.default_md_tokenizer
    @test FP.name(tokens[1]) == :FOOTNOTE_REF
    @test FP.name(tokens[2]) == :FOOTNOTE_REF

    tokens = """]: [^ab]:""" |> FP.default_md_tokenizer
    @test FP.name(tokens[1]) == :LINK_DEF
    @test FP.name(tokens[2]) == :FOOTNOTE_REF

    tokens = """:foobar: and: this: bar""" |> FP.default_md_tokenizer
    @test length(tokens) == 2
    @test FP.name(tokens[1]) == :CAND_EMOJI

    # \\
    tokens = raw"\\, \ , \*" |> FP.default_md_tokenizer
    @test length(tokens) == 3 + 1
    @test FP.name(tokens[1]) == :CHAR_LINEBREAK
    @test FP.name(tokens[2]) == :CHAR_BACKSPACE
    @test FP.name(tokens[3]) == :CHAR_ASTERISK
    tokens = raw"\_, \`, \@, \{, \}, \$" |> FP.default_md_tokenizer
    @test FP.name(tokens[1]) == :CHAR_UNDERSCORE
    @test FP.name(tokens[2]) == :CHAR_BACKTICK
    @test FP.name(tokens[3]) == :CHAR_ATSIGN
    @test FP.name(tokens[4]) == :INACTIVE
    @test FP.name(tokens[5]) == :INACTIVE
    @test FP.name(tokens[6]) == :INACTIVE
    tokens = raw"\[ \] \newenvironment{foo}{a}{b}" |> FP.default_md_tokenizer
    @test FP.name(tokens[1]) == :MATH_C_OPEN
    @test FP.name(tokens[2]) == :MATH_C_CLOSE
    @test FP.name(tokens[3]) == :LX_NEWENVIRONMENT
    @test FP.name(tokens[4]) == :LXB_OPEN
    tokens = raw"\newcommand{a}{b}\begin{a}\end{a}" |> FP.default_md_tokenizer
    @test FP.name(tokens[1]) == :LX_NEWCOMMAND
    @test FP.name(tokens[2]) == :LXB_OPEN
    @test FP.name(tokens[4]) == :LXB_OPEN
    @test FP.name(tokens[6]) == :CAND_LX_BEGIN
    @test FP.name(tokens[9]) == :CAND_LX_END
    tokens = raw"\foo\bar{a}" |> FP.default_md_tokenizer
    @test FP.name(tokens[1]) == :LX_COMMAND
    @test FP.name(tokens[2]) == :LX_COMMAND
    @test tokens[1].ss == raw"\foo"
    @test tokens[2].ss == raw"\bar"
    @test FP.name(tokens[4]) == :LXB_CLOSE

    tokens = raw"@def @@d0 @@d1,d-2 @@" |> FP.default_md_tokenizer
    @test FP.name(tokens[1]) == :MD_DEF_OPEN
    @test FP.name(tokens[2]) == :DIV_OPEN
    @test FP.name(tokens[3]) == :DIV_OPEN
    @test tokens[3].ss == "@@d1,d-2"
    @test FP.name(tokens[4]) == :DIV_CLOSE

    tokens = raw"# ### ####### " |> FP.default_md_tokenizer
    @test FP.name(tokens[1]) == :H1_OPEN
    @test FP.name(tokens[2]) == :H3_OPEN
    @test FP.name(tokens[3]) == :H6_OPEN

    tokens = raw"&amp; & foo" |> FP.default_md_tokenizer
    @test FP.name(tokens[1]) == :CHAR_HTML_ENTITY
    @test length(tokens) == 2

    tokens = raw"$ $$ $a$" |> FP.default_md_tokenizer
    @test FP.name(tokens[1]) == :MATH_A
    @test FP.name(tokens[2]) == :MATH_B
    @test FP.name(tokens[3]) == :MATH_A
    @test FP.name(tokens[4]) == :MATH_A

    tokens = raw"_$>_ _$<_ ___ ****" |> FP.default_md_tokenizer
    @test FP.name(tokens[1]) == :MATH_I_OPEN
    @test FP.name(tokens[2]) == :MATH_I_CLOSE
    @test FP.name(tokens[3]) == :HORIZONTAL_RULE
    @test FP.name(tokens[4]) == :HORIZONTAL_RULE
end

@testset "MD-code" begin
    tokens = raw"` `` ``` ```` `````" |> FP.default_md_tokenizer
    @test FP.name(tokens[1]) == :CODE_SINGLE
    @test FP.name(tokens[2]) == :CODE_DOUBLE
    @test FP.name(tokens[3]) == :CODE_TRIPLE
    @test FP.name(tokens[4]) == :CODE_QUAD
    @test FP.name(tokens[5]) == :CODE_PENTA

    tokens = raw"``` ```! ```julia" |> FP.default_md_tokenizer
    @test FP.name(tokens[1]) == :CODE_TRIPLE
    @test FP.name(tokens[2]) == :CODE_TRIPLE!
    @test FP.name(tokens[3]) == :CODE_LANG3

    tokens = raw"````hello `````foo" |> FP.default_md_tokenizer
    @test FP.name(tokens[1]) == :CODE_LANG4
    @test FP.name(tokens[2]) == :CODE_LANG5
end
