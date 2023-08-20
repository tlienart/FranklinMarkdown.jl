"""
    find_tokens(s; ...)

Go through a text left to right, one (valid) char at the time and keep track
of sequences of chars that match specific tokens. The list of tokens found is
returned.

## Errors

This should not throw any error, everything should be explicitly handled by
a code path.
"""
function find_tokens(
            s::SS;
            simple_templates    = Dict(),
            simple_templates_rx = r"",
            templates::Dict     = Dict(),
            templates_rx        = r"",
            )::Vector{Token}

    tokens = Token[]
    isempty(s) && return tokens

    #
    # Put a "start of string" token first, note that it may overlap with
    # another token which would be right at the start too (e.g. a line return)
    #
    push!(
        tokens,
        Token(:SOS, subs(parent_string(s), from(s)))
    )

    #
    # string probes
    #
    head_idx     = firstindex(s)::Int
    end_idx      = lastindex(s)::Int
    next_end_idx = nextind(s, end_idx)::Int

    #
    # This first block handles the trivial tokens that correspond to an exact,
    # non-ambiguous sequence of characters.
    #
    deactivated_char_index = Set{Int}()
    if !isempty(simple_templates)
        # usually the regex is provided as a const, but in the case it
        # isn't compute it; see also MD_TOKENS_SIMPLE etc.
        rx = simple_templates_rx
        if isempty(rx.pattern)
            rx = make_simple_templates_rx(simple_templates)
        end

        simple_matches = eachmatch(rx, s)
        for match in simple_matches
            # for simple matches we can do arithmetic in +- 1 because there
            # are no 'special' characters here (of length != 1)
            idx = match.offset
            # if the index is after the span of the previous token, take it
            # otherwise move on to the next match
            (idx >= head_idx) || continue
            # form and store the token
            start  = match.offset
            finish = start + length(match.match) - 1
            push!(
                tokens,
                Token(
                    simple_templates[match.match],
                    subs(s, start, finish)
                )
            )
            # keep track of "dead zone" of the string which are already
            # captured within a token and should not be considered when
            # looking for tokens in the next step
            union!(deactivated_char_index, start:finish)
            # move the head to keep track of the span of the token
            head_idx = finish + 1
        end
    end

    #
    # The purpose of this next block is to
    #   1. find all trigger characters (chars that would start a rule-token)
    #   2. filter the ones that actually do start a token
    #   3. keep a stack of these validated tokens
    #
    head_idx = firstindex(s)
    rx = templates_rx
    if isempty(rx.pattern)
        rx = make_templates_rx(templates)
    end

    matches  = collect(eachmatch(rx, s))
    if !isempty(deactivated_char_index)
        # ignore matches that start in one of the zones already found with the
        # previous step
        filter!(
            m -> m.offset ∉ deactivated_char_index,
            matches
        )
    end

    for match in matches
        idx = match.offset
        (idx >= head_idx) || continue

        head_idx  = idx
        head_char = s[head_idx]

        # we have a set of checker function to try, first one that works
        # leads to a token
        for (tf, case) in templates[head_char]
            # exact match of a given fixed pattern
            # --> we form a candidate substring with a fixed number of chars
            # and try to see if it matches a fixed rule. Possibly the substring
            # contains an extra character for rules where we must match only
            # when the next character is or isn't something.
            if (tf.steps >= 0)
                tail_idx = nextind(s, head_idx, tf.steps)
                at_eos   = (tail_idx == next_end_idx)
                tail_idx = min(tail_idx, end_idx)

                # consider the substring and verify whether it matches
                candidate       = subs(s, head_idx, tail_idx)
                matches, offset = fixed_lookahead(tf, candidate, at_eos)

                # if it matches, form the token and break the for loop:
                # no need to check other cases.
                # (note that we don't care that the +1 is a valid char
                # we just want to indicate to move after tail so the
                # next trigger index is not on the tail)
                if matches
                    head_idx = tail_idx + 1 - offset
                    push!(
                        tokens,
                        Token(case, chop(candidate, tail=offset))
                    )
                    break
                end
            # -----------------------------------------
            # rule-based match: greedy catch until fail
            # --> we gradually form a candidate substring of increasing length until
            # the next character doesn't meet the condition.
            else
                nchars     = 1
                tail_idx   = head_idx
                probe_idx  = nextind(s, head_idx)
                (probe_idx > end_idx) && continue
                probe_char = s[probe_idx]

                # while the condition holds, consume get next char
                while greedy_lookahead(tf, nchars, probe_char)
                    tail_idx   = probe_idx
                    probe_idx  = nextind(s, probe_idx)
                    (probe_idx > end_idx) && break
                    probe_char = s[probe_idx]
                    nchars    += 1
                end

                # if we took in at least a char, validate then form the token
                if tail_idx > head_idx
                    candidate = subs(s, head_idx, tail_idx)
                    # check if the backward validator is happy otherwise skip
                    check(tf, candidate) || continue
                    # if it's happy move head and push the token
                    # (see note in fixed match for +1)
                    head_idx = tail_idx
                    push!(
                        tokens,
                        Token(case, candidate)
                    )
                    break
                end
            end
        end
    end

    # finally push the end token on the stack, note that it can overlap another
    # token that would be at the end of the string, same as :SOS token.
    push!(
        tokens,
        Token(:EOS, subs(s, end_idx))
    )
    sort!(tokens, by=t->from(t))
    
    # discard header tokens that are not at the start of a line or
    # only preceded by whitespaces
    rm_header  = process_header_tokens!(tokens)
    # validate or drop emphasis tokens
    rm_emph    = process_emphasis_tokens!(tokens)
    # discard autolink_close tokens which are preceded by a space
    rm_autolnk = process_autolink_close_tokens!(tokens)

    remove = vcat(rm_header, rm_emph, rm_autolnk)
    unique!(remove)
    sort!(remove)
    deleteat!(tokens, remove)

    return tokens
end
find_tokens(s::String; kw...) = find_tokens(subs(s); kw...)


"""
    process_header_tokens!(tokens)

Discard header tokens that are not at the start of a line or only preceded by
whitespaces.
"""
function process_header_tokens!(
            tokens::Vector{Token}
        )::Vector{Int}

    remove = Int[]
    @inbounds for (i, t) in enumerate(tokens)
        if t.name in MD_HEADERS
            ss = until_previous_line_return(t)
            isempty(strip(ss)) || push!(remove, i)
        end
    end

    return remove
end


"""
    process_emphasis_tokens!(tokens)

Process emphasis token candidates and either take them or discard them if
they don't look correct.

* `sTs` with token `T` is `s` is a space
* `xTs` with token `T` is a valid CLOSE if `x` is a character and `s` a space
* `sTx` with token `T` is a valid OPEN if `x` is a character and `s` a space
* `xTy` with token `T` is a valid MIXED if `x`, `y` are characters
"""
function process_emphasis_tokens!(
            tokens::Vector{Token}
        )::Vector{Int}

    remove = Int[]
    @inbounds for (i, t) in enumerate(tokens)
        if t.name in (:EM, :STRONG, :EM_STRONG)
            prev_char = previous_chars(t)
            next_char = next_chars(t)
            # if the token is surrounded by spaces, discard it
            bad = (!isempty(prev_char) && first(prev_char) in SPACE_CHAR) &&
                  (!isempty(next_char) && first(next_char) in SPACE_CHAR)
            # sTs
            if bad
                push!(remove, i)
            # Tx or sTx
            elseif isempty(prev_char) || first(prev_char) in SPACE_CHAR
                n = Symbol(string(t.name) * "_OPEN")
                tokens[i] = Token(n, t.ss)
            # xT or xTs
            elseif isempty(next_char) || first(next_char) in SPACE_CHAR
                n = Symbol(string(t.name) * "_CLOSE")
                tokens[i] = Token(n, t.ss)
            else # xTy
                n = Symbol(string(t.name) * "_MX")
                tokens[i] = Token(n, t.ss)
            end
        end
    end

    return remove
end

"""
    process_autolink_close_tokens!(tokens)

Discard :AUTOLINK_CLOSE that are preceded by a space.
"""
function process_autolink_close_tokens!(
            tokens::Vector{Token}
        )::Vector{Int}

    remove = Int[]
    @inbounds for (i, t) in enumerate(tokens)
        if t.name == :AUTOLINK_CLOSE
            c = previous_chars(t)
            (isempty(c) || first(c) ∈ SPACE_CHAR) && push!(remove, i)
        end
    end

    return remove
end
