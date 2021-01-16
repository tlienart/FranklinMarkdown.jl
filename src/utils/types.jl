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
content(s::AbstractSpan)::SS   = s.ss::SS

#
# Note: we don't want to have Token{N} with e.g. Token{:EOS} like we do Block.
# Indeed, if we had this then we'd need to have the block type to be Block{N,TO,TC}
# to be concrete
#
"""
$(TYPEDEF)

A token is a subtype of `Span` which typically determines the start or end of an block.
It can also be used for special characters.
"""
struct Token{N} <: AbstractSpan
    ss::SS
end

to(t::Token{:EOS}) = from(t.ss)

is_eos(t::Token)       = false
is_eos(t::Token{:EOS}) = true

name(t::Token{N}) where N = N


"""
$(TYPEDEF)

Wrapper around a special character (e.g. entity) keeping track of the exact HTML
insertion. For instance if an asterisk is seen and meant to be preserved as such, it
will be stored as a special char with html "&#42;".
"""
struct SpecialChar <: AbstractSpan
    ss::SS
    html::String
end
SpecialChar(ss) = SpecialChar(ss, "")


const EMPTY_TOKEN_SVEC = @view (Token[])[1:0]

"""
$(TYPEDEF)

Spans of text which should be left to the fallback engine (such as CommonMark for
instance). Text blocks can also have inner tokens that are non-block delimiters such as
emojis, html entities and special characters.
"""
struct Text <: AbstractSpan
    ss::SS
    inner_tokens::SubVector{Token}

    function Text(ss, it=EMPTY_TOKEN_SVEC)
        isempty(it) && return new(ss, it)
        fss = from(ss)
        tss = to(ss)
        i = findfirst(t -> fss <= from(t), it)
        j = findlast(t -> to(t) <= tss && !is_eos(t), it)
        i === nothing || j === nothing && return new(ss, EMPTY_TOKEN_SVEC)
        inner_tokens = @view it[i:j]
        new(ss, inner_tokens)
    end
end

"""
$(TYPEDEF)

Blocks are defined by an opening and a closing `Token`, they may be nested. For instance
braces block are formed of an opening `{` and a closing `}`.
"""
struct Block{N, O, C} <: AbstractSpan
    open::Token{O}
    close::Token{C}
    ss::SS
    inner_tokens::SubVector{Token}
end

const TextOrBlock = Union{Text, Block}

function Block(N::Symbol, p::Pair{Token{O}, Token{C}}, it=EMPTY_TOKEN_SVEC) where {O, C}
    o, c = p.first, p.second
    ss = subs(parent_string(o), from(o), to(c))
    return Block{N, O, C}(o, c, ss, it)
end

function Block(n::Symbol, s::SubVector{Token})
    it = @view s[2:end-1]
    return Block(n, s[1] => s[end], it)
end

name(b::Block{N, O, C}) where {N, O, C} = N

"""
$(SIGNATURES)

Return the content of a `Block`, for instance the content of a `{...}` block would be
`...`. Note EOS is a special '0 length' case to  deal with the fact that a text can end
with a token (which would then be an overlapping token and an EOS).
"""
function content(b::Block)::SS
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
