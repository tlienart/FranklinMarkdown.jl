using Test, FranklinParser, OrderedCollections, Pkg
FP = FranklinParser
FPE = FP.FranklinParserException

include("testutils.jl")

@testset "utils" begin
    include("utils/strings.jl")
    include("utils/types.jl")
end

@testset "tokens" begin
    include("tokens/utils.jl")
    include("tokens/md_tokens.jl")
    include("tokens/html_tokens.jl")
end

@testset "blocks" begin
    include("blocks/md_blocks.jl")
    include("blocks/html_blocks.jl")
    include("blocks/utils.jl")
end

@testset "partition" begin
    include("partition/md_partition.jl") # depr
    include("partition/md_specs.jl")
    include("partition/html_partition.jl")
    include("partition/math_partition.jl")
end

# TODO
#
# -- links
#
# testing specs: *[foo*](url) should be a link
# --> brackets should be done on first pass without
# deactivating tokens, then links should be formed and
# tokens that are inside links should be deactivated

# XXX emphasis is incorrect, it won't capture a*b*c correctly; we should use something like maths
# basically only when it's surrounded by spaces on both sides is it not valid.
