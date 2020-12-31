module FranklinParser

using DocStringExtensions
import OrderedCollections: LittleDict

const SubVector{T} = SubArray{T, 1}

include("utils/strings.jl")
include("utils/types.jl")
include("utils/regex.jl")
include("utils/errors.jl")

include("tokens/utils.jl")
include("tokens/find_tokens.jl")
include("tokens/markdown_utils.jl")
include("tokens/markdown_tokens.jl")

include("blocks/utils.jl")
include("blocks/find_blocks.jl")
include("blocks/markdown_blocks.jl")

include("partition.jl")

end
