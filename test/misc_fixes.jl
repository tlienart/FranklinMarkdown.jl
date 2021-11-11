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
@test FP.content(g[1].blocks[1]) // "\n ABC\n\n DEF\n\n GHI"

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
