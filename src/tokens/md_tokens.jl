"""
MD_TOKENS

Dictionary of tokens for Markdown. Note that for each, there may be several
possibilities to consider in which case the order is important: the first case
that works will be taken.
"""
const MD_TOKENS = LittleDict{Char, Vector{Pair{TokenFinder, Symbol}}}(
    '{' => [
        forward_match("{{") => :DBB_OPEN,
        forward_match("{")  => :LXB_OPEN
        ],
    '}' => [
        forward_match("}}") => :DBB_CLOSE,
        forward_match("}")  => :LXB_CLOSE,
        ],
    '\n' => [
        forward_match("\n    ")  => :LINE_RETURN_INDENT_4,
        forward_match("\n  ")    => :LINE_RETURN_INDENT_2,
        forward_match("\n\t")    => :LINE_RETURN_INDENT_TAB,
        forward_match("\n")      => :LINE_RETURN
        ],
    '<' => [
        forward_match("<!--") => :COMMENT_OPEN
        ],
    '-' => [
        forward_match("-->") => :COMMENT_CLOSE,
        F_HR_1               => :HRULE
        ],
    '+' => [
        forward_match("+++", ['\n']) => :MD_DEF_BLOCK
        ],
    '~' => [
        forward_match("~~~") => :RAW_HTML
        ],
    '[' => [
        F_FOOTNOTE => :FOOTNOTE_REF, # [^...](:)? defs will be separated after
        ],
    ']' => [
        forward_match("]: ") => :LINK_DEF,
        ],
    ':' => [
        F_EMOJI => :CAND_EMOJI,
        ],
    '\\' => [ # -- special characters (https://www.amp-what.com/unicode/search)
        forward_match("\\\\") => :LINEBREAK,       # --> <br/>
        forward_match("\\", SPACE_CHAR) => :CHAR_92,
        forward_match("\\*")  => :CHAR_42,
        forward_match("\\_")  => :CHAR_95,
        forward_match("\\`")  => :CHAR_96,
        forward_match("\\@")  => :CHAR_64,
        forward_match("\\#")  => :CHAR_35,
        forward_match("\\{")  => :CHAR_123,
        forward_match("\\}")  => :CHAR_125,
        forward_match("\\\$") => :CHAR_36,
        # -- maths
        forward_match("\\[")  => :MATH_C_OPEN,      # \[ ...
        forward_match("\\]")  => :MATH_C_CLOSE,     #    ... \]
        # -- latex
        forward_match("\\newenvironment", ['{']) => :LX_NEWENVIRONMENT,
        forward_match("\\newcommand", ['{'])     => :LX_NEWCOMMAND,
        forward_match("\\begin", ['{'])          => :LX_BEGIN,
        forward_match("\\end", ['{'])            => :LX_END,
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
        forward_match("\$", ['$'], false) => :MATH_A,  # $⎵*
        forward_match("\$\$")             => :MATH_B,  # $$⎵*
        ],
    '_' => [
        forward_match("_\$>_") => :MATH_I_OPEN,  # internal when resolving a lx command
        forward_match("_\$<_") => :MATH_I_CLOSE, # within mathenv (e.g. \R <> \mathbb R)
        F_HR_2 => :HRULE,
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
        F_HR_3 => :HRULE,
        ]
    )  # end dict

"""
MD_MATH_TOKENS

Tokens that should be considered within a math environment.
"""
const MD_MATH_TOKENS = LittleDict{Char, Vector{Pair{TokenFinder, Symbol}}}(
    '{' => [
        forward_match("{")  => :LXB_OPEN
        ],
    '}' => [
        forward_match("}")  => :LXB_CLOSE,
        ],
    '\\' => [
        forward_match("\\begin", ['{'])          => :LX_BEGIN,
        forward_match("\\end", ['{'])            => :LX_END,
        F_LX_COMMAND                             => :LX_COMMAND,  # \command⎵*
        ],
    ) # end dict


"""
END_OF_LINE

All tokens that indicate the end of a line.
"""
const END_OF_LINE = (:LINE_RETURN, :LINE_RETURN_INDENT, :EOS)

"""
MD_IGNORE

Tokens that may be left over after partition but should be ignored in text blocks.
"""
const MD_IGNORE = (:LINE_RETURN, :LINE_RETURN_INDENT_TAB, :LINE_RETURN_INDENT_2,
                   :LINE_RETURN_INDENT_4)
