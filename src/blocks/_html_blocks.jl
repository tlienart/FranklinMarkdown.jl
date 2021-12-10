const HTML_TEMPLATES = LittleDict{Symbol,BlockTemplate}(e.opening => e for e in [
   BlockTemplate(:COMMENT, :COMMENT_OPEN, :COMMENT_CLOSE ),
   BlockTemplate(:SCRIPT,  :SCRIPT_OPEN,  :SCRIPT_CLOSE  ),
   BlockTemplate(:DBB,     :DBB_OPEN,     :DBB_CLOSE     )
   ])
