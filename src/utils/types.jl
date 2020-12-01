"""
$(TYPEDEF)

SubString of the parent String with a specific meaning for Franklin. All subtypes of `AbstractBlock` must have an `ss` field corresponding to the substring associated to
the block.
See also [`Token`](@ref), [`OCBlock`](@ref).
"""
abstract type AbstractSpan end

from(s::AbstractSpan)          = from(s.ss)
to(s::AbstractSpan)            = to(s.ss)
parent_string(s::AbstractSpan) = parent_string(s.ss)

"""
$(TYPEDEF)

A token is a subtype of `Span` which typically determines the start or end of an block.
It can also be used for special characters.
"""
struct Token <: AbstractSpan
    name::Symbol
    ss::SubString
    lno::Int  # for LRINDENT it's useful to store line number
end
Token(n, s) = Token(n, s, 0)

to(t::Token) = ifelse(t.name == :EOS, from(t), to(t.ss))

is_eos(t::Token) = t.name == :EOS

"""
$(TYPEDEF)

Wrapper around a special charcter (e.g. entity) keeping track of the exact HTML
insertion. For instance if an asterisk is seen and meant to be preserved as such, it
will be stored as a special char with html "&#42;".
"""
struct SpecialChar <: AbstractSpan
    ss::SubString
    html::String
end
SpecialChar(ss) = SpecialChar(ss, "")

"""
$(TYPEDEF)

Blocks are defined by an opening and a closing `Token`, they may be nested. For instance
braces block are formed of an opening `{` and a closing `}`.
"""
struct Block <: AbstractSpan
    name::Symbol
    open::Token
    close::Token
    ss::SubString
end

function Block(n::Symbol, p::Pair{Token,Token})
    o, c = p.first, p.second
    ss = subs(parent_string(o), from(o), to(c))
    return Block(n, o, c, ss)
end

"""
$(SIGNATURES)

Return the content of an open-close block (`OCBlock`), for instance the content of a
`{...}` block would be `...`.
Note EOS is a special '0 length' case to  deal with the fact that a text can end with a
token (which would then be an overlapping token and an EOS).
"""
function content(b::Block)::SubString
    s = parent_string(b.ss) # does not allocate
    t = from(b.close)

    idxo = nextind(s, to(b.open))
    idxc = ifelse(is_eos(b.close), t, prevind(s, t))

    return subs(s, idxo, idxc)
end
