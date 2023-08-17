"""
    EOS

Mark the end of the string to parse (helps with corner cases where a token
ends a document without being followed by a space).
"""
const EOS = '\0'

"""
    SPACE_CHARS

List of characters that correspond to a `\\s` regex + EOS.

Ref: https://github.com/JuliaLang/julia/blob/master/base/strings/unicode.jl.
"""
const SPACE_CHAR = [' ', '\r', '\n', '\t', '\f', '\v', EOS]

"""
    NUM_CHAR

Convenience list of characters corresponding to digits.
"""
const NUM_CHAR = ['0':'9'...]

"""
    ALPHA_LATIN

Convenience list of characters corresponding to letters a-zA-Z.
"""
const ALPHA_LATIN = ['a':'z'..., 'A':'Z'...]

"""
    ALPHANUM_LATIN

Convenience list of characters corresponding to a-zA-Z0-9.
"""
const ALPHANUM_LATIN = vcat(ALPHA_LATIN, NUM_CHAR)

"""
    ALPHA_ALL

All 10_000 first characters.
"""
const ALPHA_ALL = [Char(i) for i in 1:10_000 if isletter(Char(i))]

"""
    ALPHANUM_ALL

ALPHA_ALL and digits.
"""
const ALPHANUM_ALL = vcat(ALPHA_ALL, NUM_CHAR)


"""
    Chomp

Structure to encapsulate rules around a token such as whether it's fine at the
end of a string, what are allowed following characters and, in the greedy
case, what characters are allowed.
"""
struct Chomp
    # fixed style
    refstring::String
    ok_at_eos::Bool
    is_followed::Bool
    next_chars::Vector{Char}
    # greedy style
    head_chars::Vector{Vector{Char}}
    tail_chars::Vector{Char}
end
function Chomp(;
            refstring::String="",
            ok_at_eos::Bool=true,
            is_followed::Bool=true,
            next_chars::Vector{Char}=Char[],
            head_chars::Vector{Vector{Char}}=Vector{Vector{Char}}(),
            tail_chars::Vector{Char}=Char[])
    Chomp(
        refstring, ok_at_eos, is_followed,
        next_chars, head_chars, tail_chars)
end

"""
    TokenFinder

Structure to find a token keeping track of how many characters should be seen,
some rules with respect to positioning or following chars (see Chomp) and
possibly a validator that checks whether a candidate respects a rule.
"""
struct TokenFinder
    steps::Int
    chomp::Chomp
    check::Regex
end
TokenFinder(s::Int, c::Chomp) = TokenFinder(s, c, r"")

"""
    fixed_lookahead(tokenfinder, candidate, at_eos)

Applies a fixed lookahead step corresponding to a token finder.
This is used as a helper function in `find_tokens`.
"""
function fixed_lookahead(tf::TokenFinder, candidate::SS, at_eos::Bool)
    c = tf.chomp
    matches = false
    if at_eos
        matches  = (candidate == c.refstring)
        matches &= c.ok_at_eos
    elseif isempty(c.next_chars)
        matches  = candidate == c.refstring
    else
        matches  = chop(candidate) == c.refstring
        matches &= !xor(c.is_followed, candidate[end] ∈ c.next_chars)
    end
    offset = Int(!isempty(c.next_chars) & !at_eos)
    return matches, offset
end

"""
    greedy_lookahead(tokenfinder, nchars, probe_char)

Applies a greedy lookahead step corresponding to a token finder.
This is used as a helper function in `find_tokens`.
"""
function greedy_lookahead(tf::TokenFinder, nchars::Int, probe_char::Char)
    c = tf.chomp
    (nchars > length(c.head_chars)) && return (probe_char in c.tail_chars)
    return (probe_char in c.head_chars[nchars])
end

"""
    check(tokenfinder, ss)

Check whether a substring verifies the regex of a token finder.
"""
function check(tf::TokenFinder, ss::SS)
    return match(tf.check, ss) !== nothing
end


"""
    forward_match(refstring, next_chars, is_followed)

Return a TokenFinder corresponding to a forward lookup checking if a sequence
of characters matches a `refstring` and is followed (or not followed if
`is_followed==false`) by a char out of a list of chars (`next_chars`).
"""
function forward_match(
            refstring::String,
            next_chars::Vector{Char}=Char[],
            is_followed::Bool=true
            )::TokenFinder
    # steps keeps track of the number of character to consume
    steps = lastindex(refstring)
    steps = ifelse(isempty(next_chars), prevind(refstring, steps), steps)

    # check whether it would be allowed to be at the end of the string
    ok_at_eos::Bool = isempty(next_chars) || !is_followed || EOS ∈ next_chars

    # form the validator and return the tokenfinder
    chomp = Chomp(; refstring, ok_at_eos, is_followed, next_chars)
    return TokenFinder(steps, chomp)
end

"""
    greedy_match(head_chars, tail_chars, check)

Lazily accept the next char and stop as soon as it fails to verify `λ(c)`.
"""
function greedy_match(;
            head_chars::Vector{Vector{Char}}=Vector{Vector{Char}}(),
            tail_chars::Vector{Char}=Char[],
            check::Regex=r"")
    TokenFinder(-1, Chomp(; head_chars, tail_chars), check)
end

regex_escaper(s) = escape_string(string(s),
    [
        '!', '?', '|',
        '(', ')', '[', ']', '{', '}',
        '-', '+', '.', '*',
        '$', '^'
    ]
)

function make_simple_templates_rx(simple_templates)
    return Regex(
        join(
            (
                regex_escaper(k)
                for k in keys(simple_templates)
            ),
            '|'
        )
    )
end

function make_templates_rx(templates)
    return Regex(
        '[' * prod(regex_escaper(k) for k in keys(templates)) * ']'
    )
end
