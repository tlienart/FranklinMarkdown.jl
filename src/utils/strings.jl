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

"""
$(SIGNATURES)

Return the index just before the object `o`.
"""
previous_index(o) = prevind(parent_string(o), from(o))

"""
$(SIGNATURES)

Return the index just after the object `o`.
"""
next_index(o) = nextind(parent_string(o), to(o))

"""
$(SIGNATURES)

Remove the common leading whitespace from each non-empty line.
"""
function dedent(s::AS)
    # initial whitespace if any
    iwsp = match(LEADING_WHITESPACE_PAT, s)
    # common whitespace
    cwsp = (iwsp !== nothing) ? iwsp.captures[1] : nothing

    # there's no leading whitespace on the first line --> no dedent
    isempty(cwsp) && return s

    for m in eachmatch(NEWLINE_WHITESPACE_PAT, s)
        # skip empty lines
        (m !== nothing) || continue
        twsp = m.captures[1]
        # if twsp is empty, there's no leading whitespace on that line --> no dedent
        isempty(twsp) && return s
        # does twsp contain cwsp?
        startswith(twsp, cwsp) && continue
        # does cwsp contain twsp?
        if startswith(cwsp, twsp)
            cwsp = twsp
            continue
        end
        # if we're here then TWSP and CWSP don't have a common part --> check intersection
        # for instance CWSP = "\t⎵" and TWSP = "\t\t" --> CWSP = "\t"
        i = 0
        for (c1, c2) in zip(cwsp, twsp)
            c1 == c2 || break
            i += 1
        end
        if i > 0
            cwsp = cwsp[1:i]
        else
            # if we're here then TWSP and CWSP have an empty intersection --> no dedent
            return s
        end
    end
    # we're here --> remove all cwsp + remove cwsp from first line if relevant
    ds = replace(s, "\n$cwsp" => "\n")
    iwsp === nothing && return ds
    return replace(ds, "$cwsp" => "", count=1)
end
