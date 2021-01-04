# CM fix // disable parsing of indented blocks
struct SkipIndented end
block_rule(::SkipIndented) = CM.Rule((p, c) -> 0, 8, "")
cm_parser = CM.enable!(CM.disable!(CM.Parser(),
                        CM.IndentedCodeBlockRule()), SkipIndented())

# --------------------------------------------------------------------------------------

import Base.//

isapproxstr(s1::AbstractString, s2::AbstractString) =
    isequal(map(s->replace(s, r"\s|\n"=>""), String.((s1, s2)))...)

# stricter than isapproxstr, just strips the outside.
(//)(s1::String, s2::String) = strip(s1) == strip(s2)

# --------------------------------------------------------------------------------------

md_blockifier = s -> FP.default_md_tokenizer(s) |> FP.default_md_blockifier

function check_tokens(tokens, idx, name)
    @test all(t -> t.name == name, tokens[idx])
    @test all(t -> t.name != name, tokens[[i for i in eachindex(tokens) if i ∉ idx]])
end
