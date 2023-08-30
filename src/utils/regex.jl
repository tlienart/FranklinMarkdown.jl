"""
    HR_PAT

Pattern to match horizontal rule indicators.
"""
const HR_PAT = r"^([\-\_\*]){3}(?:\s|\1)*$"


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
Underscore are allowed inside the command but not at extremities.
The star `*` is not allowed anywhere.

## Examples:
* \\com
* \\ab1_cd*
"""
const LX_COMMAND_PAT = r"^\\[a-zA-Z](?:[_a-zA-Z0-9]*[a-zA-Z0-9])?$"

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

Note: longest entity is &CounterClockwiseContourIntegral; so capping the max
number of characters to 32.
"""
const HTML_ENTITY_PAT = r"&(?:[a-zA-Z]{1,32}[0-9]{0,2}|#[0-9]{1,6}|#x[0-9a-f]{1,6});"


const EMOJI_PAT = r"^\:[a-zA-Z0-9+-_]+\:$"

const FOOTNOTE_PAT = r"^\[\^[\p{L}0-9][\p{L}0-9_]*\](:)?$"

const OL_ITEM_PAT = r"^\s*[0-9]{1,9}(?:[\.\)])[ \t]"

# we're stricter here than usual Github-flavored-markdown in that
# rows *must* start and end with a pipe, every row must be on a
# single line (we allow spaces before and after first and final pipe)
const ROW_CAND_PAT = r"^\s*\|.+\|\s*$"
