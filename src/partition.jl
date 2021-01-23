"""
$(SIGNATURES)

Go through a piece of text, either with an existing tokenization or an empty one,
tokenize if needed with the given tokenizer, blockify with the given blockifier and
return a partition of the text into a vector of Blocks.
"""
function partition(
            s::SS,
            tokenizer::Function,
            blockifier::Function;
            tokens::SubVector{Token}=EMPTY_TOKEN_SVEC,
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
    return parts
end
partition(s::String, a...; kw...) = partition(subs(s), a...; kw...)
partition(b::Block, a...; kw...)  = partition(content(b), a...; tokens=b.inner_tokens)


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
function tokenizer_factory(;
            templates::LittleDict=MD_TOKENS,
            postprocess::Function=(ts::Vector{Token} -> filter!(t -> t.name != :SKIP, ts))
            )::Function
    return s -> postprocess(find_tokens(s, templates))
end

default_md_tokenizer   = tokenizer_factory()
default_html_tokenizer = tokenizer_factory(templates=HTML_TOKENS)


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
function blockifier_factory(;
            templates::LittleDict=MD_BLOCKS,
            postprocess::Function=identity
            )::Function
    return t -> postprocess(find_blocks(t, templates))
end

default_md_blockifier   = blockifier_factory()
default_html_blockifier = blockifier_factory(templates=HTML_BLOCKS)

default_md_partition(s_or_b; kw...) =
    partition(s_or_b, default_md_tokenizer, default_md_blockifier; kw...)
default_html_partition(s_or_b; kw...) =
    partition(s_or_b, default_html_tokenizer, default_html_blockifier; kw...)
