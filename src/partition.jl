"""
$(SIGNATURES)

Go through a piece of text, either with an existing tokenization or an empty one,
tokenize if needed with the given tokenizer, blockify with the given blockifier and
return a partition of the text into a vector of Text elements and Block elements.
"""
function partition(
            s::SS,
            t::SubVector{Token},
            tokenizer::Function,
            blockifier::Function,
            )::Vector{TextOrBlock}

    parts = TextOrBlock[]
    isempty(s) && return parts
    if isempty(t)
        t = tokenizer(s)
    end
    if length(t) == 1   # only the EOS token
        return [Text(s)]
    end
    blocks = blockifier(t)
    isempty(blocks) && return [Text(s, t)]

    # add Text at beginning if first block is not there
    first_block = blocks[1]
    last_block = blocks[end]
    if from(s) < from(first_block)
        push!(parts, Text(subs(s, from(s), previous_index(first_block)), t))
    end
    for i in 1:length(blocks)-1
        bi   = blocks[i]
        bip1 = blocks[i+1]
        push!(parts, blocks[i])
        inter = subs(s, next_index(bi), previous_index(bip1))
        isempty(inter) || push!(parts, Text(inter, t))
    end
    push!(parts, last_block)
    # add Text at the end if last block is not there
    if to(s) > to(last_block)
        push!(parts, Text(subs(s, next_index(last_block), to(s)), t))
    end
    return parts
end
partition(s::String, a...) = partition(subs(s), a...)
partition(s::SS, v::Vector{Token}, a...) = partition(s, subv(v), a...)


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
            postprocess::Function=(t -> filter!(e -> !isa(e, Token{:SKIP}), t))
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


function default_md_partition(s, t=EMPTY_TOKEN_SVEC)
    return partition(s, t, default_md_tokenizer, default_md_blockifier)
end

function default_html_partition(s, t=EMPTY_TOKEN_SVEC)
    return partition(s, t, default_html_tokenizer, default_html_blockifier)
end
