function get_classes(b::Block{:DIV, :DIV_OPEN, :DIV_CLOSE})::String
    return replace(b.open.ss[3:end], "," => " ")
end

function prepare(b::Block{:TEXT})::String
    c = content(b)
    isempty(b.inner_tokens) && return String(c)
    parent = parent_string(c)
    io = IOBuffer()
    head = from(c)
    for t in b.inner_tokens
        name(t) in MD_IGNORE && continue
        write(io, subs(parent, head, previous_index(t)))
        write(io, insert(t))
        head = next_index(t)
    end
    write(io, subs(parent, head, to(c)))
    return String(take!(io))
end

insert(t::Token{:LINEBREAK})       = "~~~<br>~~~"
insert(t::Token{:HORIZONTAL_RULE}) = "~~~<hr>~~~"

insert(t::Token{:CHAR_HTML_ENTITY}) = String(t.ss)

insert(t::Token{:CHAR_92})  = "&#92;"   # '\'
insert(t::Token{:CHAR_42})  = "&#42;"   # '*'
insert(t::Token{:CHAR_95})  = "&#95;"   # '_'
insert(t::Token{:CHAR_96})  = "&#96;"   # '`'
insert(t::Token{:CHAR_64})  = "&#64;"   # '@'
insert(t::Token{:CHAR_35})  = "&#35;"   # '#'
insert(t::Token{:CHAR_123}) = "&#123;"  # '{'
insert(t::Token{:CHAR_125}) = "&#125;"  # '}'
insert(t::Token{:CHAR_36})  = "&#36;"   # '$'
