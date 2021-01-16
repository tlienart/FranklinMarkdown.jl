function process(s::FP.SS)::String
    io = IOBuffer()
    parts = FP.default_md_partition(s)
    for part in parts
        write(io, process(part))
    end
    return String(take!(io))
end
process(s::String) = process(FP.subs(s))

# explicit typing was just when playing with SnoopCompile.
process(t::FP.Text) = (t |> FP.content)::FP.SS |> FP.dedent |> cm_parser |> CM.html

function process(b::FP.Block{:DIV, :DIV_OPEN, :DIV_CLOSE})
    classes = replace(b.open.ss[3:end], "," => " ")
    return "<div class=\"$(FP.get_classes(b))\">" *
           process(FP.dedent(FP.content(b))) *
           "</div>"
end
