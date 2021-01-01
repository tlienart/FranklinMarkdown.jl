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
   # md def one line
   BlockTemplate(:MD_DEF, :MD_DEF_OPEN, (:LINE_RETURN, :EOS)),
   # div and braces
   BlockTemplate(:DIV, :DIV_OPEN, :DIV_CLOSE, nesting=true),
   BlockTemplate(:LXB, :LXB_OPEN, :LXB_CLOSE, nesting=true),
   BlockTemplate(:DBB, :DBB_OPEN, :DBB_CLOSE),
   # headers
   BlockTemplate(:H1, :H1_OPEN, LINE_RETURNS),
   BlockTemplate(:H2, :H2_OPEN, LINE_RETURNS),
   BlockTemplate(:H3, :H3_OPEN, LINE_RETURNS),
   BlockTemplate(:H4, :H4_OPEN, LINE_RETURNS),
   BlockTemplate(:H5, :H5_OPEN, LINE_RETURNS),
   BlockTemplate(:H6, :H6_OPEN, LINE_RETURNS),
   # Footnote
   BlockTemplate(:FOOTNOTE_DEF, :FOOTNOTE_DEF, LINE_RETURNS),
   BlockTemplate(:LINK_DEF,     :LINK_DEF,     LINE_RETURNS),
   ])

function md_blockifier(t::Vector{Token})
   blocks = find_blocks(t, MD_BLOCKS)
   return blocks
end

function md_blockifier(s::AS)
   return s |> md_tokenizer |> md_blockifier
end
