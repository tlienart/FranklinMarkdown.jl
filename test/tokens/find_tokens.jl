@testset "Chars" begin
    @test FP.EOS == '\0'
    @test all(e -> e in FP.SPACE_CHAR, (' ', '\n', '\t', FP.EOS))
    @test '0' in FP.NUM_CHAR
    @test '5' in FP.NUM_CHAR
    @test '9' in FP.NUM_CHAR
end

@testset "forward_match" begin
    # no post-check
    r = (s, o, λ, ν) = FP.forward_match("abc")
    @test s == 2 == length("abc") - 1
    @test r isa FP.TokenFinder
    @test λ("abc", false)
    @test !o  # no check of next char
    @test ν   # no check of next char so ok at EOS

    # with post-check
    (s, o, λ, ν) = FP.forward_match("abc", ('α',))
    @test s == 3 == length("abc") - 1 + 1
    @test o   # check of next char
    @test !ν  # not ok at EOS because can't be alpha
    @test λ("abcα", false)
    @test !λ("abc", true)

    # single char
    r = (s, o, λ, ν) = FP.forward_match("{")
    @test s == 0 == length("{") - 1
    @test r isa FP.TokenFinder
    @test λ("{", false)
    @test λ("{", true)
    @test !o
    @test ν
end

@testset "greedy_match" begin
    # no validator
    r = (s, o, λ, ν) = FP.greedy_match(e -> e in FP.NUM_CHAR)
    @test s == -1
    @test !o
    @test λ('1')
    @test !λ('a')
    @test isnothing(ν)
    @test r isa FP.TokenFinder
    # with validator
    r = FP.greedy_match(e -> e in FP.NUM_CHAR, c -> length(c) == 3)
    @test r isa FP.TokenFinder
end

@testset "is_letter_or" begin
    @test FP.is_letter_or('a')
    for c in ('a', 'b', 'α', 'Λ', '-', '_', '0')
        @test FP.is_alphanum_or(c, ('-', '_'))
    end
    @test !FP.is_alphanum_or('\n', ('-',))
end

@testset "is_div_open" begin
    @test FP.is_div_open(1, '@')
    @test !FP.is_div_open(1, 'a')
    for c in ('a', 'α', '-', '_', ',')
        @test FP.is_div_open(2, c)
    end
    @test !FP.is_div_open(2, '*')
end

@testset "is_lang" begin
    r = (s, o, λ, ν) = FP.greedy_match(FP.is_lang(3))
    @test r isa FP.TokenFinder
    @test s == -1
    @test !o
    @test λ(1, '`')
    @test λ(2, '`')
    @test !λ(3, '`')
    # first char must be alpha
    @test λ(3, 'a')
    @test !λ(3, '0')
    @test λ(4, 'a')
    # then allow alphanum and -
    @test λ(4, '0')
    @test λ(4, '-')
    # validator
    @test isnothing(ν)
end

@testset "is_html_entity" begin
    (s, o, λ, ν) = FP.greedy_match(FP.is_html_entity, FP.val_html_entity)
    @test !o
    @test λ(1, 'a')
    @test ν("&#42;")
end

@testset "is_emoji" begin
    (s, o, λ, ν) = FP.greedy_match(FP.is_emoji)
    @test !o
    @test λ(1, '+')
    @test isnothing(ν)
end

@testset "is_footnote" begin
    (s, o, λ, ν) = FP.greedy_match(FP.is_footnote)
    @test !o
    @test λ(1, '^')
    @test λ(2, 'a')
    @test λ(3, ']')
    @test isnothing(ν)
end

@testset "is_hr*" begin
    @test FP.is_hr1(1, '-')
    @test !FP.is_hr1(1, 'a')
    @test FP.is_hr2(1, '_')
    @test !FP.is_hr2(1, 'a')
    @test FP.is_hr3(1, '*')
    @test !FP.is_hr3(1, 'a')
end
