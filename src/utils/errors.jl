abstract type FranklinParserException <: Exception end

struct BlockNotClosed <: FranklinParserException
    msg::String
end
