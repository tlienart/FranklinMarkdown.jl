module FranklinParser

using DocStringExtensions

import CommonMark
const CM = CommonMark

import OrderedCollections: LittleDict

# ----------------------------------------
# Disable the parsing of indented blocks
# see https://github.com/MichaelHatherly/CommonMark.jl/issues/1#issuecomment-735990126)
struct SkipIndented end
block_rule(::SkipIndented) = CM.Rule((p, c) -> 0, 8, "")
cm_parser = CM.enable!(CM.disable!(CM.Parser(), CM.IndentedCodeBlockRule()), SkipIndented())
# ----------------------------------------

include("utils/strings.jl")
include("utils/types.jl")
include("utils/regex.jl")

include("tokens/utils.jl")
include("tokens/find_tokens.jl")
include("tokens/markdown_utils.jl")
include("tokens/markdown_tokens.jl")

include("blocks/utils.jl")
include("blocks/find_blocks.jl")
include("blocks/markdown_blocks.jl")

end
