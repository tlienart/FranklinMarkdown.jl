include("../testutils.jl")

@testset "tokenize" begin
    s = """
        A { B } C
        D } E { F
        """
    tokens = FP.default_md_tokenizer(s)
    names = [FP.name(t) for t in tokens]
    # tokens are sorted
    @test names == [
        :SOS,
        :CU_BRACKET_OPEN, :CU_BRACKET_CLOSE, :LINE_RETURN,
        :CU_BRACKET_CLOSE, :CU_BRACKET_OPEN, :LINE_RETURN,
        :EOS
    ]

    s = """
        A <!-- B --> C
        ---
        and +++
        """
    tokens = FP.default_md_tokenizer(s)
    names = [FP.name(t) for t in tokens]
    @test names == [
        :SOS,
        :COMMENT_OPEN, :COMMENT_CLOSE, :LINE_RETURN,
        :LINE_RETURN,
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
    tokens = collect(FP.default_md_tokenizer(s))
    deleteat!(tokens, 1)
    check_tokens(tokens, [1, 2, 4, 6, 7],  :CU_BRACKET_OPEN)
    check_tokens(tokens, [3, 5, 8, 9, 10], :CU_BRACKET_CLOSE)
    check_tokens(tokens, [11, 13, 14, 15], :LINE_RETURN)
    check_tokens(tokens, [12], :COMMENT_OPEN)
    check_tokens(tokens, [16], :COMMENT_CLOSE)
    check_tokens(tokens, [17], :EOS)

    t = """
        abc
            def
        {{abc}}
        """ |> FP.default_md_tokenizer
    @test [FP.name(ti) for ti in t] == [
        :SOS, 
        :LINE_RETURN,
        :LINE_RETURN,
        :CU_BRACKET_OPEN, :CU_BRACKET_OPEN, :CU_BRACKET_CLOSE, :CU_BRACKET_CLOSE,
        :LINE_RETURN, :EOS
    ]
end

@testset "md-base" begin
    s = """* *a _ b_ **a b**"""
    tokens = collect(FP.default_md_tokenizer(s))
    deleteat!(tokens, 1)
    @test [FP.name(t) for t in tokens] == [
        :EM_OPEN, :EM_OPEN, :EM_CLOSE, :STRONG_OPEN, :STRONG_CLOSE, :EOS
    ]
    s = """--> ----"""
    tokens = collect(FP.default_md_tokenizer(s))
    deleteat!(tokens, 1)
    @test FP.name(tokens[1]) == :COMMENT_CLOSE
    @test FP.name(tokens[2]) == :EOS
    s = """+++ +++
    """
    tokens = collect(FP.default_md_tokenizer(s))
    deleteat!(tokens, 1)
    @test length(tokens) == 3 # 1 +++ 2 \n 3 EOS
    @test FP.name(tokens[1]) == :MD_DEF_BLOCK
    tokens = """~~~ a""" |> FP.default_md_tokenizer |> collect
    deleteat!(tokens, 1)
    @test FP.name(tokens[1]) == :RAW_HTML

    tokens = """:foobar: and: this: bar""" |> FP.default_md_tokenizer |> collect
    deleteat!(tokens, 1)
    @test length(tokens) == 2
    @test FP.name(tokens[1]) == :CAND_EMOJI

    # \\
    tokens = raw"\\, \ , \*" |> FP.default_md_tokenizer |> collect
    deleteat!(tokens, 1)
    @test length(tokens) == 3 + 1
    @test FP.name(tokens[1]) == :LINEBREAK
    @test FP.name(tokens[2]) == :CHAR_92
    @test FP.name(tokens[3]) == :CHAR_42
    tokens = raw"\_, \`, \@, \{, \}, \$, \#" |> FP.default_md_tokenizer |> collect
    deleteat!(tokens, 1)
    @test FP.name(tokens[1]) == :CHAR_95
    @test FP.name(tokens[2]) == :CHAR_96
    @test FP.name(tokens[3]) == :CHAR_64
    @test FP.name(tokens[4]) == :CHAR_123
    @test FP.name(tokens[5]) == :CHAR_125
    @test FP.name(tokens[6]) == :CHAR_36
    @test FP.name(tokens[7]) == :CHAR_35
    tokens = raw"\[ \] \newenvironment{foo}{a}{b}" |> FP.default_md_tokenizer |> collect
    deleteat!(tokens, 1)
    @test FP.name(tokens[1]) == :MATH_DISPL_B_OPEN
    @test FP.name(tokens[2]) == :MATH_DISPL_B_CLOSE
    @test FP.name(tokens[3]) == :LX_NEWENVIRONMENT
    @test FP.name(tokens[4]) == :CU_BRACKET_OPEN
    tokens = raw"\newcommand{a}{b}\begin{a}\end{a}" |> FP.default_md_tokenizer |> collect
    deleteat!(tokens, 1)
    @test FP.name(tokens[1]) == :LX_NEWCOMMAND
    @test FP.name(tokens[2]) == :CU_BRACKET_OPEN
    @test FP.name(tokens[4]) == :CU_BRACKET_OPEN
    @test FP.name(tokens[6]) == :LX_BEGIN
    @test FP.name(tokens[9]) == :LX_END
    tokens = raw"\foo\bar{a}" |> FP.default_md_tokenizer |> collect
    deleteat!(tokens, 1)
    @test FP.name(tokens[1]) == :LX_COMMAND
    @test FP.name(tokens[2]) == :LX_COMMAND
    @test tokens[1].ss == raw"\foo"
    @test tokens[2].ss == raw"\bar"
    @test FP.name(tokens[4]) == :CU_BRACKET_CLOSE

    tokens = raw"@def @@d0 @@d1,d-2 @@" |> FP.default_md_tokenizer |> collect
    deleteat!(tokens, 1)
    @test FP.name(tokens[1]) == :MD_DEF_OPEN
    @test FP.name(tokens[2]) == :DIV_OPEN
    @test FP.name(tokens[3]) == :DIV_OPEN
    @test tokens[3].ss == "@@d1,d-2"
    @test FP.name(tokens[4]) == :DIV_CLOSE

    tokens = raw"@@d1,d-2:1/2 @@" |> FP.default_md_tokenizer |> collect
    deleteat!(tokens, 1)
    @test FP.name(tokens[1]) == :DIV_OPEN
    @test tokens[1].ss == "@@d1,d-2:1/2"

    tokens = raw"&amp; & foo" |> FP.default_md_tokenizer |> collect
    deleteat!(tokens, 1)
    @test FP.name(tokens[1]) == :CHAR_HTML_ENTITY
    @test length(tokens) == 2

    tokens = raw"$ $$ $a$" |> FP.default_md_tokenizer |> collect
    deleteat!(tokens, 1)
    @test FP.name(tokens[1]) == :MATH_INLINE
    @test FP.name(tokens[2]) == :MATH_DISPL_A
    @test FP.name(tokens[3]) == :MATH_INLINE
    @test FP.name(tokens[4]) == :MATH_INLINE

    # tokens = raw"_$>_ _$<_ ___ **** ---" |> FP.default_md_tokenizer
    # deleteat!(tokens, 1)
    # @test FP.name(tokens[1]) == :MATH_I_OPEN
    # @test FP.name(tokens[2]) == :MATH_I_CLOSE
    # @test FP.name(tokens[3]) == :EOS
end

@testset "MD-code" begin
    tokens = raw"` `` ``` ```` `````" |> FP.default_md_tokenizer |> collect
    deleteat!(tokens, 1)
    @test FP.name(tokens[1]) == :CODE_SINGLE
    @test FP.name(tokens[2]) == :CODE_DOUBLE
    @test FP.name(tokens[3]) == :CODE_TRIPLE
    @test FP.name(tokens[4]) == :CODE_QUAD
    @test FP.name(tokens[5]) == :CODE_PENTA

    tokens = raw"``` ```! ```julia" |> FP.default_md_tokenizer |> collect
    deleteat!(tokens, 1)
    @test FP.name(tokens[1]) == :CODE_TRIPLE
    @test FP.name(tokens[2]) == :CODE_TRIPLE
    @test FP.name(tokens[3]) == :CODE_TRIPLE

    tokens = raw"````hello `````foo" |> FP.default_md_tokenizer |> collect
    deleteat!(tokens, 1)
    @test FP.name(tokens[1]) == :CODE_QUAD
    @test FP.name(tokens[2]) == :CODE_PENTA
end

@testset "HTML entity" begin
    s = "abc&amp;foo"
    FP.name.(FP.default_md_tokenizer(s)) == [:SOS,:CHAR_HTML_ENTITY,:EOS]
end
