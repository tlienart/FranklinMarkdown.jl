function name(b::B) where B <: Block
    return first(B.parameters)
end

function get_classes(b::Block{:DIV})
    return replace(b.open.ss[3:end], "," => " ")
end
