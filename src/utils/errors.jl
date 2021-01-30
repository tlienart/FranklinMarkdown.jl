struct FranklinParserException <: Exception
    kind::Symbol
    msg::String
end

@inline parser_exception(k::Symbol, m::String) = throw(FranklinParserException(k, m))
