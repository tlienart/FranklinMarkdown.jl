"""
    MD_TOKENS

Dictionary of tokens for Markdown. Note that for each, there may be several
possibilities to consider in which case the order is important: the first case
that works will be taken.

Dev: F_* are greedy match, see `md_utils.jl`.

Try: https://spec.commonmark.org/dingus
"""
const MD_TOKENS = LittleDict{Char, Vector{Pair{TokenFinder, Symbol}}}(
    '?' => [
        forward_match("???") => :RAW
    ],
    '(' => [
        forward_match("(") => :BRACKET_OPEN
        ],
    ')' => [
        forward_match(")") => :BRACKET_CLOSE
        ],
    '{' => [
        forward_match("{")  => :CU_BRACKET_OPEN
        ],
    '}' => [
        forward_match("}")  => :CU_BRACKET_CLOSE,
        ],
    '\n' => [
        F_LINE_RETURN       => :LINE_RETURN,
        forward_match("\n") => :LINE_RETURN,
        ],
    '<' => [
        forward_match("<!--")           => :COMMENT_OPEN,
        forward_match("<", ALPHA_LATIN) => :AUTOLINK_OPEN
        ],
    '>' => [
        forward_match(">") => :AUTOLINK_CLOSE
        ],
    '-' => [
        forward_match("-->") => :COMMENT_CLOSE,
        ],
    '+' => [
        forward_match("+++", ['\n']) => :MD_DEF_BLOCK
        ],
    '~' => [
        forward_match("~~~") => :RAW_HTML
        ],
    '[' => [
        forward_match("[") => :SQ_BRACKET_OPEN,
        ],
    ']' => [
        forward_match("]")  => :SQ_BRACKET_CLOSE,
        ],
    ':' => [
        F_EMOJI => :CAND_EMOJI,
        ],
    '\\' => [
        # -- special characters (https://www.amp-what.com/unicode/search)
        # commonmark specs: https://spec.commonmark.org/0.30/#backslash-escapes
        # OK \#\$\~\{\}\*\@\\\!\"\%\&\'\+\,\-\.\/\:\;\<\=\>\?\^\_\`\|
        # NO \[\]\(\)
        forward_match("\\\\") => :LINEBREAK,         # --> <br/>
        forward_match("\\", SPACE_CHAR) => :CHAR_92,
        # -- maths
        forward_match("\\[")  => :MATH_C_OPEN,      # \[ ...
        forward_match("\\]")  => :MATH_C_CLOSE,     #    ... \]
        # -- latex
        forward_match("\\newenvironment", ['{']) => :LX_NEWENVIRONMENT,
        forward_match("\\newcommand", ['{'])     => :LX_NEWCOMMAND,
        forward_match("\\begin", ['{'])          => :LX_BEGIN,
        forward_match("\\end", ['{'])            => :LX_END,
        F_LX_COMMAND                             => :LX_COMMAND,  # \command⎵*
        # -- other special characters
        forward_match("\\*")  => :CHAR_42,
        forward_match("\\_")  => :CHAR_95,
        forward_match("\\`")  => :CHAR_96,
        forward_match("\\@")  => :CHAR_64,
        forward_match("\\#")  => :CHAR_35,
        forward_match("\\{")  => :CHAR_123,
        forward_match("\\}")  => :CHAR_125,
        forward_match("\\\$") => :CHAR_36,
        forward_match("\\~")  => :CHAR_126,
        forward_match("\\!")  => :CHAR_33,
        forward_match("\\\"") => :CHAR_34,
        forward_match("\\%")  => :CHAR_37,
        forward_match("\\&")  => :CHAR_38,
        forward_match("\\'")  => :CHAR_39,
        forward_match("\\+")  => :CHAR_43,
        forward_match("\\,")  => :CHAR_44,
        forward_match("\\-")  => :CHAR_45,
        forward_match("\\.")  => :CHAR_46,
        forward_match("\\/")  => :CHAR_47,
        forward_match("\\:")  => :CHAR_58,
        forward_match("\\;")  => :CHAR_59,
        forward_match("\\<")  => :CHAR_60,
        forward_match("\\=")  => :CHAR_61,
        forward_match("\\>")  => :CHAR_62,
        forward_match("\\?")  => :CHAR_63,
        forward_match("\\^")  => :CHAR_94,
        forward_match("\\|")  => :CHAR_124,
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
        forward_match("\$", ['$'], false) => :MATH_A,  # $⎵*
        forward_match("\$\$")             => :MATH_B,  # $$⎵*
        ],
    '_' => [
        forward_match("___", ['_'], false) => :EM_STRONG,
        forward_match("__",  ['_'], false) => :STRONG,
        forward_match("_",   ['_'], false) => :EM,
        ],
    '`' => [
        forward_match("`",  ['`'], false)   => :CODE_SINGLE,  # `⎵
        forward_match("``", ['`'], false)   => :CODE_DOUBLE,  # ``⎵*
        # 3+ can be named
        forward_match("```",  SPACE_CHAR)   => :CODE_TRIPLE,  # ```⎵*
        forward_match("`"^4,  SPACE_CHAR)   => :CODE_QUAD,    # ````⎵*
        forward_match("`"^5,  SPACE_CHAR)   => :CODE_PENTA,   # `````⎵*
        forward_match("```!", SPACE_CHAR)   => :CODE_TRIPLE!, # ```!⎵*
        #
        F_LANG_3 => :CODE_LANG3,   # ```lang*
        F_LANG_4 => :CODE_LANG4,   # ````lang*
        F_LANG_5 => :CODE_LANG5,   # `````lang*
        ],
    '*' => [
        forward_match("***", ['*'], false) => :EM_STRONG,
        forward_match("**",  ['*'], false) => :STRONG,
        forward_match("*",   ['*'], false) => :EM,
        ]
    )  # end dict

"""
MD_MATH_TOKENS

Tokens that should be considered within a math environment.
"""
const MD_MATH_TOKENS = LittleDict{Char, Vector{Pair{TokenFinder, Symbol}}}(
    '{' => [
        forward_match("{") => :CU_BRACKET_OPEN
        ],
    '}' => [
        forward_match("}") => :CU_BRACKET_CLOSE,
        ],
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
const MD_IGNORE = (:LINE_RETURN,)

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
