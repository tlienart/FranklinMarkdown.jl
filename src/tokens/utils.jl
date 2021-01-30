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
const SPACE_CHAR = [' ', '\n', '\t', '\v', '\f', '\r', '\u85', '\ua0', EOS]

"""
NUM_CHAR

Convenience list of characters corresponding to digits.
"""
const NUM_CHAR = ['0':'9'...]

const ALPHA_LATIN = ['a':'z'..., 'A':'Z'...]

const ALPHANUM_LATIN = vcat(ALPHA_LATIN, NUM_CHAR)

const ALPHA_ALL = [Char(i) for i in 1:10_000 if isletter(Char(i))]
const ALPHANUM_ALL = vcat(ALPHA_ALL, NUM_CHAR)



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
            refstring::String="", ok_at_eos::Bool=true, is_followed::Bool=true, next_chars::Vector{Char}=Char[],
            head_chars::Vector{Vector{Char}}=Vector{Vector{Char}}(),
            tail_chars::Vector{Char}=Char[])
    Chomp(
        refstring, ok_at_eos, is_followed, next_chars,
        head_chars, tail_chars)
end

struct TokenFinder
    steps::Int
    chomp::Chomp
    check::Regex
end

TokenFinder(s::Int, c::Chomp) = TokenFinder(s, c, r"")


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

function greedy_lookahead(tf::TokenFinder, nchars::Int, probe_char::Char)
    c = tf.chomp
    (nchars > length(c.head_chars)) && return (probe_char in c.tail_chars)
    return (probe_char in c.head_chars[nchars])
end

function check(tf::TokenFinder, ss::SS)
    return match(tf.check, ss) !== nothing
end


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
@inline function forward_match(
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
$(SIGNATURES)

Lazily accept the next character and stop as soon as it fails to verify `λ(c)`.
"""
@inline function greedy_match(;
            head_chars::Vector{Vector{Char}}=Vector{Vector{Char}}(),
            tail_chars::Vector{Char}=Char[],
            check::Regex=r"")
    TokenFinder(-1, Chomp(; head_chars, tail_chars), check)
end

# """
# $(SIGNATURES)
#
# Validator function wrapping a regex match.
# """
# validator(rx::Regex) = (s::SS -> (match(rx, s) !== nothing)::Bool)
#
# """
# $(SIGNATURES)
#
# Check whether `c` is a letter or is in a vector of characters `oc`.
# """
# is_letter_or(c::Char, oc::NTuple{K, Char}=()) where K =
#     ifelse(isletter(c), true, c ∈ oc)::Bool
#
# is_alphanum_or(c::Char, oc::NTuple{K, Char}=()) where K =
#     is_letter_or(c, (oc..., NUM_CHAR...))
