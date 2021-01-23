function process(s::FP.SS)::String
    io = IOBuffer()
    parts = FP.default_md_partition(s)
    for part in parts
        write(io, process(part))
    end
    return String(take!(io))
end
process(s::String) = process(FP.subs(s))

function process(b::FP.Block)::String
    if b.name == :TEXT
        return (b |> FP.content)::FP.SS |> FP.dedent |> cm_parser |> CM.html
    elseif b.name == :DIV
        classes = replace(b.open.ss[3:end], "," => " ")
        return "<div class=\"$(FP.get_classes(b))\">" *
               process(FP.dedent(FP.content(b))) *
               "</div>"
    else
        throw(TypeError("Expected either a text or div block"))
    end
end
