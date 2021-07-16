# see utils/types/BlockTemplate
const MD_BLOCKS = LittleDict{Symbol,BlockTemplate}(e.opening => e for e in [
   BlockTemplate(:COMMENT,         :COMMENT_OPEN, :COMMENT_CLOSE),
   BlockTemplate(:RAW_HTML,        :RAW_HTML,     :RAW_HTML     ),
   BlockTemplate(:MD_DEF_BLOCK,    :MD_DEF_BLOCK, :MD_DEF_BLOCK ),
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
   BlockTemplate(:MATH_I, :MATH_I_OPEN, :MATH_I_CLOSE),
   # md def one line
   BlockTemplate(:MD_DEF, :MD_DEF_OPEN, (:LINE_RETURN, :EOS)),
   # div and braces
   BlockTemplate(:DIV, :DIV_OPEN, :DIV_CLOSE, nesting=true),
   BlockTemplate(:LXB, :LXB_OPEN, :LXB_CLOSE, nesting=true),
   # headers
   BlockTemplate(:H1, :H1_OPEN, END_OF_LINE),
   BlockTemplate(:H2, :H2_OPEN, END_OF_LINE),
   BlockTemplate(:H3, :H3_OPEN, END_OF_LINE),
   BlockTemplate(:H4, :H4_OPEN, END_OF_LINE),
   BlockTemplate(:H5, :H5_OPEN, END_OF_LINE),
   BlockTemplate(:H6, :H6_OPEN, END_OF_LINE),
   # Footnote
   BlockTemplate(:FOOTNOTE_DEF, :FOOTNOTE_DEF, :LINE_RETURN),
   BlockTemplate(:LINK_DEF,     :LINK_DEF,     END_OF_LINE),
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
