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
