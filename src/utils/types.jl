"""
    AbstractSpan

Section of a parent String with a specific meaning. All subtypes of
`AbstractSpan` must have an `ss` field corresponding to the substring
associated to the block. This field is necessarily of type `SubString{String}`.
"""
abstract type AbstractSpan end

parent_string(s::AbstractSpan)::String = parent_string(s.ss::SS)

from(s::AbstractSpan)::Int             = from(s.ss::SS)
to(s::AbstractSpan)::Int               = to(s.ss::SS)

content(s::AbstractSpan)::SS           = s.ss
content(s::SS)::SS                     = s
content(s::String)::SS                 = subs(s)

Base.isempty(o::AbstractSpan)::Bool    = isempty(strip(o.ss))


"""
    Token{N} <: AbstractSpan

A token is a small span typically determining the start or end of a block.
It can also be used for special characters.
"""
struct Token{N} <: AbstractSpan
    ss::SS
end
Token(n, ss) = Token{n}(ss)

is_sos(t::Token)       = false
is_sos(t::Token{:SOS}) = true
is_eos(t::Token)       = false
is_eos(t::Token{:EOS}) = true
to(t::Token{:EOS})     = from(t.ss)

const EMPTY_TOKEN_SVEC = @view (Token[])[1:0] # always valid, always empty

name(::Token{N}) where N = N


"""
    Block{N} <: AbstractSpan

Blocks are a span covering one or more tokens.
"""
struct Block{N} <: AbstractSpan
    ss    ::SS
    tokens::SubVector{Token}
end
Block(name, ss, tokens=EMPTY_TOKEN_SVEC) = Block{name}(ss, tokens)

"""
    Block(name, tokens)

Constructor where the span is implicitly `from(tokens[1])` to `to(tokens[end])`.
"""
function Block(
            name::Symbol,
            tokens::SubVector{Token}
        )
    ps = parent_string(tokens[1])
    return Block(
        name,
        subs(ps, from(tokens[1]), to(tokens[end])),
        tokens
    )
end

"""
    TokenBlock(tokens, i)

Constructor where the span is implicitly `from(tokens[i])` to `to(tokens[i])`
and the name is that of the token. There's never any metadata for token blocks.
"""
function TokenBlock(
            tokens::Vector{Token},
            i::Int
        )
    return Block(
        name(tokens[i]),
        tokens[i].ss,
        @view tokens[i:i]
    )
end

name(::Block{N}) where N = N

"""
    span_between(b, i, j)

Span (substring) between token `i` and `j` of the block `b`.
"""
function span_between(b::Block, i::Int, j::Int)::SS
    s = parent_string(b.ss)
    if j <= 0
        return subs(s,
            nextind(s, to(b.tokens[i])),
            prevind(s, from(b.tokens[end + j]))
        )
    end
    return subs(s,
            nextind(s, to(b.tokens[i])),
            prevind(s, from(b.tokens[j]))
        )
end

"""
    content(block)

Return the relevant content of a `Block`, for instance the content of a `{...}`
block would be `...`. Note EOS is a special '0 length' case to  deal with the
fact that a text can end with a token (which would then be an overlapping token
and an EOS).
"""
function content(b::Block)::SS
    # General case from opening to closing token
    s    = parent_string(b.ss)
    idxo = nextind(s, to(b.tokens[1]))
    c    = b.tokens[end]
    t    = from(c)
    idxc = ifelse(is_eos(c), t, prevind(s, t))
    return subs(s, idxo, idxc)
end

function content(b::Block{:TEXT})::SS
    return b.ss
end

function content(b::Block{:DIV})::SS
    return lstrip(span_between(b, 1, 0))
end

function content(b::Block{:BLOCKQUOTE})::SS
    return strip(replace(
            b.ss,
            r"(?:(?:^>)|(?:\n>))[ \t]*" => "\n")
        ) 
end

content(b::Block{:ENV}) = span_between(b, 3, -2)

function content(b::Block{:DBB})
    if name(b.tokens[1]) == :DBB_OPEN # html case
        span_between(b, 1, 0)
    else
        span_between(b, 2, -1)
    end
end

function content(b::Block{:REF})::SS
    ps = parent_string(b)
    return subs(ps, 
        nextind(ps, next_index(b.tokens[2]), 2), # skip the `:⎵`
        to(b.ss)
    )
end

"""
    content_tokens(block)

Return the view of tokens corresponding to `content(block)`.
"""
function content_tokens(b::Block)::SubVector{Token}
    # general case from opening to closing token
    return @view b.tokens[2:end-1]
end

content_tokens(b::Block{:ENV}) = @view b.tokens[4:end-3]
content_tokens(b::Block{:DBB}) = @view b.tokens[3:end-2]
content_tokens(b::Block{:REF}) = @view b.tokens[3:end]

content_tokens(b::Union{
    Block{:TEXT},
    Block{:LIST},
    Block{:BLOCKQUOTE},
    Block{:TABLE},
    Block{:REF}
    }) = b.tokens

env_name(b::Block{:ENV}) = span_between(b, 2, 3)

link_a(b::Union{
    Block{:LINK_A}, Block{:LINK_AR}, Block{:LINK_AB},
    Block{:IMG_A}, Block{:IMG_AR}, Block{:IMG_AB},
    Block{:REF}
    }) = span_between(b, 1, 2)

link_b(b::Union{
    Block{:LINK_AR}, Block{:LINK_AB},
    Block{:IMG_AR}, Block{:IMG_AB}
    }) = span_between(b, 3, 4)


"""
    BlockTemplate

Template for a block to find for the general case where a block goes from an
opening token to one of several possible closing tokens.
Blocks can allow or disallow nesting. For instance brace blocks can be nested
`{.{.}.}` but not comments.
When nesting is enabled, Franklin will try to find the closing token taking
into account the balance in opening-closing tokens.
"""
struct BlockTemplate
    name    ::Symbol
    opening ::Symbol
    closing ::NTuple{N, Symbol} where N
    nesting ::Bool
end

BlockTemplate(n, o, c::Symbol, ne) = BlockTemplate(n, o, (c,), ne)
BlockTemplate(a...; nesting=false) = BlockTemplate(a..., nesting)

const NO_CLOSING = (:NONE,) # is also used in find_blocks

SingleTokenBlockTemplate(n::Symbol) = BlockTemplate(n, n, NO_CLOSING, false)


"""
    Group{N} <: AbstractSpan

A Group contains 1 or more more Blocks and will map to either a Paragraph or
something else like a code block.
"""
struct Group{N} <: AbstractSpan
    blocks  ::Vector
    ss      ::SS
end

function Group(role::Symbol, blocks::Vector)
    ps = parent_string(blocks[1])
    return Group{role}(
        blocks,
        subs(ps, from(blocks[1]), to(blocks[end]))
    )
end

Group(role::Symbol, block::Block) = Group(role, [block])

name(::Group{N}) where N = N
