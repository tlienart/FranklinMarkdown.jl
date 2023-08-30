include("../testutils.jl")

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
    @test FP.name(b[1]) == :P_BREAK
    @test strip(s) == "abc" * b[1].ss * "def"
    @test length(b) == 1

    # multiple line skips (should get merged in later stage)
    s = "abc\n\n\ndef"
    b = pass1blocks(s)
    @test FP.name(b[1]) == FP.name(b[2]) == :P_BREAK
    @test length(b) == 2

    # small trick, we don't actually care that much bc it's the start
    # of the string
    s = "\n\ndef"
    b = pass1blocks(s)
    @test FP.name(b[1]) == :P_BREAK
    @test len1(b)
    s = "\n\n\ndef"
    b = pass1blocks(s)
    @test length(b) == 2
    s = "\n\n\n\ndef"
    b = pass1blocks(s)
    @test length(b) == 3

    #
    # HRULE
    #
    s = "\n---"; b = s |> pass1blocks
    @test FP.name(b[1]) == :HRULE
    @test length(b) == 1
    @test b[1].ss   == strip(s)

    for m in ('-','_','*')
        s = "\n $m$m$m $m$m $m$m$m  "; b = s |> pass1blocks
        @test strip(b[1].ss) == strip(s)
        @test FP.name(b[1]) == :HRULE
        @test length(b) == 1
    end

    #
    # ITEM (UL/OL)
    #
    s = "\n- foo"
    b = pass1blocks(s)
    @test FP.name(b[1]) == :ITEM_U_CAND
    @test length(b) == 1

    s = "\n     - foo"
    b = pass1blocks(s)
    @test FP.name(b[1]) == :ITEM_U_CAND
    @test length(b) == 1

    s = "\n 1. foo\n 2. bar\n    1. barfoo"
    b = pass1blocks(s)
    @test all(FP.name(bi) == :ITEM_O_CAND for bi in b)
    @test length(b) == 3

    s = "\n1) foo"
    b = pass1blocks(s)
    @test FP.name(b[1]) == :ITEM_O_CAND

    #
    # BLOCKQUOTE
    #
    s = "> foo"
    b = pass1blocks(s)
    @test len1(b)
    @test FP.name(b[1]) == :BLOCKQUOTE_LINE
    @test strip(b[1].ss) == strip(s)

    s = "\n>foo"
    b = pass1blocks(s)
    @test len1(b)
    @test FP.name(b[1]) == :BLOCKQUOTE_LINE
    @test strip(b[1].ss) == strip(s)

    #
    # TABLE ROW
    #
    s = "\n | a | b | "
    b = pass1blocks(s)
    @test len1(b)
    @test FP.name(b[1]) == :TABLE_ROW_CAND
    s = "\n | a | b | \n | c | d |"
    b = pass1blocks(s)
    @test FP.name(b[1]) == :TABLE_ROW_CAND == FP.name(b[2])
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
    @test FP.name(b[1]) == :ITEM_U_CAND
    @test b[1].ss // s
    @test FP.name.(b[1].tokens)  == [
        :LINE_RETURN,
        :CODE_SINGLE,
        :CODE_SINGLE,
        :EOS
    ]
end
