"""
$(TYPEDEF)

SubString of the parent String with a specific meaning for Franklin. All subtypes of `AbstractBlock` must have an `ss` field corresponding to the substring associated to
the block.
"""
abstract type AbstractSpan end

from(s::AbstractSpan)          = from(s.ss)
to(s::AbstractSpan)            = to(s.ss)
parent_string(s::AbstractSpan) = parent_string(s.ss)
content(s::AbstractSpan)       = s.ss


"""
$(TYPEDEF)

A token is a subtype of `Span` which typically determines the start or end of an block.
It can also be used for special characters.
"""
struct Token <: AbstractSpan
    name::Symbol
    ss::SubString
end

to(t::Token) = ifelse(t.name == :EOS, from(t), to(t.ss))

is_eos(t::Token) = t.name == :EOS


"""
$(TYPEDEF)

Wrapper around a special character (e.g. entity) keeping track of the exact HTML
insertion. For instance if an asterisk is seen and meant to be preserved as such, it
will be stored as a special char with html "&#42;".
"""
struct SpecialChar <: AbstractSpan
    ss::SubString
    html::String
end
SpecialChar(ss) = SpecialChar(ss, "")


const EMPTY_TOKEN_VEC = Token[]

"""
$(TYPEDEF)

Spans of text which should be left to the fallback engine (such as CommonMark for
instance). Text blocks can also have inner tokens that are non-block delimiters such as
emojis, html entities and special characters.
"""
struct Text <: AbstractSpan
    ss::SubString
    inner_tokens::AbstractVector{Token}
    function Text(ss, it=EMPTY_TOKEN_VEC)
        isempty(it) && return new(ss, it)
        fss = from(ss)
        tss = to(ss)
        i = findfirst(t -> fss <= from(t), it)
        j = findlast(t -> to(t) <= tss && !is_eos(t), it)
        any(isnothing, (i, j)) && return new(ss, EMPTY_TOKEN_VEC)
        inner_tokens = @view it[i:j]
        new(ss, inner_tokens)
    end
end

"""
$(TYPEDEF)

Blocks are defined by an opening and a closing `Token`, they may be nested. For instance
braces block are formed of an opening `{` and a closing `}`.
"""
struct Block{N} <: AbstractSpan
    open::Token
    close::Token
    ss::SubString
    inner_tokens::AbstractVector{Token}
end

const TextOrBlock = Union{Text, Block}

function Block(n::Symbol, p::Pair{Token,Token}, it=EMPTY_TOKEN_VEC)
    o, c = p.first, p.second
    ss = subs(parent_string(o), from(o), to(c))
    return Block{n}(o, c, ss, it)
end

function Block(n::Symbol, s::SubVector{Token})
    it = @view s[2:end-1]
    return Block(n, s[1] => s[end], it)
end

"""
$(SIGNATURES)

Return the content of a `Block`, for instance the content of a `{...}` block would be
`...`. Note EOS is a special '0 length' case to  deal with the fact that a text can end
with a token (which would then be an overlapping token and an EOS).
"""
function content(b::Block)::SubString
    s = parent_string(b.ss)  # does not allocate
    t = from(b.close)
    # find the relevant range of the parent string
    idxo = nextind(s, to(b.open))
    idxc = ifelse(is_eos(b.close), t, prevind(s, t))
    # return the substring corresponding to the range
    return subs(s, idxo, idxc)
end


"""
$(TYPEDEF)

Template for a block to find. A block goes from a token with a given `opening` name to
one of several possible `closing` names. Blocks can allow or disallow nesting. For
instance brace blocks can be nested `{.{.}.}` but not comments.
When nesting is enabled, Franklin will try to find the closing token taking into account
the balance in opening-closing tokens.
"""
struct BlockTemplate
    name::Symbol
    opening::Symbol
    closing::NTuple{N, Symbol} where N
    nesting::Bool
end

BlockTemplate(n, o, c::Symbol, ne) = BlockTemplate(n, o, (c,), ne)
BlockTemplate(a...; nesting=false) = BlockTemplate(a..., nesting)
