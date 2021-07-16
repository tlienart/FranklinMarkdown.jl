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
        opening in template_keys || continue

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

        if closing_index == -1
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
    n_blocks = length(blocks)
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
