module FranklinParser

import REPL.REPLCompletions: emoji_symbols
import Base.isempty
import Random
import PrecompileTools

using TimerOutputs
const TIMER = TimerOutput()

const SS = SubString{String}
const SubVector{T} = SubArray{T, 1, Vector{T}, Tuple{UnitRange{Int64}}, true}

subv(v::Vector{T}) where T = @view v[1:length(v)]
subv(v::SubVector{T}) where T = v

include("utils/strings.jl")
include("utils/types.jl")
include("utils/regex.jl")
include("utils/errors.jl")

include("tokens/utils.jl")
include("tokens/find_tokens.jl")
include("tokens/md_utils.jl")
include("tokens/_md_tokens.jl")
include("tokens/_html_tokens.jl")
include("tokens/_args_tokens.jl")

include("blocks/_inline_blocks.jl")
include("blocks/form.jl")
include("blocks/find_blocks.jl")
include("blocks/_md_blocks.jl")
include("blocks/_html_blocks.jl")
include("blocks/_args_blocks.jl")
include("blocks/utils.jl")

include("partition.jl")

# include("_precompile/main.jl")

end
