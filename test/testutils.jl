using Test
import Base.//

isapproxstr(s1::AbstractString, s2::AbstractString) =
    isequal(map(s->replace(s, r"\s|\n"=>""), String.((s1, s2)))...)

# stricter than isapproxstr, just strips the outside.
(//)(s1::AbstractString, s2::AbstractString) = strip(s1) == strip(s2)

# --------------------------------------------------------------------------------------

md_blockifier = s -> FP.default_md_tokenizer(s) |> FP.default_md_blockifier

function check_tokens(tokens, idx, name)
    @test all([t.name for t in tokens[idx]] .== name)
    compl = [i for i in eachindex(tokens) if i ∉ idx]
    @test all([t.name for t in tokens[compl]] .!= name)
end

toks    = FP.default_md_tokenizer
slice   = FP.md_partition
text(b) = FP.prepare_text(b)
ct(b)   = FP.content(b)
ctf(b::FP.Group) = FP.content(first(b.blocks))
grouper = FP.md_grouper ∘ slice
isp(g)  = g.role == :paragraph
