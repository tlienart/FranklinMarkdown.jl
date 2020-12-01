"""
LX_COMMAND_PAT

Allowed latex command name (without `\\`).

## Examples:
* com
* ab1_cd*
"""
const LX_COMMAND_PAT = r"^\p{L}[\p{L}_0-9]*\*?$"

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
const HTML_ENTITY_PAT = r"&(?:[a-zA-Z]+[0-9]{0,2}|#[0-9]{1,6}|#x[0-9a-f]{1,6});"

# """
# LX_NARG_PAT
#
# Regex to find the number of argument in a new command (if it is given). For
# example:
#
#     \\newcommand{\\com}[2]{def}
#
# will give as second capture group `2`. If there are no number of arguments, the
# second capturing group will be `nothing`.
# """
# const LX_NARG_PAT = r"\s*(\[\s*(\d)\s*\])?\s*"
#
#
# """
# LX_ENVNAME_PAT
#
# Regex to find the name in a LX_BEGIN or LX_END.
# """
# const LX_ENVNAME_PAT = r"\\(?:begin|end)\{\s*(\p{L}+\*?)\s*\}"
#
# #= =====================================================
# MDDEF patterns
# ===================================================== =#
# """
#     ASSIGN_PAT
#
# Regex to match 'var' in an assignment of the form
#
#     var = value
# """
# const ASSIGN_PAT = r"^([\p{L}_]\S*)\s*?=((?:.|\n)*)"
#
# #= =====================================================
# LINK patterns, see html link fixer, validate_footnotes
# ===================================================== =#
# # here we're looking for [id] or [id][] or [stuff][id] or ![stuff][id] but not [id]:
# # 1 > (&#33;)? == either ! or nothing
# # 2 > &#91;(.*?)&#93; == [...] inside of the brackets
# # 3 > (?:&#91;(.*?)&#93;)? == [...] inside of second brackets if there is such
# const ESC_LINK_PAT = r"(&#33;)?&#91;(.*?)&#93;(?!:)(?:&#91;(.*?)&#93;)?"
#
# const FN_DEF_PAT = r"^\[\^[\p{L}0-9_]+\](:)?$"
#
# #= =====================================================
# CODE blocks
# ===================================================== =#
#
# const CODE_3!_PAT = r"```\!\s*\n?((?:.|\n)*)```"
#
# const CODE_3_PAT = Regex(
#         "```([a-zA-Z][a-zA-Z-]*)" *    # language
#         "(?:(" * # optional script name
#             "\\:[\\p{L}\\\\\\/_\\.]" * # :(...) start of script name
#             "[\\p{L}_0-9-\\\\\\/]*"  * # script name
#             "(?:\\.[a-zA-Z0-9]+)?"   * # script extension
#         ")|(?:\\n|\\s))" *
#         "\\s*\\n?((?:.|\\n)*)```") # rest of the code
#
# const CODE_5_PAT = Regex("``" * CODE_3_PAT.pattern * "``")
#
# #= =====================================================
# HTML entity pattern
# ===================================================== =#
# const HTML_ENT_PAT = r"&(?:[a-z0-9]+|#[0-9]{1,6}|#x[0-9a-f]{1,6});"
#
# #= =====================================================
# HBLOCK patterns, see html blocks
# NOTE: the &#123 is { and 125 is }, this is because
# Markdown.html converts { => html entity but we want to
# recognise those double as {{ so that they can be used
# within markdown as well.
# NOTE: the for block needs verification (matching parens)
# ===================================================== =#
# const HBO = raw"(?:{{|&#123;&#123;)\s*"
# const HBC = raw"\s*(?:}}|&#125;&#125;)"
# const VAR = raw"([\p{L}_]\S*)"
# const ANY = raw"((.|\n)+?)"
#
# const HBLOCK_IF_PAT     = Regex(HBO * raw"if\s+" * VAR * HBC)
# const HBLOCK_ELSE_PAT   = Regex(HBO * "else" * HBC)
# const HBLOCK_ELSEIF_PAT = Regex(HBO * raw"else\s*if\s+" * VAR * HBC)
# const HBLOCK_END_PAT    = Regex(HBO * "end" * HBC)
#
# const HBLOCK_ISDEF_PAT    = Regex(HBO * raw"i(?:s|f)def\s+" * VAR * HBC)
# const HBLOCK_ISNOTDEF_PAT = Regex(HBO * raw"i(?:s|f)n(?:ot)?def\s+" * VAR * HBC)
#
# const HBLOCK_ISEMPTY_PAT    = Regex(HBO * raw"i(?:s|f)empty\s+" * VAR * HBC)
# const HBLOCK_ISNOTEMPTY_PAT = Regex(HBO * raw"i(?:s|f)n(?:ot)?empty\s+" * VAR * HBC)
#
# const HBLOCK_ISPAGE_PAT    = Regex(HBO * raw"ispage\s+" * ANY * HBC)
# const HBLOCK_ISNOTPAGE_PAT = Regex(HBO * raw"isnotpage\s+" * ANY * HBC)
#
# """
#     HBLOCK_FOR_PAT
#
# Regex to match `{{ for v in iterate }}` or {{ for (v1, v2) in iterate}} etc
# where `iterate` is an iterator
# """
# const HBLOCK_FOR_PAT = Regex(
#         HBO * raw"for\s+" *
#         raw"(\(?(?:\s*[\p{L}_][^\r\n\t\f\v,]*,\s*)*[\p{L}_]\S*\s*\)?)" *
#         raw"\s+in\s+" * VAR * HBC)
#
# """
# HBLOCK_FUN_PAT
#
# Regex to match `{{ fname param₁ param₂ }}` where `fname` is a html processing
# function and `paramᵢ` should refer to appropriate variables in the current
# scope.
# """
# const HBLOCK_FUN_PAT = Regex(HBO * VAR * raw"(\s+((.|\n)*?))?" * HBC)
#
# #= =====================================================
# Pattern checkers
# ===================================================== =#
#
# """
#     check_for_pat(v)
#
# Check that we have something like `{{for v in iterate}}` or
# `{for (v1,v2) in iterate}}` but not something with unmached parens.
# """
# function check_for_pat(v)
#     op = startswith(v, "(")
#     cp = endswith(v, ")")
#     xor(op, cp) &&
#         throw(HTMLBlockError("Unbalanced expression in {{for ...}}"))
#     !op && occursin(",", v) &&
#         throw(HTMLBlockError("Missing parens in {{for ...}}"))
#     return nothing
# end
