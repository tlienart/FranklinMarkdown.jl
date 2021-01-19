"""
$(SIGNATURES)

Facilitate taking a SubString of an AS. The bounds given are expected to be valid
String indices.
Returns a SubString.
"""
subs(s::SS, from::Int, to::Int)::SS = SubString(s, from, to)
subs(s::SS, from::Int)              = subs(s, from, from)
subs(s::SS, range::UnitRange{Int})  = subs(s, range.start, range.stop)

subs(s::SS) = s
subs(s::String, a...) = subs(SS(s), a...)

"""
$(SIGNATURES)

Returns the parent string corresponding to `s`; i.e. `s` itself if it is a String, or
the parent string if `s` is a SubString.
Returns a String.
"""
parent_string(s::String) = s
parent_string(s::SS)     = s.string

"""
$(SIGNATURES)

Given a SubString `ss`, returns the position in the parent string where the substring
starts. If `ss` is a String, return 1.
Returns an Int.
```
"""
from(ss::SS)    = nextind(parent_string(ss), ss.offset)
from(s::String) = 1

"""
$(SIGNATURES)

Given a SubString `ss`, returns the position in the parent string where the substring
ends. If `ss` is a String, return the last index.
Returns an Int.
"""
to(ss::SS)    = ss.offset + ss.ncodeunits
to(s::String) = lastindex(s)

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

Remove the common leading whitespace from each non-empty line. The returned text
is decoupled from the original text (forced to String).
"""
function dedent(s::SS)::String
    # initial whitespace if any
    iwsp = match(LEADING_WHITESPACE_PAT, s)
    if iwsp !== nothing
        cwsp::SS = iwsp.captures[1]
        # there's no leading whitespace on the first line --> no dedent
        isempty(cwsp) && return String(s)
    end

    for m in eachmatch(NEWLINE_WHITESPACE_PAT, s)
        # skip empty lines
        (m !== nothing) || continue
        twsp::SS = m.captures[1]
        # if twsp is empty, there's no leading whitespace on that line --> no dedent
        isempty(twsp) && return String(s)
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
        for j in eachindex(cwsp)
            isvalid(twsp, j) || break
            cwsp[j] == twsp[j] || break
            i = j
        end
        if i > 0
            cwsp = subs(cwsp, 1:i)
        else
            # if we're here then TWSP and CWSP have an empty intersection --> no dedent
            return String(s)
        end
    end
    # we're here --> remove all cwsp + remove cwsp from first line if relevant
    ds = replace(s, "\n$cwsp" => "\n")
    iwsp === nothing && return ds
    return replace(ds, "$cwsp" => "", count=1)
end
dedent(s::String) = dedent(subs(s))
