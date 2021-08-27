const CAN_BE_LEFT_OPEN = (
    :EM_OPEN,
    :STRONG_OPEN,
    :EM_STRONG_OPEN,
    :BRACKET_OPEN,
    # :CU_BRACKET_OPEN,  ==> user must use \{
    :SQ_BRACKET_OPEN,
    :AUTOLINK_OPEN
)

# see utils/types/BlockTemplate
const MD_BLOCKS = LittleDict{Symbol,BlockTemplate}(e.opening => e for e in [
   BlockTemplate(:COMMENT,         :COMMENT_OPEN,   :COMMENT_CLOSE  ),
   BlockTemplate(:RAW_HTML,        :RAW_HTML,       :RAW_HTML       ),
   BlockTemplate(:MD_DEF_BLOCK,    :MD_DEF_BLOCK,   :MD_DEF_BLOCK   ),
   BlockTemplate(:EMPH_EM,         :EM_OPEN,        :EM_CLOSE       ),
   BlockTemplate(:EMPH_STRONG,     :STRONG_OPEN,    :STRONG_CLOSE   ),
   BlockTemplate(:EMPH_EM_STRONG,  :EM_STRONG_OPEN, :EM_STRONG_CLOSE),
   BlockTemplate(:AUTOLINK,        :AUTOLINK_OPEN,  :AUTOLINK_CLOSE ),
   # these blocks are disabled in find_blocks if they're not attached in
   # a link/img/... context
   BlockTemplate(:BRACKET,    :BRACKET_OPEN,    :BRACKET_CLOSE,    nesting=true),
   BlockTemplate(:SQ_BRACKET, :SQ_BRACKET_OPEN, :SQ_BRACKET_CLOSE, nesting=true),
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
   # BlockTemplate(:MATH_I, :MATH_I_OPEN, :MATH_I_CLOSE),
   # md def one line
   BlockTemplate(:MD_DEF, :MD_DEF_OPEN, END_OF_LINE),
   # div and braces
   BlockTemplate(:DIV,        :DIV_OPEN, :DIV_CLOSE,               nesting=true),
   BlockTemplate(:CU_BRACKET, :CU_BRACKET_OPEN, :CU_BRACKET_CLOSE, nesting=true),
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

# NOTE: {{...}} blocks (DBB_BLOCK) are processed separately, see find_blocks

const MD_FIRST_PASS_TEMPLATES = LittleDict{Symbol,BlockTemplate}(
   o => bt for (o, bt) in MD_BLOCKS
   if bt.name in (
         :COMMENT,
         :RAW_HTML,
         :MD_DEF_BLOCK, :MD_DEF,
         :CODE_BLOCK_LANG, :CODE_BLOCK!, :CODE_BLOCK, :CODE_INLINE,
         :MATH_A, :MATH_B, :MATH_C,
         :DIV,
         :CU_BRACKET,
         :H1, :H2, :H3, :H4, :H5, :H6,
      )
)

const MD_SECOND_PASS_TEMPLATES = LittleDict{Symbol,BlockTemplate}(
   o => bt for (o, bt) in MD_BLOCKS
   if o ∉ keys(MD_FIRST_PASS_TEMPLATES)
)
