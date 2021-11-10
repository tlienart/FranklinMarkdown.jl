# ✅ 1 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/block-bq-flat.md
# ✅ 2 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/block-bq-nested.md
# 🚫 3 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/block-code.md
# ✅ 4 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/block-fences.md
# ✅ 5 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/block-heading.md
# ✅ 6 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/block-hr.md
# 🚫 7 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/block-html.md
# 🚫 8 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/block-lheading.md
# ✅ 9 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/block-list-flat.md
# ✅ 10 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/block-list-nested.md
# ✅ 11 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/block-ref-flat.md
# 12 https://github.com/MichaelHatherly/CommonMark.jl/blob/master/test/samples/cmark/block-ref-nested.md

# NOTE: a bunch of those are validated/resolved at Franklin level

@testset "1|blockquote" begin
    s = """
        > the simple example of a blockquote
        > the simple example of a blockquote
        > the simple example of a blockquote
        > the simple example of a blockquote
        ... continuation
        ... continuation
        ... continuation
        ... continuation

        empty blockquote:

        >
        >
        >
        >
        """
    g = s |> grouper
    g[1] // """
        > the simple example of a blockquote
        > the simple example of a blockquote
        > the simple example of a blockquote
        > the simple example of a blockquote
        ... continuation
        ... continuation
        ... continuation
        ... continuation
        """
    g[2] // "empty blockquote:"
    g[3] // """
        >
        >
        >
        >
        """
    @test isapproxstr(FP.content(g[1].blocks[1]), """
        the simple example of a blockquote
        the simple example of a blockquote
        the simple example of a blockquote
        the simple example of a blockquote
        ... continuation
        ... continuation
        ... continuation
        ... continuation
        """)
end

# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX

@testset "2|blockquote2" begin
    s = """
        >>>>>> deeply nested blockquote
        >>>>> deeply nested blockquote
        >>>> deeply nested blockquote
        >>> deeply nested blockquote
        >> deeply nested blockquote
        > deeply nested blockquote

        > deeply nested blockquote
        >> deeply nested blockquote
        >>> deeply nested blockquote
        >>>> deeply nested blockquote
        >>>>> deeply nested blockquote
        >>>>>> deeply nested blockquote
        """
    g = s |> grouper
    @test length(g) == 2
    @test g[1].ss // """
        >>>>>> deeply nested blockquote
        >>>>> deeply nested blockquote
        >>>> deeply nested blockquote
        >>> deeply nested blockquote
        >> deeply nested blockquote
        > deeply nested blockquote
        """
    @test g[2].ss // """
        > deeply nested blockquote
        >> deeply nested blockquote
        >>> deeply nested blockquote
        >>>> deeply nested blockquote
        >>>>> deeply nested blockquote
        >>>>>> deeply nested blockquote
        """
end

# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX

@testset "4|codefence" begin
    # NOTE: we only allow up to 5 backticks
    s = """

        `````text
        an
        example
        ```
        of


        a fenced
        ```
        code
        block
        `````
        """
    g = s |> grouper
    @test g[1].ss // s
end

# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX

@testset "5|heading" begin
    s = raw"""
        # heading
        ### heading
        ##### heading

        # heading #
        ### heading ###
        ##### heading \#\#\#\#\######

        ############ not a heading
        """
    g = s |> grouper
    @test g[1] // "# heading"
    @test g[2] // "### heading"
    @test g[3] // "##### heading"

    @test g[5] // "# heading #"
    @test g[6] // "### heading ###"
    @test g[7] // raw"##### heading \#\#\#\#\######"

    @test g[8] // "\n############ not a heading"
    @test isp(g[8])
end

# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX

@testset "6|hrules" begin
    # NOTE: here we're stricter and require a triple
    s = """

         * * * * *
         *** * *

         -  -  -  -  -
         --- -

         ________


         ************************* text
        """
    g = s |> grouper
    filter!(!isempty, g)
    @test g[1] // "* * * * *"
    @test g[1].role == :LIST # NOTE: gets invalidated at Franklin level
    @test g[2] // "*** * *"
    @test g[2].role == :HRULE
    @test g[3].role == :LIST
    @test g[3] // "-  -  -  -  -"
    @test g[4].role == :HRULE
    @test g[4] // "--- -"
    @test g[5] // "________"
    @test g[5].role == :HRULE
    @test g[6] // "************************* text"
    @test isp(g[6])
end

# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX

@testset "9|list" begin
    s = """
        - tidy
        - bullet
        - list


        - loose

        - bullet

        - list


        0. ordered
        1. list
        2. example


        -
        -
        -
        -


        1.
        2.
        3.


        -  an example
        of a list item
              with a continuation

           this part is inside the list

          this part is just a paragraph


        1. test
        -  test
        1. test
        -  test


        111111111111111111111111111111111111111111. is this a valid bullet?
        """
    g = s |> grouper
    @test g[1] // """
        - tidy
        - bullet
        - list
        """
    # NOTE we don't allow loose lists so they're each their own group...
    @test g[2] // "- loose"
    @test g[3] // "- bullet"
    @test g[4] // "- list"

    @test g[5] // """
        0. ordered
        1. list
        2. example
        """
    @test g[6] // """
        -
        -
        -
        -
        """
    @test g[7] // """
        1.
        2.
        3.
        """
    # a line skip breaks a list
    @test g[8] // """
        -  an example
        of a list item
              with a continuation
        """
    @test g[11] // """
        1. test
        -  test
        1. test
        -  test
        """

    # at most 9 chars
    @test g[12].role == :PARAGRAPH
end

# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX

@testset "10|nestedlist" begin
    s = """

         - this
           - is
             - a
               - deeply
                 - nested
                   - bullet
                     - list


         1. this
            2. is
               3. a
                  4. deeply
                     5. nested
                        6. unordered
                           7. list


         - 1
          - 2
           - 3
            - 4
             - 5
              - 6
               - 7
              - 6
             - 5
            - 4
           - 3
          - 2
         - 1


         - - - - - - - - - deeply-nested one-element item

        """
    g = s |> grouper
    @test isapproxstr(g[1].ss, """
    - this
      - is
        - a
          - deeply
            - nested
              - bullet
                - list""")
    isapproxstr(g[2].ss, """
        1. this
           2. is
              3. a
                 4. deeply
                    5. nested
                       6. unordered
                          7. list
                          """)
    isapproxstr(g[3].ss, """
        - 1
         - 2
          - 3
           - 4
            - 5
             - 6
              - 7
             - 6
            - 5
           - 4
          - 3
         - 2
        - 1
        """)

    @test g[4] // "- - - - - - - - - deeply-nested one-element item"
end

# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX

@testset "11|ref" begin
    s = """
        [1] [2] [3] [1] [2] [3]

        [looooooooooooooooooooooooooooooooooooooooooooooooooong label]

         [1]: <http://something.example.com/foo/bar>
         [2]: http://something.example.com/foo/bar 'test'
         [3]:
         http://foo/bar
         [    looooooooooooooooooooooooooooooooooooooooooooooooooong   label    ]:
         111
         'test'
         [[[[[[[[[[[[[[[[[[[[ this should not slow down anything ]]]]]]]]]]]]]]]]]]]]: q
         (as long as it is not referenced anywhere)

         <!-- [[[[[[[[[[[[[[[[[[[[]: this is not a valid reference -->
        """
     g = s |> grouper
     filter!(!isempty, g)
     @test g[1].blocks[1] // "[1]"
     @test g[1].blocks[1].name == :LINK_A
     @test g[2].blocks[2] // "[looooooooooooooooooooooooooooooooooooooooooooooooooong label]"
     @test g[2].blocks[2].name == :LINK_A

     @test g[3] // "[1]: <http://something.example.com/foo/bar>"
     @test g[4] // "[2]: http://something.example.com/foo/bar 'test'"
     @test g[5] // "[3]:\n http://foo/bar"
     @test g[6] // """
        [    looooooooooooooooooooooooooooooooooooooooooooooooooong   label    ]:
         111
         'test'
        """
    @test g[7] // """
        [[[[[[[[[[[[[[[[[[[[ this should not slow down anything ]]]]]]]]]]]]]]]]]]]]: q
         (as long as it is not referenced anywhere)"""
end

@testset "12|nestedref" begin
    s = """
        [[[[[[[foo]]]]]]]

        [[[[[[[foo]]]]]]]: bar
        [[[[[[foo]]]]]]: bar
        [[[[[foo]]]]]: bar
        [[[[foo]]]]: bar
        [[[foo]]]: bar
        [[foo]]: bar
        [foo]: bar

        [*[*[*[*[foo]*]*]*]*]

        [*[*[*[*[foo]*]*]*]*]: bar
        [*[*[*[foo]*]*]*]: bar
        [*[*[foo]*]*]: bar
        [*[foo]*]: bar
        [foo]: bar
        """
    g = s |> grouper
    filter!(!isempty, g)
    @test g[1] // "[[[[[[[foo]]]]]]]"
    @test g[2] // "[[[[[[[foo]]]]]]]: bar"
    @test g[3] // "[[[[[[foo]]]]]]: bar"
    @test g[4] // "[[[[[foo]]]]]: bar"

    @test g[5] // "[[[[foo]]]]: bar"
    @test g[6] // "[[[foo]]]: bar"
    @test g[7] // "[[foo]]: bar"
    @test g[8] // "[foo]: bar"
    @test g[9] // "[*[*[*[*[foo]*]*]*]*]"

    @test g[10] // "[*[*[*[*[foo]*]*]*]*]: bar"
    @test g[11] // "[*[*[*[foo]*]*]*]: bar"
    @test g[12] // "[*[*[foo]*]*]: bar"
    @test g[13] // "[*[foo]*]: bar"
    @test g[14] // "[foo]: bar"
end
