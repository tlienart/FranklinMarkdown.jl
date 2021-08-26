"""
$(SIGNATURES)

Given a list of tokens and a dictionary of block templates, find all blocks
matching templates. The blocks are sorted by order of appearance and inner
blocks are weeded out.
"""
function find_blocks(
            tokens::SubVector{Token},
            templates::LittleDict{Symbol, BlockTemplate}
            )::Vector{Block}

    blocks = Block[]
    n_tokens = length(tokens)
    iszero(n_tokens) && return blocks
    is_active = ones(Bool, n_tokens)

    template_keys = keys(templates)
    @inbounds for i in eachindex(tokens)
        is_active[i] || continue
        opening = tokens[i].name

        if opening == :LINE_RETURN
            process_line_return!(blocks, tokens, i)
            continue
        elseif opening ∉ template_keys
            continue
        end

        template = templates[opening]
        closing  = template.closing
        nesting  = template.nesting

        if closing === NO_CLOSING
            push!(blocks, TokenBlock(tokens[i]))
            continue
        end

        # Find the closing token
        closing_index = -1
        open_depth = 1
        for j in i+1:n_tokens
            candidate = tokens[j].name
            if nesting && (candidate == opening)
                open_depth += 1
            elseif (candidate in closing)
                open_depth -= 1
            end
            if open_depth == 0
                closing_index = j
                break
            end
        end

        if (closing_index == -1)
            # allow those to not be closed properly
            if opening ∈ (:EM_OPEN, :EM_CLOSE,
                          :STRONG_OPEN, :STRONG_CLOSE,
                          :EM_STRONG_OPEN, :EM_STRONG_CLOSE)
                continue
            end
            parser_exception(:BlockNotClosed, """
                An opening token '$(opening)' was found but not closed.
                """)
        end

        tokens_in_span = @view tokens[i:closing_index]
        new_block = Block(template.name, tokens_in_span)
        push!(blocks, new_block)

        # deactivate all tokens in the span of the block
        is_active[i:closing_index] .= false
    end
    sort!(blocks, by=from)
    remove_inner!(blocks)

    # assemble double brace blocks; this has to be done here to avoid
    # ambiguity with stray {{ or }} in Lx context.
    form_dbb!(blocks)
    return blocks
end

@inline find_blocks(t::Vector{Token}, a...) = find_blocks(subv(t), a...)


"""
$(SIGNATURES)

Remove blocks which are part of larger blocks (these will get re-formed and
re-processed at an ulterior step).
"""
function remove_inner!(blocks::Vector{Block})
    isempty(blocks) && return
    n_blocks  = length(blocks)
    is_active = ones(Bool, n_blocks)
    for i in eachindex(blocks)
        is_active[i] || continue
        to_current = to(blocks[i])
        next_outer = n_blocks + 1
        for j = i+1:n_blocks
            if from(blocks[j]) >= to_current
                next_outer = j
                break
            end
        end
        is_active[i+1:next_outer-1] .= false
    end
    deleteat!(blocks, [i for i in eachindex(blocks) if !is_active[i]])
    return
end


"""
$(SIGNATURES)

Find LXB blocks that start with `{{` and and with `}}` and mark them as :DBB.
"""
function form_dbb!(b::Vector{Block})
    for i in eachindex(b)
        b[i].name === :LXB || continue
        ss = b[i].ss
        (startswith(ss, "{{") && endswith(ss, "}}")) || continue

        open  = Token(:DBB_OPEN, subs(ss, 1:2))
        li    = lastindex(ss)
        close = Token(:DBB_CLOSE, subs(ss, li-1:li))
        it    = @view b[i].inner_tokens[2:end-1]
        b[i]  = Block(:DBB, open => close, it)
    end
end


"""
$SIGNATURES

Process a line return followed by any number of white spaces and X. Depending
on `X`, it will lead to a different interpretation.

* a paragraph break (double line skip)
* a hrule (has --- or *** or ____ on the line)
* an item candidate (starts with * or + or ...)
* a table row candidate (startswith |)
* a blockquote (startswith >).

We disambiguate the different cases based on the two characters after the
whitespaces of the line return (the line return token captures `\n[ \t]*`).
"""
function process_line_return!(b::Vector{Block}, tv::SubVector{Token}, i::Int)::Nothing
    t = tv[i]
    c = next_chars(t, 2)

    if isempty(c) || c[1] ∈ ('\n', EOS)
        # P_BREAK; if there's not two chars beyond `c` will be empty
        # otherwise if there's `\n` or `EOS` then it's a line skip
        push!(b, Block(:P_BREAK, t.ss))

    # ------------------------------------------------------------------------
    # Hrules
    # NOTE the line MUST start with a triple followed only by
    # the same character, whitespaces and the eventual line return.
    elseif c[1] == c[2] == '-'
        _hrule!(b, t, HR1_PAT)

    elseif c[1] == c[2] == '_'
        _hrule!(b, t, HR2_PAT)

    elseif c[1] == c[2] == '*'
        _hrule!(b, t, HR3_PAT)

    # ------------------------------------------------------------------------
    # List items
    # NOTE for an item candidate, the candidate might not capture
    # the full item if the full item is on several lines, this has to
    # be post-processed when assembling ITEM_x_CAND into lists.
    elseif c[1] in ('+', '-', '*') && c[2] in (' ', '\t')
        cand = until_next_line_return(t)
        ps   = parent_string(cand)
        push!(b, Block(:ITEM_U_CAND, subs(ps, from(t), to(cand))))

    elseif c[1] ∈ NUM_CHAR && c[2] in vcat(NUM_CHAR, [' ', '\t', '.', ')'])
        cand = until_next_line_return(t)
        ps   = parent_string(cand)
        push!(b, Block(:ITEM_O_CAND, subs(ps, from(t), to(cand))))

    # ------------------------------------------------------------------------
    # Table Rows
    # NOTE we're stricter here than usual GFM, every row must start and end
    # with a pipe, every row must be on a single line.
    elseif c[1] == '|' && c[2] in (' ', '\t')
        # TABLE_ROW_CAND
        cand = until_next_line_return(t)
        ps   = parent_string(cand)
        push!(b, Block(:TABLE_ROW_CAND, subs(ps, from(t), to(cand))))

    # ------------------------------------------------------------------------
    # Blockquote
    elseif c[1] == '>'
        # Blockquote
        cand = until_next_line_return(t)
        ps   = parent_string(cand)
        push!(b, Block(:BLOCKQUOTE_LINE, subs(ps, from(t), to(cand))))
    end
    return
end

"""
$SIGNATURES

Helper function to match and process a hrule.
"""
function _hrule!(b, t, r)
    cand  = until_next_line_return(t)
    check = match(r, cand)
    ps    = parent_string(cand)
    isnothing(check) || push!(b, Block(:HRULE, subs(ps, from(t), to(cand))))
    return
end
