module FranklinParser

import OrderedCollections: LittleDict
import REPL.REPLCompletions: emoji_symbols

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

# see partition, we put this here because it's also used in 'form.jl'
const INLINE_BLOCKS = [
    :TEXT,
    :COMMENT,                                 # <!-- ... -->
    :RAW_HTML,                                # ~~~...~~~
    :EMPH_EM, :EMPH_STRONG, :EMPH_EM_STRONG,  # * ** ***, _ __ ____
    :LINEBREAK,                               # \\
    :CODE_INLINE,                             # `...`
    :MATH_A,                                  # $...$
    # :MATH_I,                                # _\$>_..._\$<_
    :AUTOLINK,                                # <...>
    :LINK_A, :LINK_AB, :IMG_A, :IMG_AB,       # [...](...) ![...](...)
    :CU_BRACKET, :LX_COMMAND,
    :DBB,
    # derived by reconstructing commands (Franklin)
    :RAW_INLINE
]

include("blocks/form.jl")
include("blocks/find_blocks.jl")
include("blocks/_md_blocks.jl")
include("blocks/_html_blocks.jl")
include("blocks/utils.jl")

include("partition.jl")

end
