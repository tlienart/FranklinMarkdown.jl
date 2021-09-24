# ----------------------------------------------------------------------------
# Sep24 | more of the previous
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
