# ✅ 1 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/inline-autolink.md
# ✅ 2 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/inline-backticks.md
# ✅ 3 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/inline-em-flat.md
# ✅ 4 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/inline-em-nested.md
# ✅ 5 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/inline-em-worst.md
# ✅ 6 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/inline-entity.md
# ✅ 7 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/inline-escape.md
# 🚫 8 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/inline-html.md
# ✅ 9 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/inline-links-flat.md
# ✅ 10 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/inline-links-nested.md
# 🚫 11 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/inline-newlines.md

@testset "1|autolinks" begin
    s = """
        closed (valid) autolinks:

        <ftp://1.2.3.4:21/path/foo>
        <http://foo.bar.baz?q=hello&id=22&boolean>
        <http://veeeeeeeeeeeeeeeeeeery.loooooooooooooooooooooooooooooooong.autolink/>
        <teeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeest@gmail.com>

        these are not autolinks:

        <ftp://1.2.3.4:21/path/foo
        <http://foo.bar.baz?q=hello&id=22&boolean
        <http://veeeeeeeeeeeeeeeeeeery.loooooooooooooooooooooooooooooooong.autolink
        <teeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeest@gmail.com
        < http://foo.bar.baz?q=hello&id=22&boolean >
        """
    b = s |> md_blockifier
    a = filter!(e -> FP.name(e) == :AUTOLINK, b)
    @test a[1] // "<ftp://1.2.3.4:21/path/foo>"
    @test a[2] // "<http://foo.bar.baz?q=hello&id=22&boolean>"
    @test a[3] // "<http://veeeeeeeeeeeeeeeeeeery.loooooooooooooooooooooooooooooooong.autolink/>"
    @test a[4] // "<teeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeest@gmail.com>"
    @test length(a) == 4
end

# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX

@testset "2|backticks" begin
    s = """
        `lots`of`backticks`

        ``i``wonder``how``this``will``be``parsed``
        """
    b = s |> md_blockifier
    filter!(e -> !(e // "\n"), b)
    @test b[1] // "`lots`"
    @test b[2] // "`backticks`"
    @test b[3] // "``i``"
    @test b[4] // "``how``"
    @test b[5] // "``will``"
    @test b[6] // "``parsed``"
end

# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX

@testset "3|em" begin
    s = """
        *this* *is* *your* *basic* *boring* *emphasis*

        _this_ _is_ _your_ _basic_ _boring_ _emphasis_

        **this** **is** **your** **basic** **boring** **emphasis**
        """
    b = s |> md_blockifier
    filter!(e -> !(e // "\n"), b)
    @test ct(b[1]) // "this"
    @test ct(b[2]) // "is"
    @test ct(b[3]) // "your"

    @test ct(b[7]) // "this"
    @test ct(b[8]) // "is"
    @test ct(b[9]) // "your"

    @test ct(b[13]) // "this"
    @test ct(b[14]) // "is"
    @test ct(b[15]) // "your"
end

# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX

@testset "4|em2" begin
    s = """
        *this *is *a *bunch* of* nested* emphases*

        __this __is __a __bunch__ of__ nested__ emphases__

        ***this ***is ***a ***bunch*** of*** nested*** emphases***
        """
    b = s |> md_blockifier
    filter!(e -> !(e // "\n"), b)

    @test b[1] // "*this *is *a *bunch* of* nested* emphases*"
    @test b[2] // "__this __is __a __bunch__ of__ nested__ emphases__"
    @test b[3] // "***this ***is ***a ***bunch*** of*** nested*** emphases***"
end

# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX

@testset "5|em3" begin
    b = """
        *this *is *a *worst *case *for *em *backtracking

        __this __is __a __worst __case __for __em __backtracking

        ***this ***is ***a ***worst ***case ***for ***em ***backtracking
        """ |> md_blockifier
    filter!(e -> !(e // "\n"), b)
    @test length(b) == 0
end

# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX

@testset "6|entity" begin
    s = """
        entities:

        &nbsp; &amp; &copy; &AElig; &Dcaron; &frac34; &HilbertSpace; &DifferentialD; &ClockwiseContourIntegral;

        &#35; &#1234; &#992; &#98765432;

        non-entities:

        &18900987654321234567890; &1234567890098765432123456789009876543212345678987654;

        &qwertyuioppoiuytrewqwer; &oiuytrewqwertyuioiuytrewqwertyuioytrewqwertyuiiuytri;
        """
    t = s |> toks |> collect
    filter!(t -> FP.name(t) ∉ FP.MD_IGNORE, t)

    gt = ["&nbsp;", "&amp;", "&copy;", "&AElig;", "&Dcaron;", "&frac34;",
          "&HilbertSpace;", "&DifferentialD;", "&ClockwiseContourIntegral;",
          "&#35;", "&#1234;", "&#992;"]

    for i in 1:12
        @test t[i] // gt[i]
    end

    # NOTE: we do not validate the names, so the last two entities ARE caught as such
    # this does not have consequences though
    # however, we don't accept &#98765432; as it has too many chars.

    # fewer than 32 characters
    @test t[13] // "&qwertyuioppoiuytrewqwer;"

    # last one is not taken as it's more than 32.
end

# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX

@testset "7|escapes" begin
    s = raw"""
        \!\"\#\$\%\&\'\*\+\,\.\/\:\;\<\=\>\?


        \@ \^ \_ \` \{ \| \} \~ \- \'

        <!--
        Not OK as clash with something else (latex/math/...)

            \t\e\s\t\i\n\g \e\s\c\a\p\e \s\e\q\u\e\n\c\e\s
            \\\(\)
            \[ \]
            \
            \\
            \\\
            \\\\
            \\\\\
        -->
        """
    b = s |> slice
    for (t, gt) in zip(filter(t -> FP.name(t) ∉ FP.MD_IGNORE, FP.content_tokens(b[1])), [
                        raw"\!", raw"\#", raw"\$", raw"\%", raw"\&",
                        raw"\'", raw"\*", raw"\+", raw"\,", raw"\.",
                        raw"\/", raw"\:", raw"\;", raw"\<", raw"\=", raw"\>", raw"\?"])
        @test t // gt
    end
    for (t, gt) in zip(filter(t -> FP.name(t) ∉ FP.MD_IGNORE, FP.content_tokens(b[4])), [
                        raw"\@", raw"\^", raw"\_", raw"\`", raw"\{",
                        raw"\|", raw"\}", raw"\~", raw"\-", raw"\'"])
        @test t // gt
    end
end

# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX

@testset "9|links" begin
    # cropped example as we're stricter than CM
    s = """
        Valid links:

         [this is a link]()
         [this is a link](<http://something.example.com/foo/bar>)
         [this is a link](http://something.example.com/foo/bar 'test')
         ![this is an image]()
         ![this is an image](<http://something.example.com/foo/bar>)
         ![this is an image](http://something.example.com/foo/bar 'test')
        """
    b = s |> md_blockifier
    filter!(!isempty, b)

    @test b[1] // "[this is a link]()"
    @test b[2] // "[this is a link](<http://something.example.com/foo/bar>)"
    @test b[3] // "[this is a link](http://something.example.com/foo/bar 'test')"
    @test b[4] // "![this is an image]()"
    @test b[5] // "![this is an image](<http://something.example.com/foo/bar>)"
    @test b[6] // "![this is an image](http://something.example.com/foo/bar 'test')"
end

@testset "10|links2" begin
    s = """
        Valid links:

        [[[[[[[[](test)](test)](test)](test)](test)](test)](test)]

        [ [[[[[[[[[[[[[[[[[[ [](test) ]]]]]]]]]]]]]]]]]] ](test)
        """
    b = s |> md_blockifier
    filter!(!isempty, b)
    @test b[1] // "[[[[[[[[](test)](test)](test)](test)](test)](test)](test)]"
    @test b[2] // "[ [[[[[[[[[[[[[[[[[[ [](test) ]]]]]]]]]]]]]]]]]] ](test)"
end
