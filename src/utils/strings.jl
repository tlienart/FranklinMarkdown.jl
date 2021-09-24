"""
    subs(...)

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
    parent_string(o)

Returns the parent string corresponding to `s`; i.e. `s` itself if it is a String, or
the parent string if `s` is a SubString.
Returns a String.
"""
parent_string(s::String) = s
parent_string(s::SS)     = s.string

"""
    from(o)

Given a SubString `ss`, returns the position in the parent string where the substring
starts. If `ss` is a String, return 1.
Returns an Int.
```
"""
from(ss::SS)    = nextind(parent_string(ss), ss.offset)
from(s::String) = 1

"""
    to(o)

Given a SubString `ss`, returns the position in the parent string where the substring
ends. If `ss` is a String, return the last index.
Returns an Int.
"""
to(ss::SS)    = ss.offset + ss.ncodeunits
to(s::String) = lastindex(s)

"""
    prev_index(o)

Return the index just before the object `o`.
"""
prev_index(o) = prevind(parent_string(o), from(o))

"""
    next_index(o)

Return the index just after the object `o`.
"""
next_index(o) = nextind(parent_string(o), to(o))

"""
    previous_chars(o, n)

Return the characters just before the object. Empty vector if there isn't the number of
characters required.
"""
function previous_chars(o, n::Int=1)
    ps = parent_string(o)
    fo = from(o)
    i  = prevind(ps, fo, n)
    i <= 0 && return Char[]
    j  = prevind(ps, fo)
    ij = [nextind(ps, i, k) for k in 0:n-1]
    return [ps[k] for k in ij]
end

"""
    next_chars(o, n)

Return the characters just after the object. Empty vector if there isn't the number of
characters required.
"""
function next_chars(o, n::Int=1)
    ps = parent_string(o)
    no = to(o)
    j  = nextind(ps, no, n)
    j > lastindex(ps) && return Char[]
    i  = nextind(ps, no)
    ij = [nextind(ps, i, k) for k in 0:n-1]
    return [ps[k] for k in ij]
end

"""
    until_next_line_return(o)

Return the substring following the object and until the next line return or end.
"""
function until_next_line_return(o)
    ps = parent_string(o)
    no = to(o)
    j  = ifelse(o isa Token && o.name == :SOS, no, nextind(ps, no))
    j  > lastindex(ps) && return subs("")
    j1 = j
    jk = j
    # no need to match EOS, it's implicit with j <= lastindex
    @inbounds while (j <= lastindex(ps)) && (ps[j] != '\n')
        jk = j
        j  = nextind(ps, j)
    end
    return subs(ps, j1, jk)
end

"""
    until_previous_line_return(o)

Return the substring preceding the object until the preceding line return if
any.
"""
function until_previous_line_return(o)
    ps = parent_string(o)
    no = from(o)
    j  = prevind(ps, no)
    j  < 1 && return subs("")
    jk = j
    j1 = j
    @inbounds while (j >= 1) && (ps[j] != '\n')
        j1 = j
        j  = prevind(ps, j)
    end
    return subs(ps, j1, jk)
end


"""
    dedent(s)

Remove the common leading whitespace from each non-empty line. The returned text
is decoupled from the original text (forced to String).

This is used in the context of lxdef in Franklin for instance, see try_form_lxdef.
"""
function dedent(s::SS)::String
    # initial whitespace if any
    iwsp = match(LEADING_WHITESPACE_PAT, s)
    cwsp = ""
    if iwsp !== nothing
        cwsp::SS = iwsp.captures[1]
        # there's no leading whitespace on the first line --> no dedent
        isempty(cwsp) && return String(s)
    end

    for m in eachmatch(NEWLINE_WHITESPACE_PAT, s)
        twsp::SS = m.captures[1]
        # if twsp is empty, there's no leading whitespace on that line --> no dedent
        isempty(twsp) && return String(s)
        isempty(cwsp) && (cwsp = twsp; continue)
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
