@testset "Chars" begin
    @test FP.EOS == '\0'
    @test all(e -> e in FP.SPACE_CHAR, (' ', '\n', '\t', FP.EOS))
    @test '0' in FP.NUM_CHAR
    @test '5' in FP.NUM_CHAR
    @test '9' in FP.NUM_CHAR
end

@testset "forward_match" begin
    # no post-check
    tf = FP.forward_match("abc")
    @test tf.steps == 2 == length("abc") - 1
    @test tf isa FP.TokenFinder
    @test FP.fixed_lookahead(tf, FP.subs("abc"), false) == (true, 0)
    @test isempty(tf.check.pattern)

    # with post-check
    tf = FP.forward_match("abc", ['α'])
    @test tf.steps == 3 == length("abc") - 1 + 1
    @test FP.fixed_lookahead(tf, FP.subs("abcα"), false) == (true, 1)
    @test FP.fixed_lookahead(tf, FP.subs("abcα"), true) == (false, 0)

    # single char
    tf = FP.forward_match("{")
    @test tf.steps == 0 == length("{") - 1
    @test FP.fixed_lookahead(tf, FP.subs("{"), false) == (true, 0)
    @test FP.fixed_lookahead(tf, FP.subs("{"), true) == (true, 0)
end

@testset "greedy_match" begin
    tf = FP.greedy_match(tail_chars=FP.NUM_CHAR)
    @test tf.steps == -1
    @test FP.greedy_lookahead(tf, 1, '1')
    @test !FP.greedy_lookahead(tf, 1, 'a')
    @test tf isa FP.TokenFinder
    @test isempty(tf.check.pattern)
    # with check
    tf = FP.greedy_match(tail_chars=FP.NUM_CHAR, check=r"^\d{3}$")
    @test FP.greedy_lookahead(tf, 1, '1')
    @test FP.greedy_lookahead(tf, 2, '2')
    @test FP.greedy_lookahead(tf, 3, '3')
    @test FP.check(tf, FP.subs("123"))
    @test !FP.check(tf, FP.subs("1234"))
end

@testset "is_div_open" begin
    tf = FP.F_DIV_OPEN
    @test FP.greedy_lookahead(tf, 1, '@')
    @test !FP.greedy_lookahead(tf, 2, '@')
    for c in ('a', 'Z')
        @test FP.greedy_lookahead(tf, 2, c)
    end
    # not allowed as first char
    for c in ('1', '_', 'α')
        @test !FP.greedy_lookahead(tf, 2, c)
    end
    # allowed as subsequent char
    for c in ('1', '_', 'a', 'Z')
        @test FP.greedy_lookahead(tf, 3, c)
    end
end

@testset "is_latex_command" begin
    tf = FP.F_LX_COMMAND
    @test FP.greedy_lookahead(tf, 1, 'a')
    @test FP.check(tf, FP.subs("\\abcd"))
    @test !FP.check(tf, FP.subs("\\_abcd"))
    @test FP.check(tf, FP.subs("\\abcd1"))
end

@testset "is_lang" begin
    tf = FP.F_LANG_3
    @test FP.greedy_lookahead(tf, 1, '`')
    @test FP.greedy_lookahead(tf, 2, '`')
    @test !FP.greedy_lookahead(tf, 3, '`')
    @test FP.greedy_lookahead(tf, 3, 'j')
    @test FP.check(tf, FP.subs("```julia"))
    @test !FP.check(tf, FP.subs("```013"))

    tf = FP.F_LANG_4
    @test FP.greedy_lookahead(tf, 3, '`')
    @test !FP.greedy_lookahead(tf, 4, '`')
    @test FP.check(tf, FP.subs("````hello"))
    @test !FP.check(tf, FP.subs("```hello"))
    @test !FP.check(tf, FP.subs("`````hello"))

    tf = FP.F_LANG_5
    @test FP.greedy_lookahead(tf, 4, '`')
    @test !FP.greedy_lookahead(tf, 6, '`')
    @test !FP.check(tf, FP.subs("```hello"))
    @test !FP.check(tf, FP.subs("````hello"))
    @test FP.check(tf, FP.subs("`````hello"))
    @test !FP.check(tf, FP.subs("``````hello"))
end

@testset "is_html_entity" begin
    tf = FP.F_HTML_ENTITY
    @test FP.greedy_lookahead(tf, 2, 'a')
    @test !FP.greedy_lookahead(tf, 2, 'α')
    @test FP.check(tf, FP.subs("&#42;"))
end

@testset "is_emoji" begin
    tf = FP.F_EMOJI
    for c in ('a', '+', '_', '-')
        @test FP.greedy_lookahead(tf, 1, c)
    end
    @test FP.check(tf, FP.subs(":smile:"))
end

@testset "is_footnote" begin
    tf = FP.F_FOOTNOTE
    @test FP.check(tf, FP.subs("[^hello]:"))
    @test FP.check(tf, FP.subs("[^h1]"))
end

@testset "regexes" begin
    tf = FP.F_LX_COMMAND
    for c in (FP.subs(raw"\abc"), FP.subs(raw"\abc_def"))
        @test FP.check(tf, c)
    end

    for c in (FP.subs(raw"\abc "), FP.subs(raw"\abc1_def*"), FP.subs(raw"\abc**"),
              FP.subs(raw"\a*bc"), FP.subs(raw"\abc1_"),  FP.subs(raw"\_abc1"))
        @test !FP.check(tf, c)
    end

    tf = FP.F_HTML_ENTITY
    for e in ("&sqcap;", "&SquareIntersection;", "&#x02293;", "&#8851;",
              "&Succeeds;", "&frac78;", "&gEl;", "&gnapprox;")
        @test FP.check(tf, FP.subs(e))
    end
    @test !FP.check(tf, FP.subs("&42;"))
end
