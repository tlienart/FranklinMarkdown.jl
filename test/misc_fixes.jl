# Dec12'22 | release line return deactivated in block find so that
# other things can start immediately after e.g. a heading
md = """
    # abc
    * i1
    * i2
    """
g = FP.md_partition(md)
@test g[1].name == :H1
@test g[1].ss == "# abc\n"
@test FP.content(g[1]) == " abc"
@test g[2].name == :LIST
@test g[2].ss == "\n* i1\n* i2"
@test g[3].name == :P_BREAK
md = """
    @def v = 5
    * i1
    * i2
    """
g = FP.md_partition(md)
@test g[2].ss == "\n* i1\n* i2"
# Dec9'22 | remove_inner! when last block has from=to
md = """
    * abc
    * def
    ghi [aaa](bbb).
    """
g = FP.md_partition(md) |> FP.md_grouper
@test length(g) == 1
@test g[1].ss // md
# ----------------------------------------------------------------------------
# Oct14'22 | md block finishing at EOS #9
md = """+++\na = 5\n+++"""
g = FP.md_partition(md) |> FP.md_grouper
@test FP.content(g[1].blocks[1]) // "a = 5"
# ----------------------------------------------------------------------------
# Nov11 | content of blockquotes with empty line
md = """
    > ABC
    >
    > DEF
    >
    > GHI
    """
g = FP.md_partition(md) |> FP.md_grouper
@test FP.content(g[1].blocks[1]) // "ABC\n\nDEF\n\nGHI"
md = """
    > ABC
    > > DEF
    > >
    > >  GHI
    >
    > JKL
    """
g = FP.md_partition(md) |> FP.md_grouper
md2 = FP.content(g[1].blocks[1])
@test md2 // "ABC\n> DEF\n>\n>  GHI\n\nJKL"
g2 = FP.md_partition(md2) |> FP.md_grouper
@test g2[1] // "ABC"
@test FP.content(g2[2].blocks[1]) // "DEF\n\nGHI"
@test g2[3] // "JKL"

# ----------------------------------------------------------------------------
# Nov10 | bracketed link
md = """
    ([a](b))
    """
g = FP.md_partition(md) |> FP.md_grouper
@test g[1] // md
@test g[1].blocks[1] // "("
@test g[1].blocks[2] // "[a](b)"
@test g[1].blocks[3] // ")"
# ----------------------------------------------------------------------------
# Sep24 | more issues with lists and sub
md = """
    1. A
    1. B
    """
g = FP.md_partition(md) |> FP.md_grouper
@test g[1].role == :LIST
@test g[1] // md
md = """
    * A **B** `C`
    * D _E_
    """
mdss = FP.subs(md, 3, 13)
p = FP.md_partition(mdss) |> FP.md_grouper
@test p[1].ss // "A **B** `C`"
# ----------------------------------------------------------------------------
# Sep21 | Empty first block (P_BREAK)
md = """

    * A
    """
mdss = FP.subs(md, 4, 5)
p = FP.md_partition(mdss)
@test p[1].name == :TEXT
@test p[1] // "A"
