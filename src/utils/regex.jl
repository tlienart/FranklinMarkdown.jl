"""
HR*_PAT

Pattern to match horizontal rule indicators.
"""
const HR1_PAT = r"\-{3}\-*"
const HR2_PAT = r"\_{3}\_*"
const HR3_PAT = r"\*{3}\**"


"""
*_WHITESPACE_PAT

Pattern to match the whitespaces (tabs or spaces) at the start of a line, see
[`dedent`](@ref).
"""
const LEADING_WHITESPACE_PAT = r"^([ \t]*)\S"
const NEWLINE_WHITESPACE_PAT = r"\n([ \t]*)\S"


"""
LX_COMMAND_PAT

Allowed latex command name.

## Examples:
* \\com
* \\ab1_cd*
"""
const LX_COMMAND_PAT = r"^\\[a-zA-Z][_a-zA-Z0-9]*\*?$"

"""
CODE_LANG*_PAT
"""
const CODE_LANG3_PAT = r"^`{3}[a-zA-Z][a-zA-Z0-9-]*$"
const CODE_LANG4_PAT = r"^`{4}[a-zA-Z][a-zA-Z0-9-]*$"
const CODE_LANG5_PAT = r"^`{5}[a-zA-Z][a-zA-Z0-9-]*$"

"""
HTML_ENTITY_PAT

Pattern for an html entity.
Ref: https://dev.w3.org/html5/html-author/charref.

## Examples:
* &sqcap;
* &SquareIntersection;
* &#x02293;
* &#8851;
"""
const HTML_ENTITY_PAT = r"^&(?:[a-zA-Z]+[0-9]{0,2}|#[0-9]{1,6}|#x[0-9a-f]{1,6});$"


const EMOJI_PAT = r"^\:[a-zA-Z0-9+-_]+\:$"

const FOOTNOTE_PAT = r"^\[\^[\p{L}0-9][\p{L}0-9_]*\](:)?$"
