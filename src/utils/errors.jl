abstract type FranklinParserExceptionTypes end

struct BlockNotClosed <: FranklinParserExceptionTypes end

struct FranklinParserException{T} <: Exception where T <: FranklinParserExceptionTypes
    msg::String
end

parser_exception(T::DataType, m::String) = throw(FranklinParserException{T}(m))
