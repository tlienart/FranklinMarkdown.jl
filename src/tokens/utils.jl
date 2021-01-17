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
function forward_match(
            refstring::String,
            next_char::NTuple{K, Char} where K = (),
            is_followed=true
            )::TokenFinder

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
greedy_match(λ::Function, validator=nothing) = (-1, false, λ, validator)

"""
$(SIGNATURES)

Validator function wrapping a regex match.
"""
validator(rx::Regex) = s -> (match(rx, s) !== nothing)

"""
$(SIGNATURES)

Check whether `c` is a letter or is in a vector of characters `oc`.
"""
is_letter_or(c::Char, oc::NTuple{K, Char}=()) where K = isletter(c) || (c ∈ oc)

is_alphanum_or(c::Char, oc::NTuple{K, Char}=()) where K = is_letter_or(c, (oc..., NUM_CHAR...))
