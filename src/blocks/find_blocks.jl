"""
$(SIGNATURES)

Given a list of tokens and a dictionary of block templates, find all blocks matching
templates. The blocks are sorted by order of appearance and inner blocks are weeded out.
"""
function find_blocks(
            tokens::AbstractVector{Token},
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
        closing = template.closing
        nesting = template.nesting

        # Find the closing token
        closing_index = nothing
        open_depth = 1
        for j in i+1:n_tokens
            name = tokens[j].name
            if nesting && (name == opening)
                open_depth += 1
            elseif (name in closing)
                open_depth -= 1
            end
            if iszero(open_depth)
                closing_index = j
                break
            end
        end

        if isnothing(closing_index)
            parser_exception(BlockNotClosed, """
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
    return blocks
end


"""
$(SIGNATURES)

Remove blocks which are part of larger blocks.
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
