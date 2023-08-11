"""
    HTML_TOKENS_SIMPLE

Cf. MD_TOKENS_SIMPLE, same but for html.
"""
const HTML_TOKENS_SIMPLE = Dict{String,Symbol}(
    "{{"        => :DBB_OPEN,
    "}}"        => :DBB_CLOSE,
    "<!--"      => :COMMENT_OPEN,
    "-->"       => :COMMENT_CLOSE,
    "\\("       => :MATH_INLINE_OPEN,
    "\\)"       => :MATH_INLINE_CLOSE,
    "\\["       => :MATH_BLOCK_OPEN,
    "\\]"       => :MATH_BLOCK_CLOSE,
    "<script>"  => :SCRIPT_OPEN,
    "</script>" => :SCRIPT_CLOSE
)


"""
    HTML_TOKENS

Dictionary of tokens for HTML. See also [`MD_TOKENS`](@ref).
"""
const HTML_TOKENS = Dict{Char, Vector{Pair{TokenFinder, Symbol}}}(
    '<' => [
        forward_match("<script", [' ', '>']) => :SCRIPT_OPEN,  # [1]
        ],
)
#
# [1] note that here we don't capture the closing `>` so for an application
# where the user would want to extract the content in a script block; they
# would have to post-filer the result of `content` to find the first `>`
# character and start from there.
# We don't do that by default because in Franklin we ignore script blocks
# completely.
#
# Note also that we are a bit strict in requiring exactly '<script' and
# '</script>' so users who would somehow enter '< SCRIPT' or whatever would
# have to be told not to.
#
