"""
    HTML_TOKENS

Dictionary of tokens for HTML. See also [`MD_TOKENS`](@ref).
"""
const HTML_TOKENS = LittleDict{Char, Vector{Pair{TokenFinder, Symbol}}}(
    '{' => [
        forward_match("{{") => :DBB_OPEN
        ],
    '}' => [
        forward_match("}}") => :DBB_CLOSE
        ],
    '<' => [
        forward_match("<!--")                => :COMMENT_OPEN,
        forward_match("<script", [' ', '>']) => :SCRIPT_OPEN,  # [1]
        forward_match("</script>")           => :SCRIPT_CLOSE
        ],
    '-' => [
        forward_match("-->") => :COMMENT_CLOSE
        ],
    '\\' => [
        forward_match("\\(") => :MATH_INLINE_OPEN,
        forward_match("\\)") => :MATH_INLINE_CLOSE,
        forward_match("\\[") => :MATH_BLOCK_OPEN,
        forward_match("\\]") => :MATH_BLOCK_CLOSE,
    ]
)
#
# [1] note that we don't capture the closing `>` so for an application where the user
# would want to extract the content in a script block; they would have to post-filer
# the result of `content` to find the first `>` character and start from there.
# We don't do that by default because in Franklin we ignore script blocks completely.
#
# Note also that we are a bit strict in requiring exactly '<script' and '</script>' so
# users who would somehow enter '< SCRIPT' or whatever would have to be told not to
#
