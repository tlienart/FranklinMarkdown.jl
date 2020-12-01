const AS = Union{String, SubString}

"""
$(SIGNATURES)

Facilitate taking a SubString of an AS. The bounds given are expected to be valid
String indices.
Returns a SubString.
"""
subs(s::AS, from::Int, to::Int)    = SubString(s, from, to)
subs(s::AS, from::Int)             = subs(s, from, from)
subs(s::AS, range::UnitRange{Int}) = SubString(s, range)
subs(s::AS)                        = SubString(s)

"""
$(SIGNATURES)

Returns the parent string corresponding to `s`; i.e. `s` itself if it is a String, or
the parent string if `s` is a SubString.
Returns a String.
"""
parent_string(s::String)    = s
parent_string(s::SubString) = s.string

"""
$(SIGNATURES)

Given a SubString `ss`, returns the position in the parent string where the substring
starts. If `ss` is a String, return 1.
Returns an Int.
```
"""
from(ss::SubString) = nextind(parent_string(ss), ss.offset)
from(s::String)     = 1

"""
$(SIGNATURES)

Given a SubString `ss`, returns the position in the parent string where the substring
ends. If `ss` is a String, return the last index.
Returns an Int.
"""
to(ss::SubString) = ss.offset + ss.ncodeunits
to(s::String)     = lastindex(s)
