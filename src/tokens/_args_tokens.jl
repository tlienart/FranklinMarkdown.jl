const ARGS_TOKENS = LittleDict{Char, Vector{Pair{TokenFinder, Symbol}}}(
    '\\' => [
        forward_match("\\\"") => :SKIP,
    ],
    '"' => [
        forward_match("\"", ['"'], false)     => :SINGLE_QUOTE,
        forward_match("\"\"\"", ['"'], false) => :TRIPLE_QUOTE
    ]
)
