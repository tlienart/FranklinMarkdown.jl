"""
$(TYPEDEF)

Section of a parent String with a specific meaning for Franklin. All subtypes of
`AbstractBlock` must have an `ss` field corresponding to the substring associated to the
block. This field is necessarily of type `SubString{String}`.
"""
abstract type AbstractSpan end

from(s::AbstractSpan)          = from(s.ss::SS)
to(s::AbstractSpan)            = to(s.ss::SS)
parent_string(s::AbstractSpan) = parent_string(s.ss::SS)

#
# Note: we don't want to have Token{N} with e.g. Token{:EOS} like we do Block.
# Indeed, if we had this then we'd need to have the block type to be Block{N,TO,TC}
# to be concrete
#
"""
$(TYPEDEF)

A token is a subtype of `AbstractSpan` which typically determines the start or end of
a block. It can also be used for special characters.
"""
struct Token <: AbstractSpan
    name::Symbol
    ss::SS
end

is_eos(t::Token) = t.name == :EOS
to(t::Token)     = ifelse(is_eos(t), from(t.ss), to(t.ss))

const EMPTY_TOKEN      = Token(:NONE, subs(""))
const EMPTY_TOKEN_SVEC = @view (Token[])[1:0]


"""
$(TYPEDEF)

Blocks are defined by an opening and a closing `Token`, they may be nested. For instance
braces block are formed of an opening `{` and a closing `}`.
"""
struct Block <: AbstractSpan
    name::Symbol
    open::Token
    close::Token
    ss::SS
    inner_tokens::SubVector{Token}
end

function Block(n::Symbol, p::Pair{Token, Token}, it=EMPTY_TOKEN_SVEC)
    o, c = p.first, p.second
    ss = subs(parent_string(o), from(o), to(c))
    return Block(n, o, c, ss, it)
end

function Block(n::Symbol, s::SubVector{Token})
    it = @view s[2:end-1]
    return Block(n, s[1] => s[end], it)
end

function Block(n::Symbol, ss::SS, it=EMPTY_TOKEN_SVEC)
    return Block(n, EMPTY_TOKEN, EMPTY_TOKEN, ss, it)
end

TokenBlock(t::Token) = Block(t.name, t, EMPTY_TOKEN, t.ss, EMPTY_TOKEN_SVEC)

"""
$(SIGNATURES)

Spans of text which should be left to the fallback engine (such as CommonMark for
instance). Text blocks can also have inner tokens that are non-block delimiters such as
emojis or html entities.
"""
function TextBlock(ss::SS, it=EMPTY_TOKEN_SVEC)::Block
    isempty(it) && return Block(:TEXT, ss)
    fss = from(ss)
    tss = to(ss)
    i = findfirst(t -> fss <= from(t), it)
    j = findlast(t -> to(t) <= tss && !is_eos(t), it)
    i === nothing || j === nothing && return Block(:TEXT, ss)
    inner_tokens = @view it[i:j]
    return Block(:TEXT, ss, inner_tokens)
end

"""
$(SIGNATURES)

Return the content of a `Block`, for instance the content of a `{...}` block would be
`...`. Note EOS is a special '0 length' case to  deal with the fact that a text can end
with a token (which would then be an overlapping token and an EOS).
"""
function content(b::Block)::SS
    b.name == :TEXT && return b.ss
    # find the relevant range of the parent string
    s = parent_string(b.ss)
    t = from(b.close)
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

const NO_CLOSING = (:NONE,)

SingleTokenBlockTemplate(name::Symbol) = BlockTemplate(name, name, NO_CLOSING, false)
