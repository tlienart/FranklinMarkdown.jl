# ----------------------------------------------------------------------------
# Sep21 | Empty first block (P_BREAK)
md = """

    * A
    """
mdss = FP.subs(md, 4, 5)
p = FP.md_partition(mdss)
@test p[1].name == :TEXT
@test p[1] // "A"
