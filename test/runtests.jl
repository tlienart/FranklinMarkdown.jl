using Test, FranklinParser, OrderedCollections, Pkg
import CommonMark
const FP = FranklinParser
const FPE = FP.FranklinParserException
const CM = CommonMark

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
    include("blocks/utils.jl")
end

@testset "partition" begin
    include("partition/md_partition.jl")
end

@testset "integration" begin
    include("integration/rules.jl")
    include("integration/div_blocks.jl")
end
