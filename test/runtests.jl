using Test, FranklinParser, OrderedCollections
const FP = FranklinParser

@testset "utils" begin
    include("utils/strings.jl")
    include("utils/types.jl")
    include("utils/regex.jl")
end

@testset "tokens" begin
    include("tokens/tokenize.jl")
end
