"""
$(SIGNATURES)

Go through a text left to right, one (valid) char at the time and keep track
of sequences of chars that match specific tokens. The list of tokens found is
returned.

**Arguments**

* `s`: the initial text
* `templates`: dictionary of possible tokens
"""
function find_tokens(
            s::SS,
            templates::LittleDict{Char, Vector{Pair{TokenFinder, Symbol}}}
            )::Vector{Token}

    tokens = Token[]
    isempty(s) && return tokens

    # start with a linereturn to allow proper treatment of blockquote lines
    # items etc that would be right at the start
    push!(tokens, Token(:LINE_RETURN, subs(s, 1:0)))

    head_idx = firstindex(s)
    end_idx  = lastindex(s)

    @inbounds while head_idx <= end_idx
        head_char = s[head_idx]
        if haskey(templates, head_char)
            # Look at each possible finder sequentially
            for (tf, case) in templates[head_char]
                # ------------------------------------
                # exact match of a given fixed pattern
                # --> we form a candidate substring with a fixed number of characters
                # and try to see if it matches a fixed rule. Possibly the substring
                # contains an extra character for rules where we must match only when
                # the next character is or isn't something.
                if (tf.steps >= 0)
                    tail_idx = nextind(s, head_idx, tf.steps)
                    at_eos   = false
                    if tail_idx == nextind(s, end_idx)
                        tail_idx = end_idx
                        at_eos = true
                    end
                    (tail_idx > end_idx) && continue

                    # if there is space, consider the substring and verify whether it matches
                    candidate       = subs(s, head_idx, tail_idx)
                    matches, offset = fixed_lookahead(tf, candidate, at_eos)

                    # if it matches, form the token and break the for loop: no need to check
                    # other cases.
                    if matches
                        head_idx = prevind(s, tail_idx, offset)
                        token    = Token(case, chop(candidate, tail=offset))
                        push!(tokens, token)
                        break
                    end
                # -----------------------------------------
                # rule-based match: greedy catch until fail
                # --> we gradually form a candidate substring of increasing length until
                # the next character doesn't meet the condition.
                else
                    nchars    = 1
                    tail_idx  = head_idx
                    probe_idx = nextind(s, head_idx)
                    probe_idx > end_idx && continue
                    probe_char::Char = s[probe_idx]

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
                        head_idx = tail_idx
                        token = Token(case, candidate)
                        push!(tokens, token)
                        break
                    end
                end
            end
        end
        head_idx = nextind(s, head_idx)
    end

    # finally push the end token on the stack observe that it can overlap a token
    # that would be at the end of the string.
    eos = Token(:EOS, subs(s, end_idx))
    push!(tokens, eos)

    # validate or drop emphasis tokens
    process_emphasis_tokens!(tokens)
    return tokens
end

@inline find_tokens(s::String, templates) = find_tokens(subs(s), templates)


function process_emphasis_tokens!(tokens::Vector{Token})
    isempty(tokens) && return
    remove = Int[]
    ps = parent_string(first(tokens))
    N  = lastindex(ps)
    for (i, t) in enumerate(tokens)

        if t.name == :EM_CAND
            _process_emph!(remove, tokens, i, ps,
                           :EM_OPEN, :EM_CLOSE)

        elseif t.name == :STRONG_CAND
            _process_emph!(remove, tokens, i, ps,
                           :STRONG_OPEN, :STRONG_CLOSE)

        elseif t.name == :EM_STRONG_CAND
            _process_emph!(remove, tokens, i, ps,
                           :EM_STRONG_OPEN, :EM_STRONG_CLOSE)
        end
    end
    deleteat!(tokens, remove)
    return
end

function _process_emph!(remove::Vector{Int}, tokens::Vector{Token}, i::Int,
                        ps::String, os::Symbol, cs::Symbol)
    # ' _\S' => opening
    # '\S_ ' => closing
    # other => discard
    t  = tokens[i]
    ps = parent_string(t)
    N  = lastindex(ps)
    c  = first(t.ss)
    kp = previous_index(t)
    kn = next_index(t)
    if (kp < 1 || ps[kp] ∈ ('\n', ' ', '\t')) && (
        kn <= N && ps[kn] ∉ ('\n', ' ', '\t', c))

        tokens[i] = Token(os, t.ss)

    elseif (kn > N || ps[kn] ∈ ('\n', ' ', '\t')) && (
            kp >= 1 && ps[kp] ∉ ('\n', ' ', '\t', c))

        tokens[i] = Token(cs, t.ss)

    else
        push!(remove, i)
    end
end
