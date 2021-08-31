"""
    partition(s, tokenizer, blockifier, tokens; disable, postproc)

Go through a piece of text, either with an existing tokenization or an empty
one, tokenize if needed with the given tokenizer, blockify with the given
blockifier, and return a partition of the text into a vector of Blocks.

## Args

## KwArgs

    * disable:  list of token names to ignore (e.g. if want to allow math)
    * postproc: postprocessing to
"""
function partition(
            s::SS,
            tokenizer::Function,
            blockifier::Function,
            tokens::SubVector{Token}=EMPTY_TOKEN_SVEC;
            disable::Vector{Symbol}=Symbol[],
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

    # disable tokens if desired
    isempty(disable) || filter!(t -> t.name ∉ disable, tokens)

    # form Blocks
    blocks = blockifier(tokens)
    isempty(blocks) && return [TextBlock(s, tokens)]

    # Form a full partition with text blocks and blocks.
    parent = parent_string(s)
    first_block = blocks[1]
    last_block  = blocks[end]

    # add Text at beginning if first block is not there
    if from(s) < from(first_block)
        tb = TextBlock(subs(parent, from(s), prev_index(first_block)), tokens)
        push!(parts, tb)
    end

    # Go through blocks and add text with what's between them
    for i in 1:length(blocks)-1
        bi   = blocks[i]
        bip1 = blocks[i+1]
        push!(parts, blocks[i])
        inter = subs(parent, next_index(bi), prev_index(bip1))
        isempty(inter) || push!(parts, TextBlock(inter, tokens))
    end
    push!(parts, last_block)

    # add Text at the end if last block is not there
    if to(s) > to(last_block)
        push!(parts, TextBlock(subs(parent, next_index(last_block), to(s)), tokens))
    end

    # Postprocessing (e.g. forming blockquotes, lists etc)
    return postproc(parts)
end
@inline partition(s::String, a...; kw...) = partition(subs(s), a...; kw...)
@inline partition(b::Block, a...; kw...)  = partition(content(b), a...; tokens=b.inner_tokens)


"""
    tokenizer_factory(; templates, postproc)

Arguments:
----------
    templates: a dictionary or matchers to find tokens.
    postproc: a function to apply on tokens after they've been found e.g. to merge
        them or filter them etc.

Returns:
--------
    A function that takes a string and returns a vector of tokens.
"""
@inline function tokenizer_factory(;
            templates::LittleDict=MD_TOKENS
            )::Function
    return s -> find_tokens(s, templates)
end

default_md_tokenizer   = tokenizer_factory()
default_math_tokenizer = tokenizer_factory(templates=MD_MATH_TOKENS)
default_html_tokenizer = tokenizer_factory(templates=HTML_TOKENS)

default_md_blockifier   = t -> find_blocks(subv(t), is_md=true)
default_html_blockifier = t -> find_blocks(subv(t), is_md=false)

@inline md_partition(e; kw...) =
    partition(e, default_md_tokenizer, default_md_blockifier;
              postproc=default_md_postproc!, kw...)

@inline math_partition(e; kw...) =
    partition(e, default_math_tokenizer, default_md_blockifier; kw...)

@inline html_partition(e; kw...) =
    partition(e, default_html_tokenizer, default_html_blockifier; kw...)


function default_md_postproc!(blocks::Vector{Block})
    form_blockquotes!(blocks)
    form_lists!(blocks)
    form_tables!(blocks)
    form_refs!(blocks)
    remove_inner!(blocks)
    return blocks
end


"""
    md_grouper(blocks, cases, skip)

Groups text and inline blocks after partition, this helps in forming paragraphs.
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
                ],
            )
        )::Vector{Group}

    groups   = Group[]
    cur_role = :none
    cur_head = 0
    i        = 1

    while i <= length(blocks)
        bi = blocks[i]
        br = :none
        # does the block correspond to a role? [:paragraph, :table, :list]
        for (role, names) in cases
            if bi.name in names
                br = role
                break
            end
        end

        if br == :none
            _close_open_group!(groups, blocks, cur_head, i, cur_role)
            isempty(bi) || push!(groups, Group(bi; role=:none))
            cur_head = 0
            cur_role = :none

        elseif br != cur_role
            # role is different and not 'none'
            _close_open_group!(groups, blocks, cur_head, i, cur_role)
            if i == length(blocks) && !isempty(bi)
                push!(groups, Group(bi; role=br))
            end
            cur_head = i
            cur_role = br

        elseif i == length(blocks)
            _close_open_group!(groups, blocks, cur_head, i+1, cur_role)
        end

        i += 1
    end

    # finalise by removing empty blocks (e.g. P_BREAK)
    return filter!(g -> !isempty(strip(g.ss)), groups)
end


function _close_open_group!(groups, blocks, cur_head, i, cur_role)
    if cur_head != 0
        bs = filter!(!isempty, blocks[cur_head:i-1])
        isempty(bs) || push!(groups, Group(bs; role=cur_role))
    end
    return
end
