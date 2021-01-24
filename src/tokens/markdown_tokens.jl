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
        forward_match("-->")          => :COMMENT_CLOSE,
        # greedy_match(is_hr1, val_hr1) => :HRULE
        ],
    '+' => [
        forward_match("+++", ['\n']) => :MD_DEF_BLOCK
        ],
    '~' => [
        forward_match("~~~") => :RAW_HTML
        ],
    # '[' => [
    #     greedy_match(is_footnote) => :FOOTNOTE_REF, # [^...](:)? defs will be separated after
    #     ],
    ']' => [
        forward_match("]: ") => :LINK_DEF,
        ],
    # ':' => [
    #     greedy_match(is_emoji) => :CAND_EMOJI,
    #     ],
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
        forward_match("\\newenvironment", ['{'])   => :LX_NEWENVIRONMENT,
        forward_match("\\newcommand", ['{'])       => :LX_NEWCOMMAND,
        forward_match("\\begin", ['{'])            => :CAND_LX_BEGIN,
        forward_match("\\end", ['{'])              => :CAND_LX_END,
        # greedy_match(is_lx_command, val_lx_command) => :LX_COMMAND,  # \command⎵*
        ],
    '@' => [
        forward_match("@def", [' '])   => :MD_DEF_OPEN,    # @def var = ...
        forward_match("@@", SPACE_CHAR) => :DIV_CLOSE,      # @@⎵*
        # greedy_match(is_div_open)       => :DIV_OPEN,       # @@dname
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
        # greedy_match(is_html_entity, val_html_entity) => :CHAR_HTML_ENTITY,
        ],
    '$' => [
        forward_match("\$", ['$'], false) => :MATH_A,  # $⎵*
        forward_match("\$\$")              => :MATH_B,  # $$⎵*
        ],
    '_' => [
        forward_match("_\$>_")        => :MATH_I_OPEN,  # internal when resolving a lx command
        forward_match("_\$<_")        => :MATH_I_CLOSE, # within mathenv (e.g. \R <> \mathbb R)
        # greedy_match(is_hr2, val_hr2) => :HRULE,
        ],
    '`' => [
        forward_match("`",  ['`'], false)  => :CODE_SINGLE,  # `⎵
        forward_match("``", ['`'], false)  => :CODE_DOUBLE,  # ``⎵*
        # 3+ can be named
        forward_match("```",  SPACE_CHAR)   => :CODE_TRIPLE,  # ```⎵*
        forward_match("`"^4,  SPACE_CHAR)   => :CODE_QUAD,    # ````⎵*
        forward_match("`"^5,  SPACE_CHAR)   => :CODE_PENTA,   # `````⎵*
        forward_match("```!", SPACE_CHAR)   => :CODE_TRIPLE!, # ```!⎵*
        # greedy_match(is_lang(3), val_lang3) => :CODE_LANG3,   # ```lang*
        # greedy_match(is_lang(4), val_lang4) => :CODE_LANG4,   # ````lang*
        # greedy_match(is_lang(5), val_lang5) => :CODE_LANG5,   # `````lang*
        ],
    # '*' => [
    #     greedy_match(is_hr3, val_hr3) => :HRULE,
    #     ]
    )  # end dict


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

# """
# MD_1_TOKENS_MATH
#
# Reduced subset of `MD_1C_TOKENS` when parsing in a math environment.
# """
# const MD_1_TOKENS_MATH = filter(p -> p.first ∈ ['{', '}'), MD_1_TOKENS)
#
# """
# MD_N_TOKENS_MATH
#
# Reduced subset of `MD_N_TOKENS` specifically when parsing in a math environment.
# """
# const MD_N_TOKENS_MATH = LittleDict{Char, Vector{Pair{TokenFinder, Symbol}}}(
#     '\\' => [
#         forward_match("\\{")  => :INACTIVE,
#         forward_match("\\}")  => :INACTIVE,
#         greedy_match(is_lx_command, val_lx_command) => :LX_COMMAND
#         ]
#     )

#
# """
# $(SIGNATURES)
#
# Find specific tokens and check whether they should be adjusted, for instance double
# braces will have been captured individually and need to be merged.
#
# Rules:
# * {,{ => {{ and },} => }} (double brace)
# * \\n,\\s => \\n\\s (newline indent)
# """
# function postprocess!(tokens::Vector{Token})
#     n_tokens = length(tokens)
#     remove = Int[]
#     iszero(n_tokens) && return
#     parent = parent_string(tokens[1])
#     lastidx = lastindex(parent)
#     for i in eachindex(tokens)
#         token = tokens[i]
#         # { => {{ and } => }}
#         for (case, res) in zip((:LXB_OPEN, :LXB_CLOSE), (:DBB_OPEN, :DBB_CLOSE))
#             if (token.name == case) && (i < n_tokens)
#                 next_token = tokens[i+1]
#                 (to(token) == from(next_token) - 1) || continue
#                 if next_token.name == case
#                     push!(remove, i+1)
#                     tokens[i] = Token(res, subs(parent, from(token), to(next_token)))
#                 end
#             end
#         end
#         # \n => \n\t and \n => \n⎵
#         if (token.name == :LINE_RETURN)
#             # look at the next character if it exists
#             nxtidx = nextind(parent, to(token))
#             nxtidx < lastidx || continue
#             nxtchar = parent[nxtidx]
#             if nxtchar in [' ', '\t')
#                 tokens[i] = Token(:LINE_RETURN_INDENT, token.ss)
#             end
#         end
#     end
#     deleteat!(tokens, remove)
#     return
# end



# function md_math_tokenizer(s::AS)
#     return find_tokens(s, MD_1_TOKENS_MATH, MD_N_TOKENS_MATH)
# end

#
# """
# MD_N_TOKENS_LX
#
# Subset of `MD_TOKENS` with only the latex tokens (for parsing what's in a math environment).
# """
# const MD_N_TOKENS_LX = LittleDict{Char, Vector{TokenFinder}}(
#     '\\' => [
#         forward_match("\\{") => :INACTIVE,
#         forward_match("\\}") => :INACTIVE,
#         greedy_match((_, c) -> is_letter_or(c)) => :LX_COMMAND
#         ]
#     )
#
#
# """
# L_RETURNS
#
# Convenience tuple containing the name for standard line returns and line
# returns followed by an indentation (either a quadruple space or a tab).
# """
# const L_RETURNS = (:LINE_RETURN, :LR_INDENT, :EOS)


# """
# MD_OCB
#
# List of Open-Close Blocks whose content should be deactivated (any token within
# their span should be marked as inactive) until further processing.
# The keys are identifier for the type of block, the value is a pair with the
# opening and closing tokens followed by a boolean indicating whether the content
# of the block should be reprocessed.
# The only `OCBlock` not in this dictionary is the brace block since it should
# not deactivate its content which is needed to find latex definitions
# (see parser/markdown/find_blocks/find_lxdefs).
# """
# const MD_OCB = [
#     # name                    opening token   closing token(s)
#     # ---------------------------------------------------------------------
#     OCProto(:COMMENT,         :COMMENT_OPEN, (:COMMENT_CLOSE]),
#     OCProto(:MD_DEF_BLOCK,    :MD_DEF_TOML,  (:MD_DEF_TOML]  ),
#     OCProto(:CODE_BLOCK_LANG, :CODE_LANG3,   (:CODE_TRIPLE]  ),
#     OCProto(:CODE_BLOCK_LANG, :CODE_LANG4,   (:CODE_QUAD]    ),
#     OCProto(:CODE_BLOCK_LANG, :CODE_LANG5,   (:CODE_PENTA]   ),
#     OCProto(:CODE_BLOCK!,     :CODE_TRIPLE!, (:CODE_TRIPLE]  ),
#     OCProto(:CODE_BLOCK,      :CODE_TRIPLE,  (:CODE_TRIPLE]  ),
#     OCProto(:CODE_BLOCK,      :CODE_QUAD,    (:CODE_QUAD]    ),
#     OCProto(:CODE_BLOCK,      :CODE_PENTA,   (:CODE_PENTA]   ),
#     OCProto(:CODE_INLINE,     :CODE_DOUBLE,  (:CODE_DOUBLE]  ),
#     OCProto(:CODE_INLINE,     :CODE_SINGLE,  (:CODE_SINGLE]  ),
#     OCProto(:MD_DEF,          :MD_DEF_OPEN,  L_RETURNS        ), # [^4]
#     OCProto(:CODE_BLOCK_IND,  :LR_INDENT,    (:LINE_RETURN]  ),
#     OCProto(:ESCAPE,          :ESCAPE,       (:ESCAPE]       ),
#     OCProto(:FOOTNOTE_DEF,    :FOOTNOTE_DEF, L_RETURNS        ),
#     OCProto(:LINK_DEF,        :LINK_DEF,     L_RETURNS        ),
#     # ------------------------------------------------------------------
#     OCProto(:H1,              :H1_OPEN,      L_RETURNS), # see [^3]
#     OCProto(:H2,              :H2_OPEN,      L_RETURNS),
#     OCProto(:H3,              :H3_OPEN,      L_RETURNS),
#     OCProto(:H4,              :H4_OPEN,      L_RETURNS),
#     OCProto(:H5,              :H5_OPEN,      L_RETURNS),
#     OCProto(:H6,              :H6_OPEN,      L_RETURNS)
#     ]
# # the split is due to double brace blocks being allowed in markdown
# const MD_OCB2 = [
#     OCProto(:LXB,             :LXB_OPEN,     (:LXB_CLOSE], nestable=true),
#     OCProto(:DIV,             :DIV_OPEN,     (:DIV_CLOSE], nestable=true),
#     ]
# #= NOTE:
# * [3] a header can be closed by either a line return or an end of string (for
# instance in the case where a user defines a latex command like so:
# \newcommand{\section}{# blah} (no line return).)
# * [4] MD_DEF take precedence over CODE_IND, note that if you have an indented
# * block with @def in it, things may go bad.
# * ordering matters!
# =#
#
#
# """
#     MD_HEADER
#
# All header symbols.
# """
# const MD_HEADER = (:H1, :H2, :H3, :H4, :H5, :H6)
#
#
# """
#     MD_HEADER_OPEN
#
# All header symbols (opening).
# """
# const MD_HEADER_OPEN = (:H1_OPEN, :H2_OPEN, :H3_OPEN, :H4_OPEN, :H5_OPEN, :H6_OPEN)
#
#
# """
#     MD_OCB_ESC
#
# Blocks that will be escaped (tokens in their span will be ignored on the
# current parsing round).
# """
# const MD_OCB_ESC = [e.name for e ∈ MD_OCB if !e.nest]
#
#
# """
#     MD_OCB_MATH
#
# Same concept as `MD_OCB` but for math blocks, they can't be nested. Separating
# them from the other dictionary makes their processing easier.
# Dev note: order does not matter.
# """
# const MD_OCB_MATH = [
#     OCProto(:MATH_A,     :MATH_A,          (:MATH_A]          ),
#     OCProto(:MATH_B,     :MATH_B,          (:MATH_B]          ),
#     OCProto(:MATH_C,     :MATH_C_OPEN,     (:MATH_C_CLOSE]    ),
#     OCProto(:MATH_I,     :MATH_I_OPEN,     (:MATH_I_CLOSE]    ),
#     ]
#
#
# """
#     MD_OCB_ALL
#
# Combination of all `MD_OCB` in order.
# DEV: only really used in tests.
# """
# const MD_OCB_ALL = vcat(MD_OCB, MD_OCB2, MD_OCB_MATH)
#
# """
#     MD_OCB_IGNORE
#
# List of names of blocks that will need to be dropped at compile time.
# """
# const MD_OCB_IGNORE = (:COMMENT, :MD_DEF)
#
# """
#     MATH_DISPLAY_BLOCKS_NAMES
#
# List of names of maths environments (display mode).
# """
# const MATH_DISPLAY_BLOCKS_NAMES = collect(e.name for e ∈ MD_OCB_MATH if e.name != :MATH_A)
#
# """
#     MATH_BLOCKS_NAMES
#
# List of names of all maths environments.
# """
# const MATH_BLOCKS_NAMES = tuple(:MATH_A, MATH_DISPLAY_BLOCKS_NAMES...)
#
# """
# CODE_BLOCKS_NAMES
#
# List of names of code blocks environments.
# """
# const CODE_BLOCKS_NAMES = (:CODE_BLOCK_LANG, :CODE_BLOCK, :CODE_BLOCK!, :CODE_BLOCK_IND)
#
# """
#     MD_CLOSEP
#
# Blocks which, upon insertion, should close any open paragraph.
# Order doesn't matter.
# """
# const MD_CLOSEP = [MD_HEADER..., :DIV, CODE_BLOCKS_NAMES..., MATH_DISPLAY_BLOCKS_NAMES...]
#
# """
#     MD_OCB_NO_INNER
#
# List of names of blocks which will deactivate any block contained within them
# as their content will be reprocessed later on.
# See [`find_all_ocblocks`](@ref).
# """
# const MD_OCB_NO_INNER = vcat(MD_OCB_ESC, MATH_BLOCKS_NAMES, :LXB, MD_HEADER)
