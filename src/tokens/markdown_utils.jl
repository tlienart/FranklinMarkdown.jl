"""
F_DIV_OPEN

Finder for `@@div` checking that `div` matches a simplified rule for allowed CSS class
names. The complete rule being `-?[_a-zA-Z]+[_a-zA-Z0-9-]*` which we simplify here to
`[a-zA-Z]+[_a-zA-Z0-9-]` and allow `,` for separation so `@@d1,d2` is allowed and
corresponds to a setting where we pass two classes `class="d1 d2"`.
"""
const F_DIV_OPEN = greedy_match(
    head_chars=[['@'], ALPHA_LATIN],
    tail_chars=vcat(ALPHANUM_LATIN, ['-', '_', ','])
)

"""
F_LX_COMMAND

Finder for latex command. First character is `[a-zA-Z]`. '*' is only allowed once
and at the end. We do allow numbers (there's no ambiguity because `\\com1` is not
allowed to mean `\\com{1}` unlike in LaTeX).
"""
const F_LX_COMMAND = greedy_match(
    head_chars=[ALPHA_LATIN],
    tail_chars=vcat(ALPHANUM_LATIN, ['_', '*']),
    check=LX_COMMAND_PAT
)

"""
F_LANG_*

Finder for code blocks. I.e. something like a sequence of 3, 4 or 5 backticks followed
by a valid combination of letter defining a language.
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

Finder for emojis (those will have to be validated separately to check Julia recognises
them).
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
    head_chars=[['^'], vcat(ALPHANUM_ALL)],
    tail_chars=vcat(ALPHANUM_ALL, [']', ':', '_']),
    check=FOOTNOTE_PAT
)

"""
F_HR
"""
const F_HR_1 = greedy_match(
    head_chars=[['-'], ['-']],
    tail_chars=['-']
)
const F_HR_2 = greedy_match(
    head_chars=[['*'], ['*']],
    tail_chars=['*']
)
const F_HR_3 = greedy_match(
    head_chars=[['_'], ['_']],
    tail_chars=['_']
)

# """
# $(SIGNATURES)
#
# Check if it looks like `\\[\\^[\\p{L}0-9]+\\]:?`.
# """
# function is_footnote(i::Int, c::Char)::Bool
#     i == 1 && return c == '^'
#     i == 2 && return is_alphanum_or(c)
#     i > 2  && return is_alphanum_or(c, (']', ':'))
# end
#
# """
# $(SIGNATURES)
#
# Check if it looks like `---+`.
# """
# is_hr1(::Int, c::Char)::Bool = (c == '-')
#
# val_hr1 = validator(HR1_PAT)
#
# """
# $(SIGNATURES)
#
# Check if it looks like `___+`.
# """
# is_hr2(::Int, c::Char)::Bool = (c == '_')
#
# val_hr2 = validator(HR2_PAT)
#
# """
# $(SIGNATURES)
#
# Check if it looks like `***+`.
# """
# is_hr3(::Int, c::Char)::Bool = (c == '*')
#
# val_hr3 = validator(HR3_PAT)
