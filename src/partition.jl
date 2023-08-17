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
            blockifier::Function;
            tokens::SubVector{Token}=EMPTY_TOKEN_SVEC,
            disable::Vector{Symbol}=Symbol[],
            postproc::Function=identity
            )::Vector{Block}

    reset_timer!(TIMER)

    parts = Block[]
    isempty(s) && return parts
    if isempty(tokens)
        @timeit_debug TIMER "tokenizer" begin
            tokens = tokenizer(s)
        end
    end

    # NOTE: we need to be explicit here as, in the recursive case, when
    # partitioning a block, there will not be a LR and EOS token. We'll just
    # get the blocks' inner tokens.
    if getfield.(tokens, :name) == [:LINE_RETURN, :EOS]
        return [Block(:TEXT, s)]
    end

    # disable tokens if desired
    isempty(disable) || filter!(t -> t.name ∉ disable, tokens)

    # form Blocks
    @timeit_debug TIMER "blockifier" begin
        blocks = blockifier(tokens)
    end
    # discard first block if it's a 0-length P_BREAK
    if !isempty(blocks) && iszero(to(blocks[1]))
        deleteat!(blocks, 1)
    end
    isempty(blocks) && return [Block(:TEXT, s)]

    # disable additional blocks if desired
    isempty(disable) || filter!(t -> t.name ∉ disable, blocks)

    @timeit_debug TIMER "partitioning" begin
        @timeit_debug TIMER "init" begin
    
            # Form a full partition with text blocks and blocks.
            parent = parent_string(s)
            first_block = blocks[1]
            last_block  = blocks[end]

            # add Text at beginning if first block is not there
            if from(s) < from(first_block)
                inter = subs(parent, from(s), prev_index(first_block))
                tb    = Block(:TEXT, inter)
                push!(parts, tb)
            end
   
        end
        @timeit_debug TIMER "loop" begin

            # Go through blocks and add text with what's between them
            for i in 1:length(blocks)-1
                bi   = blocks[i]
                bip1 = blocks[i+1]
                @timeit_debug TIMER "push1" push!(parts, blocks[i])
                @timeit_debug TIMER "inter" inter = subs(parent, next_index(bi), prev_index(bip1))
                @timeit_debug TIMER "push2" begin
                    @timeit_debug TIMER "isempty" flag = isempty(inter)
                    @timeit_debug TIMER "pushif2" (flag || push!(parts, Block(:TEXT, inter)))
                end
            end
            push!(parts, last_block)

        end
        @timeit_debug TIMER "end" begin

            # add Text at the end if last block is not there
            if to(s) > to(last_block)
                inter = subs(parent, next_index(last_block), to(s))
                push!(parts, Block(:TEXT, inter))
            end
        end
    end

    @timeit_debug TIMER "postprocessing" begin
        # Postprocessing (e.g. forming blockquotes, lists etc)
        pp = postproc(parts)
    end

    TimerOutputs.complement!(TIMER)

    return pp
end
partition(s::String, a...; kw...) = partition(subs(s), a...; kw...)
partition(b::Block, a...; kw...)  = partition(content(b), a...; tokens=b.inner_tokens)


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
function tokenizer_factory(; kw...)::Function
    return s -> find_tokens(s; kw...)
end

default_md_tokenizer   = tokenizer_factory(;
    simple_templates    = MD_TOKENS_SIMPLE,
    simple_templates_rx = MD_TOKENS_SIMPLE_RX,
    templates           = MD_TOKENS,
    templates_rx        = MD_TOKENS_RX
)
default_math_tokenizer = tokenizer_factory(;
    simple_templates    = MD_MATH_TOKENS_SIMPLE,
    simple_templates_rx = MD_MATH_TOKENS_SIMPLE_RX,
    templates           = MD_MATH_TOKENS,
    templates_rx        = MD_MATH_TOKENS_RX
)
default_html_tokenizer = tokenizer_factory(
    simple_templates    = HTML_TOKENS_SIMPLE,
    simple_templates_rx = HTML_TOKENS_SIMPLE_RX,
    templates           = HTML_TOKENS,
    templates_rx        = HTML_TOKENS_RX
)

default_md_blockifier   = t -> find_blocks(subv(t), is_md=true)
default_html_blockifier = t -> find_blocks(subv(t), is_md=false)

function md_partition(e; kw...)
    partition(e, default_md_tokenizer, default_md_blockifier;
              postproc=default_md_postproc!, kw...)
end

function math_partition(e; kw...)
    partition(e, default_math_tokenizer, default_md_blockifier; kw...)
end

function html_partition(e; kw...)
    partition(e, default_html_tokenizer, default_html_blockifier; kw...)
end


function default_md_postproc!(blocks::Vector{Block})
    form_blockquotes!(blocks)
    form_lists!(blocks)
    form_tables!(blocks)
    form_refs!(blocks)
    remove_inner!(blocks)
    return blocks
end


"""
    md_grouper(blocks)

Form begin-end spans keeping track of tokens and group text and inline blocks
after partition, this helps in forming paragraphs.
"""
function md_grouper(blocks::Vector{Block})::Vector{Group}

    groups   = Group[]
    cur_role = :NONE
    cur_head = 0
    i        = 1
    n_blocks = length(blocks)

    @inbounds while i <= n_blocks
        bi = blocks[i]
        br = ifelse(bi.name in INLINE_BLOCKS, :PARAGRAPH, bi.name)

        if br != :PARAGRAPH
            _close_open_paragraph!(groups, blocks, cur_head, i)
            push!(groups, Group(bi; role=br))
            cur_head = 0
            cur_role = br

        elseif i == length(blocks)
            cur_head = ifelse(cur_head == 0, i, cur_head)
            _close_open_paragraph!(groups, blocks, cur_head, i+1)

        else
            cur_head = ifelse(cur_head == 0, i, cur_head)
        end
        i += 1
    end

    # finalise by removing P_BREAK
    filter!(g -> g.role != :P_BREAK, groups)
    return groups
end


function _close_open_paragraph!(groups, blocks, cur_head, i)
    cur_head == 0 && return
    # blocks in the paragraph
    par_blocks = blocks[cur_head:i-1]
    strict_p   = any(
        b -> b.name ∉ INLINE_BLOCKS_CHECKP && !isempty(strip(content(b))),
        par_blocks
    )
    if strict_p
        push!(groups, Group(par_blocks; role=:PARAGRAPH))
    else
        push!(groups, Group(par_blocks; role=:PARAGRAPH_NOP))
    end
    return
end


"""
    split_args(s)

Take a string like 'foo "bar baz" 1' and return a string that is split along
whitespaces preserving quoted strings. So ["foo", "\"bar baz\"", "1"].
"""
function split_args(s::SS)::Vector{String}
    # 1. find single-quoted / triply-quoted strings
    # 2. split the string outside of the quoted strings
    # 3. return the list of strings
    #
    # Ex:   foo "bar baz" 1
    #
    # expected output is ["foo", "\"bar baz\"", "1"]
    #
    # (specific parsing/processing is then left to the user, the
    # contract is that the user can then join(output, " ") and
    # get something equivalent in terms of how Franklin parses it)
    #
    parts = partition(
        s,
        _s -> find_tokens(_s; templates=ARGS_TOKENS, templates_rx=ARGS_TOKENS_RX),
        _t -> (b = Block[]; _find_blocks!(b, subv(_t), ARGS_BLOCKS); b),
    )

    # form a dummy string with |__STR__| --> "foo |__STR__| 1"
    dummy   = IOBuffer()
    insert  = "|__STR__|"
    strings = String[]
    for p in parts
        if p.name == :TEXT
            write(dummy, content(p))
        else
            write(dummy, insert)
            push!(strings, content(p))
        end
    end
    # split the dummy string along white spaces
    splits = split(String(take!(dummy)))

    # reform the arguments in which |__STR__| appears.
    i = 1
    args = String[]
    for sp in splits
        if occursin(insert, sp)
            push!(args, replace(sp, insert => "\"" * strings[i] * "\""))
            i += 1
        else
            push!(args, sp)
        end
    end
    return args
end
split_args(s::String) = split_args(subs(s))
