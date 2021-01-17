function get_classes(b::Block{:DIV, :DIV_OPEN, :DIV_CLOSE})::String
    return replace(b.open.ss[3:end], "," => " ")
end
