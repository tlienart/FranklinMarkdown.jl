#=
NOTE: a greedy match takes

- head_chars::Vector{Vector{Char}}
- tail_chars::Vector{Char}
- check::Regex

The head_chars indicate the accepted chars in order after the first triggering
char (so the first vector is for the first character after trigger, second
for second etc), as soon as we're beyond the range of head_chars, we check
whether the characters are in `tail_chars`

Finally the check regex allows to discard expressions that match the head
and char but might not overall meet the required regex. This is only
required for things where head/tail are insufficient.
The regex includes the trigger character.
=#

"""
    F_LINE_RETURN

Finder for a line return (`\n`) followed by any number of whitespaces or tabs.
These will subsequently be checked to see if they are followed by something
that constitutes a list item or not.
"""
const F_LINE_RETURN = greedy_match(
    tail_chars=[' ', '\t']
)


"""
    F_DIV_OPEN

Finder for `@@div` checking that `div` matches a simplified rule for allowed
CSS class names. The complete rule being `-?[_a-zA-Z]+[_a-zA-Z0-9-]*` which
we simplify here to `[a-zA-Z]+[_a-zA-Z0-9-]` and allow `,` for separation so
`@@d1,d2` is allowed and corresponds to a setting where we pass two classes
`class="d1 d2"`.
"""
const F_DIV_OPEN = greedy_match(
    head_chars=[['@'], ALPHA_LATIN],
    tail_chars=vcat(ALPHANUM_LATIN, ['-', '_', ','])
)

"""
    F_LX_COMMAND

Finder for latex command. First character is `[a-zA-Z]`.
We do allow numbers (there's no ambiguity because `\\com1` is not allowed to
mean `\\com{1}` unlike in LaTeX).
Underscores are allowed *inside* the command but not at the very start or very
end to avoid confusion respectively with the escaped `_` character or the
emphasis in markdown, `*` are not allowed anywhere (including at the end).
See also the check pattern.
"""
const F_LX_COMMAND = greedy_match(
    head_chars=[vcat(ALPHA_LATIN, ['_'])],
    tail_chars=vcat(ALPHANUM_LATIN, ['_']),
    check=LX_COMMAND_PAT
)

"""
    F_LANG_*

Finder for code blocks. I.e. something like a sequence of 3, 4 or 5 backticks
followed by a valid combination of letter defining a language.
"""
const F_LANG_3 = greedy_match(
    head_chars=[['`'], ['`']],
    tail_chars=vcat(ALPHANUM_LATIN, ['-']),
    check=CODE_LANG3_PAT
)
const F_LANG_4 = greedy_match(
    head_chars=[['`'], ['`'], ['`']],
    tail_chars=vcat(ALPHANUM_LATIN, ['-']),
    check=CODE_LANG4_PAT
)
const F_LANG_5 = greedy_match(
    head_chars=[['`'], ['`'], ['`'], ['`']],
    tail_chars=vcat(ALPHANUM_LATIN, ['-']),
    check=CODE_LANG5_PAT
)

"""
    F_HTML_ENTITY

Finder for html entities.
"""
const F_HTML_ENTITY = greedy_match(
    tail_chars=vcat(ALPHANUM_LATIN, ['#', ';']),
    check=HTML_ENTITY_PAT
)

"""
    F_EMOJI

Finder for emojis (those will have to be validated separately to check Julia
recognises them).
"""
const F_EMOJI = greedy_match(
    tail_chars=vcat(ALPHANUM_LATIN, [':', '+', '-', '_']),
    check=EMOJI_PAT
)

"""
    F_FOOTNOTE

Finder for footnotes.
"""
const F_FOOTNOTE = greedy_match(
    head_chars=[['^'], ALPHANUM_ALL],
    tail_chars=vcat(ALPHANUM_ALL, [']', ':', '_']),
    check=FOOTNOTE_PAT
)
