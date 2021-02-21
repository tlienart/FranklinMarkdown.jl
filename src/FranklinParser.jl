module FranklinParser

using DocStringExtensions
import OrderedCollections: LittleDict
import REPL.REPLCompletions: emoji_symbols

const SS = SubString{String}
const SubVector{T} = SubArray{T, 1, Vector{T}, Tuple{UnitRange{Int64}}, true}

subv(v::Vector{T}) where T = @view v[1:length(v)]

include("utils/strings.jl")
include("utils/types.jl")
include("utils/regex.jl")
include("utils/errors.jl")

include("tokens/utils.jl")
include("tokens/find_tokens.jl")
include("tokens/md_utils.jl")
include("tokens/md_tokens.jl")
include("tokens/html_tokens.jl")

include("blocks/find_blocks.jl")
include("blocks/md_blocks.jl")
include("blocks/html_blocks.jl")
include("blocks/utils.jl")

include("partition.jl")

end
