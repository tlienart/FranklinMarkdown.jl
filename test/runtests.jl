using Test, FranklinParser, OrderedCollections
const FP = FranklinParser

include("testutils.jl")

@testset "utils" begin
    include("utils/strings.jl")
    include("utils/types.jl")
    include("utils/regex.jl")
end

@testset "tokens" begin
    include("tokens/find_tokens.jl")
    include("tokens/markdown_tokens.jl")
end

@testset "blocks" begin
    include("blocks/markdown_blocks.jl")
end
