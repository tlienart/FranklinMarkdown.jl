"""
$(SIGNATURES)

Go through a piece of text, either with an existing tokenization or an empty
one, tokenize if needed with the given tokenizer, blockify with the given
blockifier, and return a partition of the text into a vector of Blocks.
"""
function partition(
            s::SS,
            tokenizer::Function,
            blockifier::Function,
            tokens::SubVector{Token}=EMPTY_TOKEN_SVEC;
            postproc::Function=identity
            )::Vector{Block}

    parts = Block[]
    isempty(s) && return parts
    if isempty(tokens)
        tokens = tokenizer(s)
    end
    if length(tokens) == 1   # only the EOS token
        return [TextBlock(s)]
    end
    blocks = blockifier(tokens)
    isempty(blocks) && return [TextBlock(s, tokens)]

    parent = parent_string(s)

    # add Text at beginning if first block is not there
    first_block = blocks[1]
    last_block = blocks[end]
    if from(s) < from(first_block)
        tb = TextBlock(subs(parent, from(s), previous_index(first_block)), tokens)
        push!(parts, tb)
    end
    for i in 1:length(blocks)-1
        bi   = blocks[i]
        bip1 = blocks[i+1]
        push!(parts, blocks[i])
        inter = subs(parent, next_index(bi), previous_index(bip1))
        isempty(inter) || push!(parts, TextBlock(inter, tokens))
    end
    push!(parts, last_block)
    # add Text at the end if last block is not there
    if to(s) > to(last_block)
        push!(parts, TextBlock(subs(parent, next_index(last_block), to(s)), tokens))
    end
    return postproc(parts)
end
@inline partition(s::String, a...; kw...) = partition(subs(s), a...; kw...)
@inline partition(b::Block, a...; kw...)  = partition(content(b), a...; tokens=b.inner_tokens)


"""
$SIGNATURES

Arguments:
----------
    templates: a dictionary or matchers to find tokens.
    postprocess: a function to apply on tokens after they've been found e.g. to merge
        them or filter them etc.

Returns:
--------
    A function that takes a string and returns a vector of tokens.
"""
@inline function tokenizer_factory(;
            templates::LittleDict=MD_TOKENS,
            postprocess::Function=identity
            )::Function
    return s -> postprocess(find_tokens(s, templates))
end

default_md_tokenizer   = tokenizer_factory()
default_html_tokenizer = tokenizer_factory(templates=HTML_TOKENS)
default_math_tokenizer = tokenizer_factory(templates=MD_MATH_TOKENS)

"""
$SIGNATURES

Arguments:
----------
    templates: a dictionary or matchers to find blocks.
    postprocess: a function to apply on the blocks after they've been found.

Returns:
--------
    A function that takes tokens and returns a vector of blocks.
"""
@inline function blockifier_factory(; templates::LittleDict=MD_BLOCKS)::Function
    return t -> find_blocks(t, templates)
end

default_md_blockifier   = blockifier_factory()
default_html_blockifier = blockifier_factory(templates=HTML_BLOCKS)

@inline default_md_partition(e; kw...) =
    partition(e, default_md_tokenizer, default_md_blockifier;
              postproc=default_md_postproc!, kw...)

@inline default_html_partition(e; kw...) =
    partition(e, default_html_tokenizer, default_html_blockifier; kw...)

@inline default_math_partition(e; kw...) =
    partition(e, default_math_tokenizer, default_md_blockifier; kw...)


function default_md_postproc!(blocks::Vector{Block})
    form_blockquotes!(blocks)
    form_lists!(blocks)
    form_tables!(blocks)    
    remove_inner!(blocks)
    return blocks
end


"""
$SIGNATURES

Groups text and inline blocks; this helps in forming paragraphs.
"""
function md_grouper(
            blocks::Vector{Block},
            cases::LittleDict{Symbol, Vector{Symbol}}=LittleDict(
                :paragraph => INLINE_BLOCKS,
                :list => [
                    :ITEM_U_CAND,
                    :ITEM_O_CAND
                ],
                :table => [
                    :TABLE_ROW_CAND
                ]
            ),
            skip::Vector{Symbol}=[
                :P_BREAK
            ]
        )::Vector{Group}

    groups   = Group[]
    cur_role = :none
    cur_head = 1
    i        = 1

    while i <= length(blocks)
        bi = blocks[i]
        # does the block correspond to a role?
        br = :none
        for (role, names) in cases
            if bi.name in names
                br = role
                break
            end
        end

        switch = !(br == cur_role != :none)
        if switch
            if cur_head <= i-1
                push!(groups, Group(blocks[cur_head:i-1]; role=cur_role))
            end
            cur_role = br
            cur_head = i
        end
        if i == length(blocks)
            if switch
                push!(groups, Group(blocks[i]; role=br))
            else
                push!(groups[end].blocks, blocks[i])
            end
        end

        i += 1
    end


    # finalise removing blocks to skip (p-break).
    return filter!(g -> first(g.blocks).name ∉ skip, groups)
end
