@testset "MD_1_TOKENS" begin
    d1 = FP.MD_1_TOKENS
    dn = filter(p -> p.first == '<', FP.MD_N_TOKENS)
    s = """
        { { } { }
        } <!--
        <!--"""
    tokens = FP.tokenize(s, d1, dn)
    @test all(t -> t.name == :LXB_OPEN, tokens[[1, 2, 4]])
    @test all(t -> t.name == :LXB_CLOSE, tokens[[3, 5, 7]])
    @test tokens[6].name == :LINE_RETURN
    @test FP.from(tokens[5]) < FP.from(tokens[6])
    @test FP.to(tokens[5]) < FP.to(tokens[6])
    @test tokens[6].ss == "\n"
    @test all(t -> t.name == :COMMENT_OPEN, tokens[[8, 10]])
    @test tokens[9].name == :LINE_RETURN
    @test tokens[11].name == :EOS
    @test length(tokens) == 11
end

@testset "MD_1_TOKENS_LX" begin
    @test '{' in keys(FP.MD_1_TOKENS_LX)
    @test '}' in keys(FP.MD_1_TOKENS_LX)
end

@testset "MD_N_TOKENS" begin
    s = """--> ----"""
    tokens = FP.tokenize(s, FP.MD_1_TOKENS, FP.MD_N_TOKENS)
    @test tokens[1].name == :COMMENT_CLOSE
    @test tokens[2].name == :HORIZONTAL_RULE
    @test tokens[3].name == :EOS
    s = """+++ +++
    """
    tokens = FP.tokenize(s, FP.MD_1_TOKENS, FP.MD_N_TOKENS)
    @test length(tokens) == 3 # 1 +++ 2 \n 3 EOS
    @test tokens[1].name == :MD_DEF_TOML
    tokens = """~~~ a""" |> FP.md_tokenizer
    @test tokens[1].name == :ESCAPE
    tokens = """[^1]: [^ab]""" |> FP.md_tokenizer
    @test tokens[1].name == :FOOTNOTE_REF
    @test tokens[2].name == :FOOTNOTE_REF
    tokens = """]: [^ab]:""" |> FP.md_tokenizer
    @test tokens[1].name == :LINK_DEF
    @test tokens[2].name == :FOOTNOTE_REF
    tokens = """:foobar: and: this: bar""" |> FP.md_tokenizer
    @test length(tokens) == 2
    @test tokens[1].name == :CAND_EMOJI

    # \\
    tokens = raw"\\, \ , \*" |> FP.md_tokenizer
    @test length(tokens) == 3 + 1
    @test tokens[1].name == :CHAR_LINEBREAK
    @test tokens[2].name == :CHAR_BACKSPACE
    @test tokens[3].name == :CHAR_ASTERISK
    tokens = raw"\_, \`, \@, \{, \}, \$" |> FP.md_tokenizer
    @test tokens[1].name == :CHAR_UNDERSCORE
    @test tokens[2].name == :CHAR_BACKTICK
    @test tokens[3].name == :CHAR_ATSIGN
    @test tokens[4].name == :INACTIVE
    @test tokens[5].name == :INACTIVE
    @test tokens[6].name == :INACTIVE
    tokens = raw"\[ \] \newenvironment{foo}{a}{b}" |> FP.md_tokenizer
    @test tokens[1].name == :MATH_C_OPEN
    @test tokens[2].name == :MATH_C_CLOSE
    @test tokens[3].name == :LX_NEWENVIRONMENT
    @test tokens[4].name == :LXB_OPEN
    tokens = raw"\newcommand{a}{b}\begin{a}\end{a}" |> FP.md_tokenizer
    @test tokens[1].name == :LX_NEWCOMMAND
    @test tokens[2].name == :LXB_OPEN
    @test tokens[4].name == :LXB_OPEN
    @test tokens[6].name == :CAND_LX_BEGIN
    @test tokens[9].name == :CAND_LX_END
    tokens = raw"\foo\bar{a}" |> FP.md_tokenizer
    @test tokens[1].name == :LX_COMMAND
    @test tokens[2].name == :LX_COMMAND
    @test tokens[1].ss == raw"\foo"
    @test tokens[2].ss == raw"\bar"
    @test tokens[4].name == :LXB_CLOSE

    tokens = raw"@def @@d0 @@d1,d-2 @@" |> FP.md_tokenizer
    @test tokens[1].name == :MD_DEF_OPEN
    @test tokens[2].name == :DIV_OPEN
    @test tokens[3].name == :DIV_OPEN
    @test tokens[3].ss == "@@d1,d-2"
    @test tokens[4].name == :DIV_CLOSE

    tokens = raw"# ### ####### " |> FP.md_tokenizer
    @test tokens[1].name == :H1_OPEN
    @test tokens[2].name == :H3_OPEN
    @test tokens[3].name == :H6_OPEN

    tokens = raw"&amp; & foo" |> FP.md_tokenizer
    @test tokens[1].name == :CHAR_HTML_ENTITY
    @test length(tokens) == 2

    tokens = raw"$ $$ $a$" |> FP.md_tokenizer
    @test tokens[1].name == :MATH_A
    @test tokens[2].name == :MATH_B
    @test tokens[3].name == :MATH_A
    @test tokens[4].name == :MATH_A

    tokens = raw"_$>_ _$<_ ___ ****" |> FP.md_tokenizer
    @test tokens[1].name == :MATH_I_OPEN
    @test tokens[2].name == :MATH_I_CLOSE
    @test tokens[3].name == :HORIZONTAL_RULE
    @test tokens[4].name == :HORIZONTAL_RULE
end

@testset "MD_N_TOKENS code" begin
    tokens = raw"` `` ``` ```` `````" |> FP.md_tokenizer
    @test tokens[1].name == :CODE_SINGLE
    @test tokens[2].name == :CODE_DOUBLE
    @test tokens[3].name == :CODE_TRIPLE
    @test tokens[4].name == :CODE_QUAD
    @test tokens[5].name == :CODE_PENTA

    tokens = raw"``` ```! ```julia" |> FP.md_tokenizer
    @test tokens[1].name == :CODE_TRIPLE
    @test tokens[2].name == :CODE_TRIPLE!
    @test tokens[3].name == :CODE_LANG3

    tokens = raw"````hello `````foo" |> FP.md_tokenizer
    @test tokens[1].name == :CODE_LANG4
    @test tokens[2].name == :CODE_LANG5
end
