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
