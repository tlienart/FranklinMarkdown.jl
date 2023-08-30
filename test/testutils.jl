using Test, FranklinParser, Pkg
FP = FranklinParser
FPE = FP.FranklinParserException

using Test
import Base.//

isapproxstr(s1::AbstractString, s2::AbstractString) =
    isequal(map(s->replace(s, r"\s|\n"=>""), String.((s1, s2)))...)

# stricter than isapproxstr, just strips the outside.
(//)(s1::AbstractString, s2::AbstractString) = strip(s1) == strip(s2)
(//)(o::FP.AbstractSpan, s::AbstractString)  = o.ss // s

len1(o) = length(o) == 1
# --------------------------------------------------------------------------------------


md_blockifier = s -> FP.default_md_tokenizer(s) |> FP.default_md_blockifier

function check_tokens(tokens, idx, name)
    @test all([FP.name(t) for t in tokens[idx]] .== name)
    compl = [i for i in eachindex(tokens) if i ∉ idx]
    @test all([FP.name(t) for t in tokens[compl]] .!= name)
end

toks    = FP.default_md_tokenizer
slice   = FP.md_partition
text(b) = FP.prepare_md_text(b)
ct(b)   = FP.content(b)
ctf(b::FP.Group) = FP.content(first(b.blocks))
grouper = FP.md_grouper ∘ slice
isp(g)  = FP.name(g) == :PARAGRAPH
printel(bv) = foreach(e -> println(strip(e.ss)), bv)


pass1blocks = s -> begin
    tokens = FP.default_md_tokenizer(s)
    blocks = FP.Block[]
    is_active = ones(Bool, length(tokens))
    FP._find_blocks!(blocks, tokens, FP.MD_PASS1_TEMPLATES, is_active, process_line_return=true)
    return blocks
end

pass2blocks = s -> begin
    tokens = FP.default_md_tokenizer(s)
    blocks = FP.Block[]
    is_active = ones(Bool, length(tokens))
    FP._find_blocks!(blocks, tokens, FP.MD_PASS2_TEMPLATES, is_active, process_line_return=false)
    FP.form_links!(blocks)
    return blocks
end

function tnames(b::FP.Block)
    [FP.name(e) for e in b.tokens]
end
function tnames(v::FP.SubVector)
    [FP.name(e) for e in v]
end


signames(t) = FP.name.(filter(ti -> FP.name(ti) ∉ (:EOS,:SOS,:LINE_RETURN), t))
