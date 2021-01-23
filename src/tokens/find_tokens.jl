"""
TokenFinder

Convenience type to define how tokens should be found. It is a pair mapping a tuple
describing how to recognise the token and a symbol with the name of the token.
"""
const TokenFinder = Tuple{
        Int,        # steps (number of characters for a look ahead)
        Bool,       # whether to check the following char or not
        Function,   # oracle indicating whether there's a match
        Union{Bool, Function}}  # whether it can be at EOS

"""
$(SIGNATURES)

Go through a text left to right, one (valid) char at the time and keep track of
sequences of chars that match specific tokens. The list of tokens found is returned.

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

    head_idx = firstindex(s)
    end_idx  = lastindex(s)

    @inbounds while head_idx <= end_idx
        head_char = s[head_idx]
        if haskey(templates, head_char)
            # Look at each possible finder sequentially
            for ((steps, offset, λ, ν), case) in templates[head_char]
                #=
                ↪ steps = length of the lookahead, 0 if incremental (greedy)
                ↪ offset = if we need to check one extra character
                (e.g. this is the case if we want to check that something
                is followed by a space)
                ↪ λ = the checker function
                    * for a fixed lookahead, it returns true if the segment
                    (head_idx → head_idx + steps) matches a condition
                    * for an incremental lookahead, it returns true if chars
                    given meet a condition, chars after head_idx are fed while
                    the condition holds.
                ↪ ν = the (optional) validator function in the case of a greedy
                    lookahead to check whether the sequence is valid; if boolean
                    indicates whether the pattern can  be at the end of the string.

                Either way, we push to the 'memory' the exact span (without the
                potential offset) of the token and a symbol indicating what it
                is then we move the head at the end of the token (note that
                it's pushed by 1 again after the if-else-end to start again).
                =#
                # exact match of a given fixed pattern
                if (steps >= 0)
                    tail_idx = nextind(s, head_idx, steps)
                    # is there space for the fixed pattern? otherwise skip
                    at_eos = false
                    if ν::Bool && (tail_idx == nextind(s, end_idx))
                        tail_idx = end_idx
                        at_eos = true
                    end
                    (tail_idx > end_idx) && continue

                    # if there is space, consider the substring and verify whether it matches
                    candidate = subs(s, head_idx, tail_idx)
                    if λ(candidate, at_eos)::Bool
                        # if offset --> looked at 1 extra char (lookahead)
                        back_one = offset & !at_eos
                        head_idx = prevind(s, tail_idx, back_one)
                        token = Token(case, chop(candidate, tail=back_one))
                        push!(tokens, token)
                        # once a token is identified, no need to check other cases (go to while)
                        break
                    end
                # rule-based match: greedy catch until fail
                else
                    nchars    = 1
                    tail_idx  = head_idx
                    probe_idx = nextind(s, head_idx)
                    probe_idx > end_idx && continue
                    probe_char::Char = s[probe_idx]

                    # while the condition holds, get next char
                    while λ(nchars, probe_char)::Bool
                        tail_idx   = probe_idx
                        probe_idx  = nextind(s, probe_idx)
                        (probe_idx > end_idx) && break
                        probe_char = s[probe_idx]
                        nchars    += 1
                    end

                    # if we took in at least a char, check then form the token
                    if tail_idx > head_idx
                        candidate = subs(s, head_idx, tail_idx)
                        # check if the validator is happy otherwise skip
                        (ν::Function)(candidate)::Bool || continue
                        # if it's happy push the token & move after the match
                        token = Token(case, candidate)
                        push!(tokens, token)
                        head_idx = tail_idx
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
    return tokens
end

find_tokens(s::String, templates) = find_tokens(subs(s), templates)
