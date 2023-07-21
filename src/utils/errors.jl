struct FranklinParserException <: Exception
    msg::String
    context::String
end


"""
    block_not_closed_exception(ot)

Throw a `FranklinParserException` caused by a block opened by a token `ot`
and left open.
"""
function block_not_closed_exception(ot::Token)
    message, context = _error_message(
        "Block not closed",
        """
        A block starting with token "$(ot.ss)" ($(ot.name)) was left open.
        """,
        ot.ss
    )
    throw(
        FranklinParserException(
            message,
            context
        )
    )
end


"""
    env_not_closed_exception(b)

Throw a `FranklinParserException` caused by an environment opened by a block `b`
and either not formed properly or left open.
"""
function env_not_closed_exception(b::Block, e::SubString)
    message, context = _error_message(
        "Environment not closed",
        """
        An environment "\\begin{$(e)}" was left open.
        """,
        b.ss
    )
    throw(
        FranklinParserException(
            message,
            context
        )
    )
end


"""
    _error_message(title, body, ss)

Helper function to write an informative error message that 
"""
function _error_message(title, body, ss)
    parent  = parent_string(ss)
    head    = max(firstindex(parent), prevind(parent, from(ss), 20))
    tail    = min(lastindex(parent), nextind(parent, to(ss), 20))
    context = subs(parent, head, tail) |> strip
    message = """[FranklinParser | $title]

        $(strip(replace(body, "\n" => " ")))

        Context:

            … $(replace(context, "\n" => " ")) …

        """
    return message, context
end
