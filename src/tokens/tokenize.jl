"""
EOS

Mark the end of the string to parse (helps with corner cases where a token ends a
document without being followed by a space).
"""
const EOS = '\0'

"""
SPACE_CHARS

List of characters that correspond to a `\\s` regex + EOS.

Ref: https://github.com/JuliaLang/julia/blob/master/base/strings/unicode.jl.
"""
const SPACE_CHAR = (' ', '\n', '\t', '\v', '\f', '\r', '\u85', '\ua0', EOS)

"""
NUM_CHAR

Convenience list of characters corresponding to digits.
"""
const NUM_CHAR = tuple('0':'9'...)

"""
TokenFinder

Convenience type to define how tokens should be found. It is a pair mapping a tuple
describing how to recognise the token and a symbol with the name of the token.
"""
const TokenFinder = Tuple{
        Int,        # steps
        Bool,       # whether to check the next char or not
        Function,   # oracle indicating whether there's a match
        Union{Bool,Nothing,Function}} # whether it can be at EOS

"""
$(SIGNATURES)

Return a tuple corresponding to a forward lookup checking if a sequence of characters
matches `refstring` and is followed (or not followed if `is_followed==false`) by a
character out of a list of characters (`follow`). The tuple returned has:

1. a number of steps indicating the number of characters to check,
2. whether there is an offset or not (if it is required to check a following character
or not),
3. a boolean function that can be applied on a sequence of character,
4. an indicator of whether the pattern can be found at the end of the string.
"""
function forward_match(refstring::String, next_char::NTuple{K,Char} where K = (),
                       is_followed=true)::TokenFinder
    steps      = lastindex(refstring)
    check_next = !isempty(next_char)
    steps      = ifelse(check_next, steps, prevind(refstring, steps))
    ok_at_eos  = !check_next || !is_followed || EOS ∈ next_char

    λ(s, at_eos) = begin
        if at_eos
            flag  = (s == refstring)
            flag &= ok_at_eos
        elseif !check_next
            flag  = (s == refstring)
        else
            flag  = (chop(s) == refstring)
            flag &= !xor(is_followed, s[end] ∈ next_char)
        end
        flag
    end
    return (steps, check_next, λ, ok_at_eos)
end

"""
$(SIGNATURES)

Lazily accept the next character and stop as soon as it fails to verify `λ(c)`.
"""
greedy_match(λ::Function, validator=nothing) = (0, false, λ, validator)

# -----------------------------------------------------------------------------

"""
$(SIGNATURES)

Validator function wrapping a regex match.
"""
validator(rx::Regex) = s -> !isnothing(match(rx, s))

"""
$(SIGNATURES)

Check whether `c` is a letter or is in a vector of characters `oc`.
"""
is_letter_or(c::Char, oc::NTuple{K,Char}=()) where K = isletter(c) || (c ∈ oc)

is_alphanum_or(c::Char, oc::NTuple{K, Char}=()) where K = is_letter_or(c, (oc..., NUM_CHAR...))

"""
$(SIGNATURES)

In combination with `greedy_match`, checks to see if we have something that looks like a
`@@div` describing the opening of a div block. Triggering char is a first `@`.
"""
function is_div_open(i::Int, c::Char)
    i == 1 && return c == '@'
    return is_alphanum_or(c, ('-','_', ','))
end

"""
$(SIGNATURES)

In combination with `greedy_match`, check to see if we have something that looks like a
valid latex-like command name. Triggering char is a first `\\`.
"""
function is_lx_command(i::Int, c::Char)
    i == 1 && return is_letter_or(c)
    is_letter_or(c, ('_', '*'))
end

val_lx_command = validator(LX_COMMAND_PAT)

"""
$(SIGNATURES)

In combination with `greedy_match`, checks to see if we have something that looks like
a sequence of 3, 4 or 5 backticks followed by a valid combination of letter defining a
language. Triggering char is a first backtick.
"""
function is_lang(j)
    λ(i::Int, c::Char) = begin
        i < j  && return c == '`'         # ` followed by `` forms the opening ```
        i == j && return is_letter_or(c)
        return is_alphanum_or(c, ('-',))  # eg ```objective-c
    end
    return λ
end

val_lang3 = validator(CODE_LANG3_PAT)
val_lang4 = validator(CODE_LANG4_PAT)
val_lang5 = validator(CODE_LANG5_PAT)

"""
$(SIGNATURES)

In combination with `greedy_match`, checks to see if we have something that looks like a
html entity. Note that there can be fake matches, so this will need to be validated
later on; if validated it will be treated as HTML; otherwise it will be shown as
markdown.
Triggerin char is a `&`.
"""
is_html_entity(::Int, c::Char) = is_alphanum_or(c, ('#',';'))

val_html_entity = validator(HTML_ENTITY_PAT)

"""
$(SIGNATURES)

Check if it looks like an emoji indicator `:...` note that it does not take the final
`:` this is checked and added in `validate_emoji!`.
"""
is_emoji(i::Int, c::Char) = is_alphanum_or(c, ('+','_','-'))

"""
$(SIGNATURES)

Check if it looks like `\\[\\^[\\p{L}0-9]+\\]:`.
"""
function is_footnote(i::Int, c::Char)
    i == 1 && return c == '^'
    i == 2 && return is_alphanum_or(c)
    i > 2  && return is_alphanum_or(c, (']', ':'))
end

"""
$SIGNATURES

Check if it looks like `---+`.
"""
is_hr1(::Int, c::Char) = (c == '-')

"""
$SIGNATURES

Check if it looks like `___+`.
"""
is_hr2(::Int, c::Char) = (c == '_')

"""
$SIGNATURES

Check if it looks like `***+`.
"""
is_hr3(::Int, c::Char) = (c == '*')

# -----------------------------------------------------------------------------

"""
$(SIGNATURES)

Go through a text left to right, one (valid) char at the time and keep track of
sequences of chars that match specific tokens. The list of tokens found is returned.

**Arguments**

* `s`:   the initial text
* `d1`: dictionaro of possible tokens (single character)
* `dn`: dictionary of possible tokens (multiple characters long)
"""
function tokenize(s::AS,
                  d1::LittleDict{Char,Symbol},
                  dn::LittleDict{Char,Vector{Pair{TokenFinder,Symbol}}}
                  )::Vector{Token}

    tokens = Token[]
    isempty(s) && return tokens

    head_idx = firstindex(s)
    end_idx  = lastindex(s)

    while head_idx <= end_idx
        head_char = s[head_idx]
        # is it a single-char token?
        if haskey(d1, head_char)
            push!(tokens, Token(d1[head_char], subs(s, head_idx)))

        elseif haskey(dn, head_char)
            # Look at each possible finder sequentially
            for ((steps, offset, λ, ν), case) ∈ dn[head_char]
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
                if steps > 0
                    tail_idx = nextind(s, head_idx, steps)
                    # is there space for the fixed pattern? otherwise skip
                    at_eos = false
                    if ν && (tail_idx == nextind(s, end_idx))
                        tail_idx = end_idx
                        at_eos = true
                    end
                    (tail_idx > end_idx) && continue

                    # if there is space, consider the substring and verify whether it matches
                    candidate = subs(s, head_idx, tail_idx)
                    if λ(candidate, at_eos)
                        # if offset --> looked at 1 extra char (lookahead)
                        back_one = offset && !at_eos
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
                    probe_char = s[probe_idx]

                    # while the condition holds, get next char
                    while λ(nchars, probe_char)
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
                        isnothing(ν) || ν(candidate) || continue
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
