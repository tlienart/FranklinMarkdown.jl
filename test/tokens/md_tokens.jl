@testset "tokenize" begin
    s = """
        A { B } C
        D } E { F
        """
    tokens = FP.find_tokens(s, FP.MD_TOKENS)
    names = [t.name for t in tokens]
    @test count(e -> e == :CU_BRACKET_OPEN, names) == 2
    @test count(e -> e == :CU_BRACKET_CLOSE, names) == 2
    @test count(e -> e == :LINE_RETURN, names) == 2
    @test names[end] == :EOS
    @test names[1] == :SOS
    @test length(tokens) == 2 + 2 + 2 + 1 + 1

    s = """
        A <!-- B --> C
        ---
        and +++
        """
    tokens = FP.find_tokens(s, FP.MD_TOKENS)
    names = [t.name for t in tokens]
    @test names == [
        :SOS,
        :COMMENT_OPEN, :COMMENT_CLOSE, :LINE_RETURN,
        :LINE_RETURN,  # hrule are processed as blocks
        :MD_DEF_BLOCK, :LINE_RETURN,
        :EOS
    ]
end

@testset "md-1" begin
    s = """
        { { } { } {{ }} }
        <!--
            hello
          bye
        -->"""
    tokens = FP.find_tokens(s, FP.MD_TOKENS)
    deleteat!(tokens, 1)

    check_tokens(tokens, [1, 2, 4, 6, 7], :CU_BRACKET_OPEN)
    check_tokens(tokens, [3, 5, 8, 9, 10], :CU_BRACKET_CLOSE)

    check_tokens(tokens, [11, 13, 14, 15], :LINE_RETURN)

    check_tokens(tokens, [12], :COMMENT_OPEN)
    check_tokens(tokens, [16], :COMMENT_CLOSE)

    check_tokens(tokens, [17], :EOS)

    @test length(tokens) == 17

    t = """
        abc
            def
        {{abc}}
        """ |> FP.default_md_tokenizer
    deleteat!(t, 1)
    @test t[1].name == t[2].name == :LINE_RETURN
end

@testset "md-base" begin
    s = """* *a _ b_ **a b**"""
    tokens = FP.find_tokens(s, FP.MD_TOKENS)
    deleteat!(tokens, 1)
    @test tokens[1].name == :EM_OPEN
    @test tokens[2].name == :EM_OPEN
    @test tokens[3].name == :EM_CLOSE
    @test tokens[4].name == :STRONG_OPEN
    @test tokens[5].name == :STRONG_CLOSE
    @test tokens[6].name == :EOS
    s = """--> ----"""
    tokens = FP.find_tokens(s, FP.MD_TOKENS)
    deleteat!(tokens, 1)
    @test tokens[1].name == :COMMENT_CLOSE
    @test tokens[2].name == :EOS
    s = """+++ +++
    """
    tokens = FP.find_tokens(s, FP.MD_TOKENS)
    deleteat!(tokens, 1)
    @test length(tokens) == 3 # 1 +++ 2 \n 3 EOS
    @test tokens[1].name == :MD_DEF_BLOCK
    tokens = """~~~ a""" |> FP.default_md_tokenizer
    deleteat!(tokens, 1)
    @test tokens[1].name == :RAW_HTML

    tokens = """:foobar: and: this: bar""" |> FP.default_md_tokenizer
    deleteat!(tokens, 1)
    @test length(tokens) == 2
    @test tokens[1].name == :CAND_EMOJI

    # \\
    tokens = raw"\\, \ , \*" |> FP.default_md_tokenizer
    deleteat!(tokens, 1)
    @test length(tokens) == 3 + 1
    @test tokens[1].name == :LINEBREAK
    @test tokens[2].name == :CHAR_92
    @test tokens[3].name == :CHAR_42
    tokens = raw"\_, \`, \@, \{, \}, \$, \#" |> FP.default_md_tokenizer
    deleteat!(tokens, 1)
    @test tokens[1].name == :CHAR_95
    @test tokens[2].name == :CHAR_96
    @test tokens[3].name == :CHAR_64
    @test tokens[4].name == :CHAR_123
    @test tokens[5].name == :CHAR_125
    @test tokens[6].name == :CHAR_36
    @test tokens[7].name == :CHAR_35
    tokens = raw"\[ \] \newenvironment{foo}{a}{b}" |> FP.default_md_tokenizer
    deleteat!(tokens, 1)
    @test tokens[1].name == :MATH_DISPL_B_OPEN
    @test tokens[2].name == :MATH_DISPL_B_CLOSE
    @test tokens[3].name == :LX_NEWENVIRONMENT
    @test tokens[4].name == :CU_BRACKET_OPEN
    tokens = raw"\newcommand{a}{b}\begin{a}\end{a}" |> FP.default_md_tokenizer
    deleteat!(tokens, 1)
    @test tokens[1].name == :LX_NEWCOMMAND
    @test tokens[2].name == :CU_BRACKET_OPEN
    @test tokens[4].name == :CU_BRACKET_OPEN
    @test tokens[6].name == :LX_BEGIN
    @test tokens[9].name == :LX_END
    tokens = raw"\foo\bar{a}" |> FP.default_md_tokenizer
    deleteat!(tokens, 1)
    @test tokens[1].name == :LX_COMMAND
    @test tokens[2].name == :LX_COMMAND
    @test tokens[1].ss == raw"\foo"
    @test tokens[2].ss == raw"\bar"
    @test tokens[4].name == :CU_BRACKET_CLOSE

    tokens = raw"@def @@d0 @@d1,d-2 @@" |> FP.default_md_tokenizer
    deleteat!(tokens, 1)
    @test tokens[1].name == :MD_DEF_OPEN
    @test tokens[2].name == :DIV_OPEN
    @test tokens[3].name == :DIV_OPEN
    @test tokens[3].ss == "@@d1,d-2"
    @test tokens[4].name == :DIV_CLOSE

    tokens = raw"&amp; & foo" |> FP.default_md_tokenizer
    deleteat!(tokens, 1)
    @test tokens[1].name == :CHAR_HTML_ENTITY
    @test length(tokens) == 2

    tokens = raw"$ $$ $a$" |> FP.default_md_tokenizer
    deleteat!(tokens, 1)
    @test tokens[1].name == :MATH_INLINE
    @test tokens[2].name == :MATH_DISPL_A
    @test tokens[3].name == :MATH_INLINE
    @test tokens[4].name == :MATH_INLINE

    # tokens = raw"_$>_ _$<_ ___ **** ---" |> FP.default_md_tokenizer
    # deleteat!(tokens, 1)
    # @test tokens[1].name == :MATH_I_OPEN
    # @test tokens[2].name == :MATH_I_CLOSE
    # @test tokens[3].name == :EOS
end

@testset "MD-code" begin
    tokens = raw"` `` ``` ```` `````" |> FP.default_md_tokenizer
    deleteat!(tokens, 1)
    @test tokens[1].name == :CODE_SINGLE
    @test tokens[2].name == :CODE_DOUBLE
    @test tokens[3].name == :CODE_TRIPLE
    @test tokens[4].name == :CODE_QUAD
    @test tokens[5].name == :CODE_PENTA

    tokens = raw"``` ```! ```julia" |> FP.default_md_tokenizer
    deleteat!(tokens, 1)
    @test tokens[1].name == :CODE_TRIPLE
    @test tokens[2].name == :CODE_TRIPLE
    @test tokens[3].name == :CODE_TRIPLE

    tokens = raw"````hello `````foo" |> FP.default_md_tokenizer
    deleteat!(tokens, 1)
    @test tokens[1].name == :CODE_QUAD
    @test tokens[2].name == :CODE_PENTA
end
