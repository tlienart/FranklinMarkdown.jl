@testset "subs" begin
    @test FP.subs("abc") == "abc"
    @test FP.subs("abc") !== "abc"
    @test FP.subs("abc") isa SubString
    @test FP.subs("abcd", 2) == "b"
    @test FP.subs("abcd", 2, 3) == "bc"
    @test FP.subs("abcd", 2:3) == "bc"
    a = FP.subs("abc")
    @test FP.subs(a) === a
    # invalid string indices
    @test_throws StringIndexError FP.subs("jμΛια", 2:3)
end

@testset "parent_string" begin
    s = "abcd"
    @test FP.parent_string(s) === s
    @test FP.parent_string(FP.subs(s, 2)) === s
end

@testset "from, to" begin
    s = "abcdef"
    @test FP.from(s) == firstindex(s)
    @test FP.to(s) == lastindex(s)
    ss = FP.subs(s, 2:3)
    @test FP.from(ss) == 2
    @test FP.to(ss) == 3
end

@testset "dedent" begin
    for wsp in ("    ", " ", "\t")
        @test FP.dedent("""
            $(wsp)hello
            $(wsp)bye
            """) == """
            hello
            bye
            """
        @test FP.dedent("""
            $(wsp)$(wsp)hello
            $(wsp)bye
            """) == """
            $(wsp)hello
            bye
            """
        @test FP.dedent("""
            $(wsp)abc

            $(wsp)def
            """) == """
            abc

            def
            """
    end
    # mixing
    wsp = "\t"
    @test FP.dedent("""
        $(wsp) hello
        $(wsp)$(wsp)bye
        """) == """
         hello
        $(wsp)bye
        """
    @test FP.dedent("""
         $(wsp)hello
        $(wsp)$(wsp)bye
        """) == """
         $(wsp)hello
        $(wsp)$(wsp)bye
        """
end

@testset "prev/next chars" begin
    s = "abc def ghi"
    ss = FP.subs(s, 5:7)
    @test FP.previous_chars(ss, 3) == ['b', 'c', ' ']
    @test FP.next_chars(ss, 3) == [' ', 'g', 'h']
    s = "jμΛι∀γϵ∛Ϡe"
    ss = FP.subs(s, 4:8)
    @test FP.previous_chars(ss, 2) == ['j', 'μ']
    @test FP.next_chars(ss, 3) == ['γ', 'ϵ', '∛']
end
