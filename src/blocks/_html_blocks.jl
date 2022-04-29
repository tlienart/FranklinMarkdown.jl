const HTML_TEMPLATES = Dict{Symbol,BlockTemplate}(e.opening => e for e in [
   BlockTemplate(:COMMENT,     :COMMENT_OPEN,     :COMMENT_CLOSE     ),
   BlockTemplate(:SCRIPT,      :SCRIPT_OPEN,      :SCRIPT_CLOSE      ),
   BlockTemplate(:DBB,         :DBB_OPEN,         :DBB_CLOSE         ),
   BlockTemplate(:MATH_INLINE, :MATH_INLINE_OPEN, :MATH_INLINE_CLOSE ),
   BlockTemplate(:MATH_BLOCK,  :MATH_BLOCK_OPEN,  :MATH_BLOCK_CLOSE  ),
   ])
