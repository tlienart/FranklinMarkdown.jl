const ARGS_BLOCKS = Dict{Symbol,BlockTemplate}(e.opening => e for e in [
   BlockTemplate(:STRING,  :SINGLE_QUOTE, :SINGLE_QUOTE ),
   BlockTemplate(:STRING,  :TRIPLE_QUOTE, :TRIPLE_QUOTE ),
   ])
