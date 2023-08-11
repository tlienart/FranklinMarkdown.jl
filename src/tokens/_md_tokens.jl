"""
    MD_TOKENS_SIMPLE

Dictionary of tokens for Markdown where a simple match over a fixed set of
characters is enough, and where there's no special character so indexing
arithmetic is by increments of one.
"""
const MD_TOKENS_SIMPLE = Dict{String,Symbol}(
    "???"  => :RAW,
    "~~~"  => :RAW_HTML,
    "%%%"  => :RAW_LATEX,
    "("    => :BRACKET_OPEN,
    ")"    => :BRACKET_CLOSE,
    "{"    => :CU_BRACKET_OPEN,
    "}"    => :CU_BRACKET_CLOSE,
    "["    => :SQ_BRACKET_OPEN,
    "]"    => :SQ_BRACKET_CLOSE,
    "<!--" => :COMMENT_OPEN,
    "-->"  => :COMMENT_CLOSE,
    ">"    => :AUTOLINK_CLOSE,
    "|"    => :PIPE,
    "\\\\" => :LINEBREAK,       # --> br
    # -- maths
    "\\["  => :MATH_DISPL_B_OPEN,      # \[ ...
    "\\]"  => :MATH_DISPL_B_CLOSE,     #    ... \]
    "\$\$" => :MATH_DISPL_A,  # $$⎵*
    # -- other special characters
    "\\*"  => :CHAR_42,
    "\\_"  => :CHAR_95,
    "\\`"  => :CHAR_96,
    "\\@"  => :CHAR_64,
    "\\#"  => :CHAR_35,
    "\\{"  => :CHAR_123,
    "\\}"  => :CHAR_125,
    "\\\$" => :CHAR_36,
    "\\~"  => :CHAR_126,
    "\\!"  => :CHAR_33,
    "\\\"" => :CHAR_34,
    "\\%"  => :CHAR_37,
    "\\&"  => :CHAR_38,
    "\\'"  => :CHAR_39,
    "\\+"  => :CHAR_43,
    "\\,"  => :CHAR_44,
    "\\-"  => :CHAR_45,
    "\\."  => :CHAR_46,
    "\\/"  => :CHAR_47,
    "\\:"  => :CHAR_58,
    "\\;"  => :CHAR_59,
    "\\<"  => :CHAR_60,
    "\\="  => :CHAR_61,
    "\\>"  => :CHAR_62,
    "\\?"  => :CHAR_63,
    "\\^"  => :CHAR_94,
    "\\|"  => :CHAR_124,
)


"""
    MD_TOKENS

Dictionary of tokens for Markdown. Note that for each, there may be several
possibilities to consider in which case the order is important: the first case
that works will be taken.

Dev: F_* are greedy match, see `md_utils.jl`.

Try: https://spec.commonmark.org/dingus
"""
const MD_TOKENS = Dict{Char, Vector{Pair{TokenFinder, Symbol}}}(
    '\n' => [
        F_LINE_RETURN       => :LINE_RETURN,
        forward_match("\n") => :LINE_RETURN,
        ],
    '<' => [
        # forward_match("<!--")           => :COMMENT_OPEN,
        forward_match("<", ALPHA_LATIN) => :AUTOLINK_OPEN
        ],
    ':' => [
        F_EMOJI => :CAND_EMOJI,
        ],
    '+' => [
        forward_match("+++", ['\n', EOS]) => :MD_DEF_BLOCK
        ],
    '\\' => [
        # -- special characters (https://www.amp-what.com/unicode/search)
        # commonmark specs: https://spec.commonmark.org/0.30/#backslash-escapes
        # OK \#\$\~\{\}\*\@\\\!\"\%\&\'\+\,\-\.\/\:\;\<\=\>\?\^\_\`\|
        # NO \[\]\(\)
        forward_match("\\", SPACE_CHAR) => :CHAR_92,
        # -- latex
        forward_match("\\newenvironment", ['{']) => :LX_NEWENVIRONMENT,
        forward_match("\\newcommand",     ['{']) => :LX_NEWCOMMAND,
        forward_match("\\begin",          ['{']) => :LX_BEGIN,
        forward_match("\\end",            ['{']) => :LX_END,
        F_LX_COMMAND                             => :LX_COMMAND,  # \command⎵*
        ],
    '@' => [
        forward_match("@def", [' '])    => :MD_DEF_OPEN,    # @def var = ...
        forward_match("@@", SPACE_CHAR) => :DIV_CLOSE,      # @@⎵*
        F_DIV_OPEN                      => :DIV_OPEN,       # @@dname
        ],
    '#' => [
        forward_match("#",      [' ']) => :H1_OPEN,
        forward_match("##",     [' ']) => :H2_OPEN,
        forward_match("###",    [' ']) => :H3_OPEN,
        forward_match("####",   [' ']) => :H4_OPEN,
        forward_match("#####",  [' ']) => :H5_OPEN,
        forward_match("######", [' ']) => :H6_OPEN,
        ],
    '&' => [
        F_HTML_ENTITY => :CHAR_HTML_ENTITY,
        ],
    '$' => [
        forward_match("\$", ['$'], false) => :MATH_INLINE,   # $⎵*
        ],
    '_' => [
        forward_match("___", ['_'], false) => :EM_STRONG,
        forward_match("__",  ['_'], false) => :STRONG,
        forward_match("_",   ['_'], false) => :EM,
        ],
    '`' => [
        forward_match("`",   ['`'], false) => :CODE_SINGLE,  # `⎵
        forward_match("``",  ['`'], false) => :CODE_DOUBLE,  # ``⎵*
        forward_match("```", ['`'], false) => :CODE_TRIPLE,  # ```⎵*
        forward_match("`"^4, ['`'], false) => :CODE_QUAD,    # ````⎵*
        forward_match("`"^5, ['`'], false) => :CODE_PENTA,   # `````⎵*
        ],
    '*' => [
        forward_match("***", ['*'], false) => :EM_STRONG,
        forward_match("**",  ['*'], false) => :STRONG,
        forward_match("*",   ['*'], false) => :EM,
        ]
    )  # end dict


"""
    MD_MATH_TOKENS_SIMPLE

Cf. MD_TOKENS_SIMPLE.
"""
const MD_MATH_TOKENS_SIMPLE = Dict{String,Symbol}(
    "{" => :CU_BRACKET_OPEN,
    "}" => :CU_BRACKET_CLOSE,
)


"""
    MD_MATH_TOKENS

Tokens that should be considered within a math environment.
"""
const MD_MATH_TOKENS = Dict{Char, Vector{Pair{TokenFinder, Symbol}}}(
    '\\' => [
        forward_match("\\begin", ['{']) => :LX_BEGIN,
        forward_match("\\end", ['{'])   => :LX_END,
        F_LX_COMMAND                    => :LX_COMMAND,  # \command⎵*
        ],
    ) # end dict


"""
    END_OF_LINE

All tokens that indicate the end of a line.
"""
const END_OF_LINE = (:LINE_RETURN, :EOS)

"""
    MD_IGNORE

Tokens that may be left over after partition but should be ignored in text blocks.
"""
const MD_IGNORE = (:SOS, :LINE_RETURN, :EOS)

"""
    MD_HEADERS

Tokens for headers.
"""
const MD_HEADERS = (
    :H1_OPEN,
    :H2_OPEN,
    :H3_OPEN,
    :H4_OPEN,
    :H5_OPEN,
    :H6_OPEN,
)
