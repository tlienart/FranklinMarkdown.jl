# see utils/types/BlockTemplate
const MD_BLOCKS = LittleDict{Symbol,BlockTemplate}(e.opening => e for e in [
   BlockTemplate(:COMMENT,         :COMMENT_OPEN,   :COMMENT_CLOSE  ),
   BlockTemplate(:RAW_HTML,        :RAW_HTML,       :RAW_HTML       ),
   BlockTemplate(:MD_DEF_BLOCK,    :MD_DEF_BLOCK,   :MD_DEF_BLOCK   ),
   BlockTemplate(:EMPH_EM,         :EM,             :EM             ),
   BlockTemplate(:EMPH_STRONG,     :STRONG,         :STRONG         ),
   BlockTemplate(:EMPH_EM_STRONG,  :EM_STRONG,      :EM_STRONG      ),
   BlockTemplate(:AUTOLINK,        :AUTOLINK_OPEN,  :AUTOLINK_CLOSE ),
   # these blocks are disabled in find_blocks if they're not attached in
   # a link/img/... context
   BlockTemplate(:BRACKETS,    :BRACKET_OPEN,    :BRACKET_CLOSE,    nesting=true),
   BlockTemplate(:SQ_BRACKETS, :SQ_BRACKET_OPEN, :SQ_BRACKET_CLOSE, nesting=true),
   # code
   BlockTemplate(:CODE_BLOCK_LANG, :CODE_LANG3,   :CODE_TRIPLE  ),
   BlockTemplate(:CODE_BLOCK_LANG, :CODE_LANG4,   :CODE_QUAD    ),
   BlockTemplate(:CODE_BLOCK_LANG, :CODE_LANG5,   :CODE_PENTA   ),
   BlockTemplate(:CODE_BLOCK!,     :CODE_TRIPLE!, :CODE_TRIPLE  ),
   BlockTemplate(:CODE_BLOCK,      :CODE_TRIPLE,  :CODE_TRIPLE  ),
   BlockTemplate(:CODE_BLOCK,      :CODE_QUAD,    :CODE_QUAD    ),
   BlockTemplate(:CODE_BLOCK,      :CODE_PENTA,   :CODE_PENTA   ),
   BlockTemplate(:CODE_INLINE,     :CODE_DOUBLE,  :CODE_DOUBLE  ),
   BlockTemplate(:CODE_INLINE,     :CODE_SINGLE,  :CODE_SINGLE  ),
   # maths
   BlockTemplate(:MATH_A, :MATH_A,      :MATH_A      ),
   BlockTemplate(:MATH_B, :MATH_B,      :MATH_B      ),
   BlockTemplate(:MATH_C, :MATH_C_OPEN, :MATH_C_CLOSE),
   # md def one line
   BlockTemplate(:MD_DEF, :MD_DEF_OPEN, END_OF_LINE),
   # div and braces
   BlockTemplate(:DIV,         :DIV_OPEN, :DIV_CLOSE,               nesting=true),
   BlockTemplate(:CU_BRACKETS, :CU_BRACKET_OPEN, :CU_BRACKET_CLOSE, nesting=true),
   # headers
   BlockTemplate(:H1, :H1_OPEN, END_OF_LINE),
   BlockTemplate(:H2, :H2_OPEN, END_OF_LINE),
   BlockTemplate(:H3, :H3_OPEN, END_OF_LINE),
   BlockTemplate(:H4, :H4_OPEN, END_OF_LINE),
   BlockTemplate(:H5, :H5_OPEN, END_OF_LINE),
   BlockTemplate(:H6, :H6_OPEN, END_OF_LINE),
   # Direct blocks
   SingleTokenBlockTemplate(:LINEBREAK),
   SingleTokenBlockTemplate(:HRULE),
   # Direct blocks -- latex objects
   SingleTokenBlockTemplate(:LX_NEWENVIRONMENT),
   SingleTokenBlockTemplate(:LX_NEWCOMMAND),
   SingleTokenBlockTemplate(:LX_COMMAND),
   SingleTokenBlockTemplate(:LX_BEGIN),
   SingleTokenBlockTemplate(:LX_END)
   ])

#
# NOTE: {{...}} blocks (DBB_BLOCK) are processed separately, see find_blocks
#

const CAN_BE_LEFT_OPEN = (
    :EM,
    :STRONG,
    :EM_STRONG,
    :BRACKET_OPEN,
    :AUTOLINK_OPEN
)

const MD_PASS0 = LittleDict{Symbol,BlockTemplate}(
   :RAW => BlockTemplate(:RAW, :RAW, :RAW),
)

# First pass: container blocks etc
const MD_PASS1_TEMPLATES = LittleDict{Symbol,BlockTemplate}(
   o => bt for (o, bt) in MD_BLOCKS
   if bt.name in (
         :COMMENT,
         :RAW_HTML,
         :MD_DEF_BLOCK, :MD_DEF,
         :CODE_BLOCK_LANG, :CODE_BLOCK!, :CODE_BLOCK, :CODE_INLINE,
         :MATH_A, :MATH_B, :MATH_C,
         :DIV,
         :AUTOLINK,
         :CU_BRACKETS,
         :H1, :H2, :H3, :H4, :H5, :H6,
      )
)

# Second pass: links etc
const MD_PASS2_TEMPLATES = LittleDict{Symbol,BlockTemplate}(
   o => bt for (o, bt) in MD_BLOCKS
   if bt.name in (
         :BRACKETS,
         :SQ_BRACKETS
      )
)

# Last pass: the rest
const MD_PASS3_TEMPLATES = LittleDict{Symbol,BlockTemplate}(
   o => bt for (o, bt) in MD_BLOCKS
   if o ∉ union(keys(MD_PASS1_TEMPLATES), keys(MD_PASS2_TEMPLATES))
)
