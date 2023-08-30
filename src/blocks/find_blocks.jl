"""
    find_blocks(...)

Given a vector of tokens, find all blocks matching templates.
The blocks are sorted by order of appearance and inner blocks are weeded out.
"""
function find_blocks(
            tokens::Vector{Token};
            # kwargs
            is_md::Bool=true
        )::Vector{Block}

    blocks = Block[]
    isempty(tokens) && return blocks
    is_active = ones(Bool, length(tokens))

    # ------------------------------------------------------------------------
    if is_md
        ##########
        # PASS 0 #
        ##########
        # raw blocks (??? ... ???)
        _find_blocks!(
            blocks, tokens,
            MD_PASS0_TEMPLATES,
            is_active
        )

        ##########
        # PASS 1 #
        ##########
        # basically all container blocks
        # comment, raw html, raw latex, def blocks, code blocks
        # math blocks, div blocks, autolink, cu_brackets, h* blocks
        # and lxbegin/end
        _find_blocks!(
            blocks, tokens,
            MD_PASS1_TEMPLATES,
            is_active,
            process_line_return=true
        )
        sort!(blocks, by=from)

        # At this point we have the cu_brackets and begin/end in blocks
        # Form the begin...end environments and deactivate all tokens within
        _find_env_blocks!(blocks, tokens, is_active)

        ##########
        # PASS 2 #
        ##########
        # brackets which may form a link: brackets and sq_brackets
        deact_tokens = _find_blocks!(
            blocks, tokens,
            MD_PASS2_TEMPLATES,
            is_active
        )
        form_links!(blocks)
        # here there may be brackets that are not part of links which
        # should have their content re-inspected
        @inbounds for b in filter(b_ -> name(b_) == :BRACKETS, blocks)
            fromb, tob = from(b), to(b)
            react_tokens = Token[]
            for i in deact_tokens
                toki = tokens[i]
                fi   = from(toki)
                ti   = to(toki)
                # is the token in the scope ?
                fromb < fi && ti < tob && push!(react_tokens, toki)
            end
            # recurse
            append!(blocks, find_blocks(react_tokens, is_md=true))
        end
        # discard leftover bracket blocks
        filter!(b -> name(b) != :BRACKETS, blocks)

        ##########
        # PASS 3 #
        ##########
        # remaining stuff e.g. emphasis tokens, lxnew* etc
        _find_blocks!(
            blocks, tokens,
            MD_PASS3_TEMPLATES,
            is_active
        )

    # ------------------------------------------------------------------------
    else
        # for HTML we barely do anything, a single pass is plenty enough
        _find_blocks!(
            blocks, tokens,
            HTML_TEMPLATES,
            is_active
        )
    end

    # remove blocks inside larger blocks (recursion)
    sort!(blocks, by=from)
    remove_inner!(blocks)

    # forming of double braces is done here to avoid clash with lx curly braces
    is_md && form_dbb!(blocks)

    return blocks
end


"""
    _find_blocks!(...)

Helper function to resolve each of the passes looking at a different set of
templates.
"""
function _find_blocks!(
            blocks::Vector{Block},
            tokens::Vector{Token},
            templates::Dict{Symbol, BlockTemplate},
            is_active::Vector{Bool} = ones(Bool, length(tokens));
            # kwargs
            process_line_return::Bool=false
        )::Vector{Int}
    #
    # keep track of what was deactivated, this is useful for md parsing
    # when discarding BRACKET tokens and re-enabling the tokens inside them;
    # only the tokens deactivated by it should be re-enabled.
    # so for instance:
    #   (abc _@@d *g* @@_ ef) --> first pass will deactivate `*`
    #   --> we should only re-enable `_`.
    #
    deactivated_tokens = Int[]

    isempty(templates) && return deactivated_tokens

    template_keys = keys(templates)
    n_tokens      = length(tokens)

    @inbounds for i in eachindex(tokens)
        # skip inactive
        is_active[i] || continue

        opening = name(tokens[i])

        # do we potentially have a paragraph break or something that may
        # start a line-block (blockquote candidate etc)
        if process_line_return && opening ∈ (:LINE_RETURN, :SOS)
            process_line_return!(blocks, tokens, i, is_active)
            continue
        elseif opening ∉ template_keys
            continue
        end

        # template for the closing token
        template = templates[opening]
        closing  = template.closing
        nesting  = template.nesting

        # short path for e.g. html entities
        if closing === NO_CLOSING
            push!(blocks, TokenBlock(tokens, i))
            continue
        end

        # try to find the closing token keeping potential nesting in mind
        closing_index = -1
        open_depth    = 1
        for j in i+1:n_tokens
            # the tokens ahead might be inactive due to first pass
            is_active[j] || continue
            candidate = name(tokens[j])
            # has to happen before opener to avoid ambiguity in emphasis tokens
            if candidate in closing
                open_depth -= 1
            elseif candidate == opening && nesting
                open_depth += 1
            end
            if open_depth == 0
                closing_index = j
                break
            end
        end

        # if the block isn't closed, complain unless this is tolerated.
        if (closing_index == -1)
            opening ∈ CAN_BE_LEFT_OPEN || block_not_closed_exception(tokens[i])
            continue
        end

        # now we have a block that is properly closed, push it on the stack
        # and deactivate relevant tokens
        push!(blocks,
            Block(
                template.name,
                @view tokens[i:closing_index]
            )
        )

        # for blocks that end with a line return, do not deactivate
        # that line return which might e.g. lead to the start of an item
        # see process_line_returns
        last_token    = tokens[closing_index]
        to_deactivate = i:(closing_index - Int(name(last_token) == :LINE_RETURN))

        # deactivate all tokens in the span of the block
        is_active[to_deactivate] .= false
        append!(deactivated_tokens, collect(to_deactivate))
    end
    return deactivated_tokens
end


"""
    process_line_return!(blocks, tokens, i)

Process a line return followed by any number of white spaces and one or more
characters. Depending on these characters, it will lead to a different
interpretation and an update of the token.

if the next non-space character(s) is/are:

* another lret      --> interpret as paragraph break (double line skip)
* two -,* or _      --> a hrule that will need to be validated later
* one *, +, -, etc. --> an item candidate
* |                 --> table row candidate
* >                 --> a blockquote (startswith >).

We disambiguate the different cases based on the **two** characters after the
whitespaces of the line return (the line return token captures `\n[ \t]*`).
"""
function process_line_return!(
            blocks::Vector{Block},
            tokens::Vector{Token},
            i::Int,
            is_active::Vector{Bool}
        )::Nothing

    t = tokens[i]

    #
    # We base the analysis on the two chars immediately following the token
    # (ignoring whitespaces) with one special cases: if t is near EOS; in that
    # case there may not be two chars (`c` below will be empty in that
    # situation).
    #
    t_is_sos        = is_sos(t)
    t_is_sos_and_lr = false
    if t_is_sos
        if first(t.ss) == '\n'
            c = next_chars(t, 2)
            t_is_sos_and_lr = true
        else
            c = [first(t.ss), next_chars(t, 1)...]
        end
    else
        c = next_chars(t, 2)
    end

    #
    # If there isn't two chars beyond the token, `c` will be empty.
    # This is the case if we're at the end of the string so there's nothing
    # to do. Likewise, if the second character is EOS, then we don't care
    # and skip (and deactivate all tokens in range).
    #
    if (length(c) < 2) || c[2] == EOS
        is_active[i:end] .= false

    #
    # If the immediate next character is a line return, then we have a
    # double \n\n -> line skip; this also means that the immediate next
    # token is a LINE_RETURN which we can deactivate.
    #
    elseif c[1] == '\n'
        push!(blocks,
            Block(
                :P_BREAK,
                @view tokens[i:i+1]
            )
        )
        # we only mark the base line return as inactive as the next one may
        # trigger something else such as an item (e.g. \n\n* foo\n)
        is_active[i] = false
        t_is_sos && (is_active[i+1] = false)

    else
        # 
        # We're now in a situation where the span between the token and
        # the next LINE_RETURN (or EOS) will form the block.
        #
        #   - hrule (---, ***, ___)
        #   - item starter (+ ..., - ..., * ...)
        #   - table row ( | ... )
        #   - block quote 
        #
        # if this is validated, we mark all tokens between the first line
        # return (included) and the next one (not-included *) as inactive.
        # (*) see comment above with only marking token[i] is inactive.
        # 
        j = i+1+Int(t_is_sos_and_lr)
        while name(tokens[j]) ∉ (:LINE_RETURN, :EOS)
            j += 1
        end
        next_line_return = tokens[j]
        # in the standard case of a line return, take string until the char
        # that precedes it. However, in the case of EOS, need to take the
        # string until the end.
        eol = ifelse(
            is_eos(next_line_return),
            from(next_line_return),
            prev_index(next_line_return)
        )
        rge  = ifelse(t_is_sos, from(t):eol, next_index(t):eol)
        line = subs(parent_string(t), rge)

        bpush! = name -> begin
            push!(blocks, Block(
                name,
                line,
                @view tokens[i+1:j]
            ))
            is_active[i:j-1] .= false
        end

        # HRULE
        if c[1] == c[2] && c[1] ∈ ('-', '_', '*')
            check = match(HR_PAT, line)
            isnothing(check) || bpush!(:HRULE)

        # ITEM STARTER (UN-ORDERED)
        elseif (c[1] in ('+', '-', '*')) && (c[2] in (' ', '\t'))
            bpush!(:ITEM_U_CAND)

        # ITEM STARTER (ORDERED)
        elseif (c[1] ∈ NUM_CHAR) && (c[2] in vcat(NUM_CHAR, ['.', ')']))
            check = match(OL_ITEM_PAT, line)
            isnothing(check) || bpush!(:ITEM_O_CAND)
 
        # BLOCKQUOTE
        elseif c[1] == '>'
            bpush!(:BLOCKQUOTE_LINE)

        # TABLE ROW (must be last because requires a check in the if)
        elseif !isnothing(match(ROW_CAND_PAT, line))
            bpush!(:TABLE_ROW_CAND)

        end
    end
    return
end


"""
    form_links!(blocks)

Here we catch the following:

    * [A]     LINK_A   for <a href="ref(A)">html(A)</a>
    * [A][B]  LINK_AR  for <a href="ref(B)">html(A)</a>
    * [A](B)  LINK_AB  for <a href="escape(B)">html(A)</a>
    * ![A]    IMG_A    <img src="ref(A)" alt="esc(A)" />
    # ![A][B] IMG_AR   <img src="ref(B)" alt="esc(A)" />
    * ![A](B) IMG_AB   <img src="escape(B)" alt="esc(A)" />
    * [A]: B  REF      (--> aggregate B, will need to distinguish later)

where 'A' is necessarily non empty, 'B' may be empty.

Note: currently we DO NOT support links with titles such as the following out
of simplicity:

* [A]: B C
* [A](B C)

this allows to not have to check whether B is a link and C is text. If the
user wants links with titles, they should create a command for it. We also do
not support link destinations between <...>.

Note: in the case of a LINK_A, we check around if the previous non whitespace
character and the next non whitespace character don't happen to be } {. In
that specific case, the link is
"""
function form_links!(
            blocks::Vector{Block}
        )::Nothing
    
    isempty(blocks) && return
    nblocks = length(blocks)
    remove  = Int[]
    i       = 1
    nb      = blocks[i]
    ps      = parent_string(nb)

    # retrieve the range of tokens between the blocks
    tok_rge = (b, nb) -> begin
        tokens = b.tokens.parent
        return @view tokens[
            b.tokens.indices[1][1]:nb.tokens.indices[1][end]
        ]
    end

    while i < nblocks
        b  = nb
        nb = blocks[i+1]

        if name(b) == :SQ_BRACKETS
            pchar = previous_chars(b)
            nchar = next_chars(b)

            # NOTE: ![]: --> ![] takes precedence.
            # img: is it preceded by '!'?
            # ref: is it followed by ':'?
            # lnk: is the next char '('
            img = !isempty(pchar) && pchar[1] == '!'
            ref = false
            lab = false
            lar = false
            if !isempty(nchar)
                ref = !img && nchar[1] == ':'
                lab = nchar[1] == '(' && name(nb) == :BRACKETS
                lar = nchar[1] == '[' && name(nb) == :SQ_BRACKETS
            end
            lnk = lab | lar

            # ref ==> REF, stop         []:
            #
            # img  & !lnk => IMG_A      ![]
            # img  & lab  => IMG_AB     ![]()
            # img  & lar  => IMG_AR     ![][]
            # !img & !lnk => LINK_A     []
            # !img & lab  => LINK_AB    []()
            # !img & lar  => LINK_AR    [][]

            if ref
                #
                #   [abc]:
                #
                # check if the block is at the start of line, otherwise discard
                #
                ss = until_previous_line_return(b)
                if isempty(strip(ss))
                    blocks[i] = Block(
                        :REF,
                        subs(ps, from(b), next_index(b)),
                        b.tokens
                    )
                else
                    push!(remove, i)
                end

            else
                if img
                    if !lnk
                        # ![]
                        blocks[i] = Block(
                            :IMG_A,
                            subs(ps, prev_index(b), to(b)),
                            b.tokens
                        )
                    elseif lab
                        # ![]()
                        blocks[i] = Block(
                            :IMG_AB,
                            subs(ps, prev_index(b), to(nb)),
                            tok_rge(b, nb)
                        )
                        push!(remove, i+1)
                    else
                        # ![][]
                        blocks[i] = Block(
                            :IMG_AR,
                            subs(ps, prev_index(b), to(nb)),
                            tok_rge(b, nb)
                        )
                        push!(remove, i+1)
                    end
                else
                    if !lnk
                        # []
                        blocks[i] = Block(
                            :LINK_A,
                            subs(ps, from(b), to(b)),
                            b.tokens
                        )
                    elseif lab
                        # []()
                        blocks[i] = Block(
                            :LINK_AB,
                            subs(ps, from(b), to(nb)),
                            tok_rge(b, nb)
                        )
                        push!(remove, i+1)
                    else
                        # [][]
                        blocks[i] = Block(
                            :LINK_AR,
                            subs(ps, from(b), to(nb)),
                            tok_rge(b, nb)
                        )
                        push!(remove, i+1)
                    end
                end
            end
        end
        i += 1
    end

    # check if the last block is maybe a standalone `(!)[...](:)`.
    i = nblocks
    b = blocks[i]
    if i ∉ remove && name(b) == :SQ_BRACKETS
        pchar = previous_chars(b)
        nchar = next_chars(b)
        if isempty(pchar)
            img = false
        else
            img = pchar[1] == '!'
        end
        if isempty(nchar)
            ref = false
        else
            ref = !img && nchar[1] == ':'
        end

        if ref
            ss = until_previous_line_return(b)
            if isempty(strip(ss))
                blocks[i] = Block(
                    :REF,
                    subs(ps, from(b), next_index(b)),
                    b.tokens
                )
            else
                push!(remove, i)
            end
        elseif img
            blocks[i] = Block(
                :IMG_A,
                subs(ps, prev_index(b), to(b)),
                b.tokens
            )
        else
            blocks[i] = Block(
                :LINK_A,
                subs(ps, from(b), to(b)),
                b.tokens
            )
        end
    end
    deleteat!(blocks, remove)
    return
end


"""
    remove_inner!(blocks)

Remove blocks which are part of larger blocks (these will get re-formed and
re-processed at an ulterior step).
"""
function remove_inner!(
            blocks::Vector{Block}
        )::Nothing

    isempty(blocks) && return
    n_blocks  = length(blocks)
    is_active = ones(Bool, n_blocks)
    @inbounds for i in eachindex(blocks)
        is_active[i] || continue
        to_current = to(blocks[i])
        next_outer = n_blocks + 1
        for j in i+1:n_blocks
            bj = blocks[j]
            fj, tj = from(bj), to(bj)
            # there can be a one-character block exactly at the end
            # of the span, see misc_fixes dec9'22.
            if (fj > to_current) || (fj == to_current && tj > fj)
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
    form_dbb!(blocks)

Find CU_BRACKETS blocks that start with `{{` and and with `}}` and mark them as
:DBB.
"""
function form_dbb!(b::Vector{Block})
    @inbounds for i in eachindex(b)
        name(b[i]) === :CU_BRACKETS || continue
        ss = b[i].ss
        (startswith(ss, "{{") && endswith(ss, "}}")) || continue
        b[i] = Block(
            :DBB,
            b[i].tokens
        )
    end
end


"""
    \\begin{ 1 } 2 \\end{ 1 }

    \\begin --> LX_BEGIN
    { 1 }   --> CU_BRACKETS
    2       --> content + inner tokens
    \\end   --> LX_END
    { 1 }   --> CU_BRACKETS
"""
function _find_env_blocks!(
            blocks::Vector{Block},
            tokens::Vector{Token},
            is_active::Vector{Bool}
        )::Nothing

    isempty(blocks) && return

    envs     = Block[]
    discard  = Int[]
    i        = 1
    n_blocks = length(blocks)
    curb     = blocks[i]

    check_probe(p, ename) = (name(p) == :CU_BRACKETS) && (ename == content(p) |> strip)

    @inbounds while i < n_blocks
        nxtb = blocks[i+1]
        j    = i

        if name(curb) == :LX_BEGIN
            # Note that the next block here is **necessarily** a CU_BRACKETS
            # indeed, LX_BEGIN is detected only if it's followed by `{` which
            # at this point, must have been closed (otherwise an error would
            # have been formed at block creation time).
            env_name = content(nxtb) |> strip

            # look ahead trying to find the proper closing \end{...}
            open_depth    = 1
            closing_index = -1
            probe         = nxtb
            j            += 1

            while j < n_blocks && open_depth != 0
                cand  = name(probe)
                probe = blocks[j + 1]

                if cand == :LX_BEGIN && check_probe(probe, env_name)
                    open_depth += 1
                elseif cand == :LX_END && check_probe(probe, env_name)
                    open_depth -= 1
                end

                j += 1
            end
            open_depth   != 0 && env_not_closed_exception(curb, env_name)
            closing_index = j

            # tokens in span (there is always at least LX_BEGIN and END)
            opening_token_idx = parentindices(curb.tokens)[1][1]
            closing_token_idx = parentindices(blocks[closing_index].tokens)[1][end]

            # deactivate them all
            is_active[opening_token_idx:closing_token_idx] .= false

            # mark all blocks in the range as to be discarded
            append!(discard, i:closing_index)

            # keep track of the block and its tokens
            b = Block(
                :ENV,
                @view tokens[opening_token_idx:closing_token_idx]
            )
            push!(envs, b)
        end

        curb = nxtb
        i    = j + 1
    end
    # discard all blocks within the env and append the env block
    deleteat!(blocks, discard)
    append!(blocks, envs)
    return
end
