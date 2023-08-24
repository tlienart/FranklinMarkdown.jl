@testset "basics" begin
    s = """
        abc
        def
        """
    @test isempty(pass1blocks(s))

    #
    # NEAR EOS
    #
    s = "abcdef\n-"
    @test isempty(pass1blocks(s))
    s = "abcdef\n\n"
    @test isempty(pass1blocks(s))

    #
    # P_BREAK (seq of \n\n)
    #
    s = "abc\n\ndef"
    b = pass1blocks(s)
    @test b[1].name == :P_BREAK
    @test strip(s) == "abc" * b[1].ss * "def"
    @test length(b) == 1

    # multiple line skips (should get merged in later stage)
    s = "abc\n\n\ndef"
    b = pass1blocks(s)
    @test b[1].name == b[2].name == :P_BREAK
    @test b[1].close == b[2].open
    @test length(b) == 2

    s = "\n\ndef"
    b = pass1blocks(s)
    @test b[1].name == :P_BREAK
    @test length(b) == 1

    #
    # HRULE
    #
    s = "\n---"; b = s |> pass1blocks
    @test b[1].name == :HRULE
    @test length(b) == 1
    @test b[1].ss   == strip(s)

    for m in ('-','_','*')
        s = "\n $m$m$m $m$m $m$m$m  "; b = s |> pass1blocks
        @test strip(b[1].ss) == strip(s)
        @test b[1].name == :HRULE
        @test length(b) == 1
    end

    #
    # ITEM (UL/OL)
    #
    s = "\n- foo"
    b = pass1blocks(s)
    @test b[1].name == :ITEM_U_CAND
    @test length(b) == 1

    s = "\n     - foo"
    b = pass1blocks(s)
    @test b[1].name == :ITEM_U_CAND
    @test length(b) == 1

    s = "\n 1. foo\n 2. bar\n    1. barfoo"
    b = pass1blocks(s)
    @test all(bi.name == :ITEM_O_CAND for bi in b)
    @test length(b) == 3

    s = "\n1) foo"
    b = pass1blocks(s)
    @test b[1].name == :ITEM_O_CAND

    #
    # BLOCKQUOTE
    #
    s = "\n>foo"
    b = pass1blocks(s)
    @test len1(b)
    @test b[1].name == :BLOCKQUOTE_LINE
    @test strip(b[1].ss) == strip(s)

    #
    # TABLE ROW
    #
    s = "\n | a | b | "
    b = pass1blocks(s)
    @test len1(b)
    @test b[1].name == :TABLE_ROW_CAND
    s = "\n | a | b | \n | c | d |"
    b = pass1blocks(s)
    @test b[1].name == :TABLE_ROW_CAND == b[2].name
end

@testset "nonmatching" begin
    #
    # HRULE
    #
    s = "\n--- *"
    b = pass1blocks(s)
    @test isempty(b)
    #
    # ITEMS > UL
    #
    s = "\n++ foo"
    b = pass1blocks(s)
    @test isempty(b)

    #
    # ITEMS > OL
    #
    s = "\n1] foo"
    b = pass1blocks(s)
    @test isempty(b)
    
    #
    # TABLE ROW
    #
    s = "\n| abc "
    b = pass1blocks(s)
    @test isempty(b)
end

@testset "composition" begin
    s = "\n- foo `bar`"
    b = pass1blocks(s)
    @test length(b) == 1
    @test b[1].name == :ITEM_U_CAND
    @test all(t.name == :CODE_SINGLE for t in b[1].inner_tokens)
    @test b[1].ss == strip(s)
end
