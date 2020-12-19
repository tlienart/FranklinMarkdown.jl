const MD_BLOCKS = blocks_dict([
   BlockTemplate(:COMMENT,         :COMMENT_OPEN, :COMMENT_CLOSE),
   BlockTemplate(:RAW_HTML,        :RAW_HTML,     :RAW_HTML     ),
   BlockTemplate(:MD_DEF_BLOCK,    :MD_DEF_TOML,  :MD_DEF_TOML  ),
   BlockTemplate(:CODE_BLOCK_LANG, :CODE_LANG3,   :CODE_TRIPLE  ),
   BlockTemplate(:CODE_BLOCK_LANG, :CODE_LANG4,   :CODE_QUAD    ),
   BlockTemplate(:CODE_BLOCK_LANG, :CODE_LANG5,   :CODE_PENTA   ),
   BlockTemplate(:CODE_BLOCK!,     :CODE_TRIPLE!, :CODE_TRIPLE  ),
   BlockTemplate(:CODE_BLOCK,      :CODE_TRIPLE,  :CODE_TRIPLE  ),
   BlockTemplate(:CODE_BLOCK,      :CODE_QUAD,    :CODE_QUAD    ),
   BlockTemplate(:CODE_BLOCK,      :CODE_PENTA,   :CODE_PENTA   ),
   BlockTemplate(:CODE_INLINE,     :CODE_DOUBLE,  :CODE_DOUBLE  ),
   BlockTemplate(:CODE_INLINE,     :CODE_SINGLE,  :CODE_SINGLE  ),
   # BlockTemplate(:MD_DEF,          :MD_DEF_OPEN,  L_RETURNS        ), # [^4]
   # BlockTemplate(:CODE_BLOCK_IND,  :LR_INDENT,    (:LINE_RETURN,)  ),
   # BlockTemplate(:ESCAPE,          :ESCAPE,       (:ESCAPE,)       ),
   # BlockTemplate(:FOOTNOTE_DEF,    :FOOTNOTE_DEF, L_RETURNS        ),
   # BlockTemplate(:LINK_DEF,        :LINK_DEF,     L_RETURNS        ),
   ])

md_blockifier(t::Vector{Token}) = find_blocks(t, MD_BLOCKS)
md_blockifier(s::String) = s |> md_tokenizer |> md_blockifier
