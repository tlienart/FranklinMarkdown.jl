"""
    get_classes(divblock)

Return the classe(s) of a div block. E.g. `@@c1,c2` will return `"c1 c2"` so
that it can be injected in a `<div class="..."`.
"""
function get_classes(b::Block{:DIV})::String
    open = b.tokens[1].ss
    return replace(open, 
        r"^\@\@" => "",
        "," => " "
    )
end

"""
    prepare_md_text(blocks)

For a text block, replace the remaining tokens for special characters.
"""
function prepare_md_text(
            b::Block;
            tohtml=true
        )::String

    c = b.ss
    isempty(strip(c)) && return ""

    relevant_inner_tokens = filter(
        t -> name(t) ∉ MD_IGNORE,
        content_tokens(b)
    )
    isempty(relevant_inner_tokens) && return String(c)

    parent = parent_string(c)
    io     = IOBuffer()
    head   = from(c)
    for t in relevant_inner_tokens
        write(io, subs(parent, head, prev_index(t)))
        write(io, insert(t; tohtml))
        head = next_index(t)
    end
    write(io, subs(parent, head, to(c)))
    return String(take!(io))
end

"""
    insert(token)

For tokens representing special characters, insert the relevant string.
"""
function insert(t::Token; tohtml=true)::String
    tname  = name(t)
    stname = String(tname)
    s = String(t.ss)  # safe default
    if tname != :CHAR_HTML_ENTITY
        if startswith(stname, "CHAR_") && tohtml # CHAR_*
            id = stname[6:end]
            s  = "&#$(id);"
        elseif tname == :CAND_EMOJI
            # check if it's a valid emoji
            s = get(emoji_symbols, "\\$(t.ss)", s)
        end
    end
    tohtml || (s = replace(s, "&" => "\\&"))
    return s
end

"""
    prev_token_idx(b)

Return the last token index before a block, 0 if there is no such token.

# Cases

There's always at least one token in the span of the block so just get the
index of that token and return the previous index (which might be zero)
"""
function prev_token_idx(b::Block)
    return parentindices(b.tokens)[1][1] - 1
end
