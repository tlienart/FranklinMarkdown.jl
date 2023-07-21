using Test, FranklinParser, Pkg
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
    include("partition/split_args.jl")
end

@testset "cmark" begin
    # all the tests here are directly taken from
    # https://github.com/MichaelHatherly/CommonMark.jl/tree/master/test/samples/cmark
    include("cmark/inlines.jl")
    include("cmark/blocks.jl")
    include("cmark/misc.jl")
end

@testset "misc" begin
    @test FP.content("abc") == "abc"
    @test FP.content(FP.subs("abc")) == "abc"
end

@testset "bugfixes" begin
    include("misc_fixes.jl")
end

@testset "errors" begin
    include("errors.jl")
end
